# Arquitectura de Run For Win

Este documento describe cómo está organizado el código, las decisiones de diseño y el flujo de datos de la aplicación.

## Índice

- [Visión general](#visión-general)
- [Clean Architecture por features](#clean-architecture-por-features)
- [Capa core](#capa-core)
- [Inyección de dependencias](#inyección-de-dependencias)
- [Persistencia con Hive](#persistencia-con-hive)
- [Gestión de estado (BLoC)](#gestión-de-estado-bloc)
- [Navegación](#navegación)
- [Internacionalización (i18n)](#internacionalización-i18n)
- [El motor de juego (Flame)](#el-motor-de-juego-flame)
- [Diagrama de dependencias](#diagrama-de-dependencias)

---

## Visión general

Run For Win (codename **BrixRun** en el código; paquete `run_for_win`) es una app Flutter monolítica (un solo paquete) estructurada en **Clean Architecture** y dividida por **features** verticales. Cada feature es autocontenida y se comunica con el resto solo a través de entidades de dominio y de los BLoCs registrados globalmente.

Reglas de dependencia (de fuera hacia dentro):

```
presentation  ──►  domain  ◄──  data
     (UI/BLoC)   (entidades,     (Hive,
                  contratos,      modelos,
                  usecases)       repos impl)
```

- **`domain` no depende de nada** de Flutter, Hive ni de otras capas. Contiene entidades puras (`Equatable`), contratos de repositorio (interfaces abstractas) y casos de uso.
- **`data`** implementa los contratos de `domain` usando Hive.
- **`presentation`** consume `domain` (usecases/entidades) mediante BLoCs.

Esto es lo que permite que la **misma UI** funcione con pagos reales en móvil y simulados en web: `injection.dart` registra `InAppPurchaseStoreRepository` o `StubStoreRepository` según la plataforma, y ninguna pantalla se entera. El mismo mecanismo dejaría abierto un ranking en línea el día que se quiera (otra implementación de `ScoreRepository`), aunque **en el MVP v1 todo es local**.

---

## Clean Architecture por features

Las features viven en `lib/features/`:

| Feature | Responsabilidad |
|---------|-----------------|
| `home` | Pantalla de inicio enfocada en la carrera (CTA "¡JUGAR!"); ruta inicial. |
| `character_editor` | Crear, editar, listar y borrar personajes (galería + editor) y presets precargados. |
| `economy` | Monedas, ruleta diaria, cofres, desbloqueo/compra de piezas, streak de juego y **billetera** (`/wallet`: resumen ganado/gastado/saldo). |
| `missions` | Generar y avanzar 3 misiones activas rotativas. |
| `ranking` | Registrar y consultar puntuaciones por mundo. |
| `runner` | El juego en sí: selección de mundo, pre-run, partida (motor Flame), peleas contra jefes y HUD. |

Cada una repite la misma estructura de tres capas:

```
feature/
├── domain/
│   ├── entities/      # Modelos de negocio inmutables (Equatable + copyWith)
│   ├── repositories/  # Interfaces abstractas (contratos)
│   └── usecases/      # Una clase por caso de uso, invocable con call()
├── data/
│   ├── models/        # *Model extienden/serializan la entidad; *.g.dart = TypeAdapter a mano
│   ├── datasources/   # Envuelven una Box de Hive
│   └── repositories/  # *RepositoryImpl implementan los contratos de domain
└── presentation/
    ├── bloc/          # <Feature>Bloc + <Feature>Event + <Feature>State
    ├── pages/         # Pantallas completas
    ├── widgets/       # Componentes de UI reutilizables
    └── game/          # (solo runner) mundo y componentes Flame
```

### Casos de uso

Los usecases encapsulan una única operación y exponen un método `call()` para invocarse como funciones. Ejemplos en `economy`:

- `EarnCoins`, `RecordRun`, `ClaimDailyRoulette`, `OpenChest`, `UnlockPart`.

En `character_editor`: `SaveCharacter`, `GetAllCharacters`, `DeleteCharacter`.

El BLoC recibe los usecases por constructor (no accede a repositorios directamente cuando existe un usecase), lo que mantiene la lógica de negocio fuera de la UI.

---

## Capa core

`lib/core/` contiene infraestructura transversal, sin lógica de negocio de features:

| Archivo | Rol |
|---------|-----|
| `di/injection.dart` | Registra dependencias en `get_it` y abre las cajas Hive. |
| `router/app_router.dart` | Configuración de `go_router` (rutas y redirecciones). |
| `theme/app_theme.dart` | Temas claro/oscuro. Colores marca: amarillo Brix `#FFD700`, azul Brix `#0055A5`. Fuente `Nunito`. |
| `services/audio_service.dart` | Singleton de audio con un `AudioPlayer` por efecto. |
| `l10n/` | Internacionalización a mano: `AppLocalizations`/`L10n`, tablas de traducción (`app_strings.dart`, `app_strings_extra.dart`). Ver [Internacionalización (i18n)](#internacionalización-i18n). |
| `orientation/portrait_lock.dart` | Bloqueo de orientación vertical (nativo con `SystemChrome`; en web, `PortraitGate`). |
| `test_mode/test_mode.dart` | Interruptor global del modo de prueba (inerte en release salvo `--dart-define=BRIX_TESTMODE=true`). |
| `error/failures.dart` | Tipos de fallo para el manejo de errores. |

---

## Inyección de dependencias

Se usa **`get_it`** como *service locator*, expuesto como `sl` (`final sl = GetIt.instance;`). Todo el cableado ocurre en `initDependencies()` (`lib/core/di/injection.dart`), invocado desde `main()` **antes** de `runApp`.

Orden dentro de `initDependencies()`:

1. `await Hive.initFlutter()`.
2. Registrar los `TypeAdapter` (`CharacterModelAdapter`, `CharacterAppearanceModelAdapter`, `WalletModelAdapter`, `ScoreModelAdapter`, `EntitlementsModelAdapter`, `AnalyticsEventModelAdapter`).
3. Abrir las cajas (`characters`, `wallet`, `missions`, `scores`, `entitlements`, `analytics_events`, `analytics_meta`).
4. Registrar, por feature: datasource → repository → usecases → BLoC.

Convenciones de registro:

- **`registerLazySingleton`** para datasources, repositorios y usecases (una sola instancia, creada al primer uso).
- **`registerFactory`** para los BLoCs (nueva instancia cada vez que se pide, adecuado para el ciclo de vida de la UI).

Los tres BLoCs globales (`WalletBloc`, `MissionBloc`, `RankingBloc`) se proveen en la raíz con `MultiBlocProvider` en `main.dart`; `WalletBloc` y `MissionBloc` disparan su evento de carga inicial al crearse.

---

## Persistencia con Hive

Hive es una base NoSQL clave-valor local. Cada tipo persistido tiene:

- Un **modelo** en `data/models/<x>_model.dart` que convierte a/desde la entidad de dominio (`toEntity()` / `fromEntity()`).
- Un **TypeAdapter escrito a mano** en `<x>_model.g.dart`.

> **Importante:** los `*.g.dart` **no** se generan con `build_runner`. Están escritos manualmente. Al añadir o quitar campos persistidos hay que editar el adapter a mano (ver [`DESARROLLO.md`](DESARROLLO.md#adapters-de-hive-a-mano)).

Cajas abiertas y su contenido:

| Caja | Tipo | Contenido |
|------|------|-----------|
| `characters` | `CharacterModel` | Personajes guardados. |
| `wallet` | `WalletModel` | Monedas, piezas desbloqueadas, streak, fechas de ruleta/juego. |
| `missions` | `String` | JSON serializado de las 3 misiones activas (clave `active`). |
| `scores` | `ScoreModel` | Puntuaciones del ranking. |
| `entitlements` | `EntitlementsModel` | Gemas, `totalGemsEarned`, suscripción VIP, cosméticos poseídos, `adsRemoved` (vestigial). |
| `analytics_events` | `AnalyticsEventModel` | Eventos de analítica first-party (local). |
| `analytics_meta` | `dynamic` | Metadatos de analítica (primera apertura, días activos, etc.). |

Nótese que `missions` guarda **JSON como String** en vez de un modelo Hive: la entidad `Mission` implementa `toJson`/`fromJson` y el repositorio serializa la lista completa.

Los `typeId` en uso son `0–5` (Character 0, CharacterAppearance 1, Wallet 2, Score 3, Entitlements 4, AnalyticsEvent 5); el próximo libre es **6**.

---

## Gestión de estado (BLoC)

Se usa `flutter_bloc` con el trío clásico por feature:

- `<Feature>Event` — entradas (acciones del usuario/sistema).
- `<Feature>State` — salidas (lo que la UI renderiza).
- `<Feature>Bloc` — mapea eventos a estados invocando usecases.

Todos los estados y eventos usan `Equatable` para comparaciones eficientes y evitar reconstrucciones innecesarias.

Un caso especial: **`BrixRunGame` es un `FlameGame with ChangeNotifier`**. El HUD del runner escucha al juego vía `ChangeNotifier`/`notifyListeners()` en lugar de un BLoC, porque el estado cambia cada frame y conviene el mínimo overhead.

---

## Navegación

`go_router` define rutas declarativas en `app_router.dart`. Ruta inicial: `/` (home).

| Ruta | Nombre | Pantalla |
|------|--------|----------|
| `/` | `home` | Inicio enfocado en la carrera. |
| `/gallery` | `gallery` | Galería de personajes. |
| `/presets` | `presets` | Galería de personajes precargados. |
| `/editor` | `editor-new` | Crear personaje nuevo (acepta un `PresetCharacter?` en `state.extra`). |
| `/editor/:id` | `editor-edit` | Editar personaje existente. |
| `/worlds` | `worlds` | Selección de mundo. |
| `/roulette` | `roulette` | Ruleta diaria. |
| `/wallet` | `wallet` | Billetera: resumen de la economía (se abre al tocar las monedas en Home). |
| `/store` | `store` | Tienda IAP (packs de gemas, VIP, pack de bienvenida). |
| `/gems` | `gems` | Canjería de gemas (cosméticos exclusivos + monedas). |
| `/debug/analytics` | `analytics-debug` | Panel de depuración de la analítica local (accesible desde la hoja del modo de prueba). |
| `/pre-run` | `pre-run` | Pantalla previa a la carrera. |
| `/runner` | `runner` | La partida (Flame). |
| `/ranking/:worldId` | `ranking` | Ranking de un mundo. |

**Detalle importante sobre `extra`:** `/pre-run` y `/runner` reciben datos (personaje, mundo, color, etc.) vía `state.extra`, que es efímero y se pierde al refrescar el navegador o entrar por URL directa. Por eso hay un `redirect` que devuelve a `/` (home) si esas rutas se abren sin `extra`. `errorBuilder` también cae en el home.

---

## Internacionalización (i18n)

La localización está **escrita a mano** (sin `intl`/`gen_l10n`, en línea con el
resto del proyecto). Vive en `lib/core/l10n/`:

- **`app_strings.dart` / `app_strings_extra.dart`** — tablas `clave → { código-idioma → texto }`.
  Cada clave trae los **6 idiomas** soportados. `app_strings_extra.dart` agrupa el
  contenido "de catálogo" (opciones del editor, misiones, accesorios, productos y
  pistas de música).
- **`app_localizations.dart`** — dos APIs:
  - `AppLocalizations` (basada en `BuildContext`): `context.l10n.tr('clave')`,
    `trp` (con sustitución de `{marcadores}`) y **helpers de contenido tipado**
    (`worldName`, `worldDescription`, `bossName`, `partName`, `missionTitle`,
    `storeProductTitle`/`storeProductBadge`, `musicName`/`musicDescription`, …),
    que traducen entidades cuyos campos de respaldo están en español.
  - `L10n` (acceso **global**, sin `BuildContext`): para la capa del juego (Flame),
    que no tiene contexto. El delegado mantiene `L10n.language` en sincronía con
    `MaterialApp` en cada carga de locale.

**Idiomas soportados:** inglés (`en`), español (`es`), portugués (`pt`), alemán
(`de`), ruso (`ru`) y francés (`fr`) — `kSupportedLanguages` en `app_strings.dart`.

**Idioma por defecto / de reserva: inglés** (`kFallbackLanguage = 'en'`). Si una
clave no existe en el idioma activo, cae a inglés y, si tampoco existe, devuelve
la propia clave.

**Detección del idioma:** `MaterialApp.router` usa `localeListResolutionCallback`
(en `main.dart`), que delega en `AppLocalizations.resolveLanguage(deviceLocales)`:
recorre los idiomas del dispositivo en orden de preferencia y elige el primero
soportado (comparando solo `languageCode`, así `pt_BR`/`pt_PT` → `pt`); si ninguno
coincide, cae a inglés.

---

## El motor de juego (Flame)

El corazón del runner es `lib/features/runner/presentation/game/brix_run_game.dart` (`BrixRunGame`). Ver [`JUGABILIDAD.md`](JUGABILIDAD.md) para las mecánicas; aquí solo la arquitectura:

- **`BrixRunGame extends FlameGame with ChangeNotifier`** — orquesta el bucle de juego (`update(dt)`), el spawning, las colisiones y la máquina de estados de la pelea contra el jefe.
- **Componentes** (`game/components/`): `PlayerComponent`, `ObstacleComponent`, `CoinComponent`, `PowerupComponent`, `BackgroundComponent`, `SceneryComponent` (escenografía lateral), `ScorePopupComponent`, `BossComponent` y `BossAttackComponent` (con sus `boss_painters`). Cada uno es un `Component`/`PositionComponent` de Flame que se dibuja por código.
- **Máquina de fases** (`GamePhase`): `running → bossIntro → bossFight → bossDefeated → victory`, gestionada en `_updateBossPhase(dt)`. Durante la pelea se dejan de generar obstáculos/monedas/power-ups, pero la escenografía sigue avanzando.
- **Overlays de Flame** para el HUD (`hud`), la pantalla de fin de partida (`gameOver`) y la de victoria (`victory`), gestionados con `overlays.add/remove`.
- **Colisiones manuales por profundidad**: no se usa el sistema de hitboxes de Flame; en su lugar `_checkDepthCollisions()` (obstáculos/monedas/power-ups) y `_checkBossAttacks()` (ataques del jefe) comparan `depth` y `lane`, lo que encaja con la perspectiva pseudo-3D.

Callbacks hacia la UI:

- `onRunComplete(coins)` — al morir (tras 500 ms) o al vencer al jefe (tras 400 ms), pausa el motor y notifica las monedas ganadas (para registrar la carrera en la economía y el ranking).
- `onHit()` — cada golpe recibido (para feedback háptico/visual).

---

## Diagrama de dependencias

```
                         main.dart
                            │
            ┌───────────────┼────────────────┐
            ▼               ▼                 ▼
   initDependencies    MultiBlocProvider   MaterialApp.router
     (get_it + Hive)   (Wallet/Mission/    (AppRouter →
            │            Ranking Blocs)      go_router)
            ▼
   ┌────────────────────────────────────────────┐
   │   Por feature:                             │
   │   BLoC ─► UseCase ─► Repository (contrato) │
   │                          ▲                 │
   │                          │ impl            │
   │                     RepositoryImpl         │
   │                          │                 │
   │                     Datasource ─► Hive Box │
   └────────────────────────────────────────────┘
```
