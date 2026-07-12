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
- [El motor de juego (Flame)](#el-motor-de-juego-flame)
- [Diagrama de dependencias](#diagrama-de-dependencias)

---

## Visión general

Run For Win (codename **BrixRun** en el código; paquete `lego_custom_character`) es una app Flutter monolítica (un solo paquete) estructurada en **Clean Architecture** y dividida por **features** verticales. Cada feature es autocontenida y se comunica con el resto solo a través de entidades de dominio y de los BLoCs registrados globalmente.

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

Esto permite, por ejemplo, cambiar el backend del ranking de local a remoto tocando **una sola línea** en `injection.dart` (ver comentario en el código: *"Swap ScoreLocalRepository → FirebaseScoreRepository here to go online"*).

---

## Clean Architecture por features

Las features viven en `lib/features/`:

| Feature | Responsabilidad |
|---------|-----------------|
| `home` | Pantalla de inicio enfocada en la carrera (CTA "¡JUGAR!"); ruta inicial. |
| `character_editor` | Crear, editar, listar y borrar personajes (galería + editor), presets precargados y elección de música. |
| `economy` | Monedas, ruleta diaria, cofres, desbloqueo/compra de piezas, streak de juego. |
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
| `theme/app_theme.dart` | Temas claro/oscuro. Colores marca: amarillo LEGO `#FFD700`, azul LEGO `#0055A5`. Fuente `Nunito`. |
| `services/audio_service.dart` | Singleton de audio con un `AudioPlayer` por efecto. |
| `error/failures.dart` | Tipos de fallo para el manejo de errores. |

---

## Inyección de dependencias

Se usa **`get_it`** como *service locator*, expuesto como `sl` (`final sl = GetIt.instance;`). Todo el cableado ocurre en `initDependencies()` (`lib/core/di/injection.dart`), invocado desde `main()` **antes** de `runApp`.

Orden dentro de `initDependencies()`:

1. `await Hive.initFlutter()`.
2. Registrar los `TypeAdapter` (`CharacterModelAdapter`, `CharacterAppearanceModelAdapter`, `WalletModelAdapter`, `ScoreModelAdapter`).
3. Abrir las cajas (`characters`, `wallet`, `missions`, `scores`).
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

Nótese que `missions` guarda **JSON como String** en vez de un modelo Hive: la entidad `Mission` implementa `toJson`/`fromJson` y el repositorio serializa la lista completa.

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
| `/pre-run` | `pre-run` | Pantalla previa a la carrera. |
| `/runner` | `runner` | La partida (Flame). |
| `/ranking/:worldId` | `ranking` | Ranking de un mundo. |

**Detalle importante sobre `extra`:** `/pre-run` y `/runner` reciben datos (personaje, mundo, color, etc.) vía `state.extra`, que es efímero y se pierde al refrescar el navegador o entrar por URL directa. Por eso hay un `redirect` que devuelve a `/` (home) si esas rutas se abren sin `extra`. `errorBuilder` también cae en el home.

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
