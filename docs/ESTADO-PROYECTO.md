# Estado del proyecto y decisiones (handoff entre sesiones)

> Documento de contexto para nuevas sesiones de Claude Code. Resume las
> **decisiones firmes**, lo **construido** y lo **pendiente**. Mantenerlo al día
> al cerrar cada bloque de trabajo.

_Última actualización: rama `claude/gallery-duplicate-button-2gew4c`
(preparación del MVP v1 para Google Play)._

## 1. Qué es el proyecto

**Run For Win**: endless runner pseudo-3D (estilo Subway Surfers, 3 carriles,
Flutter + Flame) con un **creador de personajes de bloques** (marca **Brix**) y
peleas contra un jefe al final de cada mundo.

**Objetivo inmediato: MVP v1 en Google Play** — app **totalmente autónoma** (sin
backend, sin API, sin red) **con pagos reales** vía Google Play Billing. La web
(GitHub Pages) queda como demo/escaparate con compras simuladas. iOS, después.

## 2. Decisiones de producto (firmes)

- **Público: niños (<13)** → aplica COPPA / GDPR-K / reglas de tiendas Kids.
- **Marca:** el producto se llama **"Run For Win"**; el estilo de bloques es
  **"Brix"** (rebranded fuera de LEGO por riesgo de IP). Codename de código:
  `BrixRun` (`BrixRunApp`, `BrixRunGame`). Paquete Dart: `run_for_win`.
- **Plataformas objetivo:** **Android primero** (MVP v1 en Google Play), iOS
  después. La web queda como demo/funnel.
- **SIN backend ni API en el MVP v1** (decisión del usuario, julio 2026): la app
  es autónoma; el progreso vive en Hive local y los pagos los cobra la tienda de
  Google. `docs/BACKEND-PAGOS.md` queda **archivado como post-MVP**.
- **Monetización: solo IAP, SIN anuncios en NINGUNA plataforma** (decisión del
  usuario). Motor de ingresos: **cosméticos (IAP) + gemas + suscripción VIP**.
  → No se construye `AdService` ni anuncios recompensados.
- **Cumplimiento infantil:** compuerta parental antes de comprar; analítica
  **first-party** (sin SDK de terceros, requisito iOS Kids); **sin loot boxes con
  dinero real**; **sin pay-to-win**.

## 3. Arquitectura clave

- **Clean Architecture por features** (`domain/` · `data/` · `presentation/`),
  BLoC (`flutter_bloc ^8`), inyección con `get_it` (`core/di/injection.dart`).
- **Patrón interfaz + implementación** para todo servicio externo, resuelto por
  plataforma en `injection.dart`:
  - `StoreRepository` → **`InAppPurchaseStoreRepository` en móvil** (pagos
    reales) y `StubStoreRepository` en web (simulados, el plugin no soporta web).
  - `AnalyticsService` → `LocalAnalyticsService` (local, nunca sale del móvil).
  - `ScoreRepository` → `ScoreLocalRepository` (ranking por dispositivo).
- **Hive escrito a mano** (NO `hive_generator`/`build_runner`). `typeId` usados:
  `0` CharacterModel · `1` CharacterAppearanceModel · `2` WalletModel ·
  `3` ScoreModel · `4` EntitlementsModel · `5` AnalyticsEventModel.
  **Próximo typeId libre: `6`.**
- **Cajas Hive:** `characters`, `wallet`, `missions`, `scores`, `entitlements`,
  `analytics_events`, `analytics_meta`.
- **Rutas (`go_router`, `core/router/app_router.dart`):** `home`, `gallery`,
  `editor-new`/`editor-edit`, `presets`, `worlds` (acepta `?character=<id>`),
  `roulette`, `store` (`/store`), `gems` (`/gems`), `analytics-debug`
  (`/debug/analytics`), `pre-run`, `runner`, `ranking`.

## 4. Qué está construido

### Plataforma Android (MVP v1)
- **`android/` generado y configurado**: applicationId **`com.yesithv.runforwin`**
  (inamovible tras publicar), etiqueta "Run For Win", **orientación vertical
  fija**, compileSdk/targetSdk 36, minSdk 24.
- **Firma de release** leída de `android/key.properties` (ignorado por git, con
  plantilla `key.properties.example`); si falta, cae a claves de depuración para
  poder probar en local.
- `versionCode`/`versionName` desde `pubspec.yaml` (`1.0.0+1`).

### Monetización y economía
- **Pagos reales cableados** (`in_app_purchase`): en móvil se registra
  `InAppPurchaseStoreRepository`; en web sigue el stub. Verificado que la build
  web sigue compilando con el adaptador importado.
- **Rebrand LEGO → Brix** (visible + interno: ids, paquete, assets).
- **Tienda** (`features/monetization`, `/store`) con catálogo (packs de gemas,
  suscripción VIP, pack cosmético). SKUs: `vip_monthly`, `gems_small`,
  `gems_medium`, `bundle_starter` — **hay que darlos de alta en Play Console con
  esos mismos IDs**.
- **Compuerta parental** (`ParentalGate`) obligatoria antes de comprar.
- **Entitlements** en Hive (gemas, `adsRemoved`, `subscriptionActive`, poseídos).
- **Canjería de gemas** (`/gems`): precio fijo y determinista (kid-safe), gemas →
  monedas o cosméticos, entregados sobre el wallet existente.
- **Desbloqueo de mundos por acumulación**: un mundo se abre cuando
  `Wallet.totalCoinsEarned >= unlockCost` (permanente; no baja al gastar).
  Costes escalonados (galaxy 500 … robot_city 8000). Barra de progreso en la
  tarjeta. Ver `docs/MONETIZACION.md` y `docs/JUGABILIDAD.md`.

### Analítica
- **First-party, local** (`features/analytics`): `AnalyticsService.track(...)`,
  resumen de funnel + retención D1/D7, y **panel de depuración** (`/debug/analytics`,
  accesible desde la hoja del modo de prueba). Eventos: `app_open`, `run_start`,
  `run_victory`, `run_death`, `roulette_spin`, `store_open`, `gem_store_open`,
  `gem_redeem`, `parental_gate_*`, `purchase_*`.

### Herramientas de desarrollo
- **Modo de prueba** (`core/test_mode/test_mode.dart`): mantener pulsado el
  título "RUN FOR WIN" en el Home → interruptor. Desbloquea todo (ruleta,
  accesorios, mundos), hace la pista muy corta (20 m) y el jefe débil (1 corazón).

### Ritmo de partida y ajustes de juego
- **Pistas dimensionadas por duración objetivo**, no por porcentaje
  (`worldTrackMeters`: **500 … 1100 m** → de 2,2 min en la pista inicial a
  3,8 min en la última, **media ≈ 3 min**). Antes: 4-6,5 min (media 5,3).
  ⚠️ **Ojo con la aritmética al retocarlas:** la velocidad sube con el tiempo
  (220 px/s +12 cada 5 s), así que la duración **no** es proporcional a la
  distancia — el primer intento (−20 % de metros) solo quitó un 14 % de tiempo.
  Referencias con la velocidad actual: 2 min ≈ 430 m · 2,5 min ≈ 590 m ·
  3 min ≈ 775 m · 3,5 min ≈ 975 m.
- Con las pistas se reescalaron sus dos dependencias: **umbrales de zona**
  (200/600) y **objetivos de las misiones de distancia** (100/250/450), para que
  la dificultad progrese igual y las misiones sean alcanzables ya en el primer
  mundo (500 m).
- **Economía sin retocar a propósito:** se gana ~40 % menos monedas por carrera,
  pero las carreras duran ~42 % menos, así que las monedas por minuto quedan
  igual y las victorias (+500) llegan más a menudo. Los costes de desbloqueo de
  mundos siguen valiendo.
- **HUD sin contador de metros**: el avance lo comunica la barra vertical de
  progreso de la derecha; los metros se ven en el resumen final.
- **Atajo del modo de prueba endurecido**: hay que mantener pulsado el título
  10 s (antes 500 ms), sin pista visual.
- **Icono propio** generado por código (`tool/gen_icon.dart`): clásico en 5
  densidades + adaptativo (Android 8+) + 512² para la ficha; splash azul Brix.

### Pulido de juego (calidad, no monetización)
- Atajo **"▶ Jugar"** en galería + **"Guardar y jugar"** (icono bandera) en el
  editor, llevando al selector de mundos con el corredor preseleccionado.
- **Recompensas de victoria** subidas (+500 monedas, +2500 score, +400/embestida).
- **Efecto de derrota del jefe**: estallido de escombros + ondas + desvanecido.
- **Sacudida de pantalla** (embestida y K.O.).
- **Movimiento del jefe en pelea**: respiración, embestida al atacar, inclinación.

## 5. Pendiente

### Para lanzar el MVP v1 (bloqueadores, ninguno es código de la app)
- **Icono y splash propios** (hoy el icono por defecto de Flutter).
- **Productos IAP dados de alta** en Play Console con los IDs del catálogo.
- **Política de privacidad en URL pública** + Data Safety + IARC + "Diseñado
  para familias" (borradores en `docs/publicacion/`).
- **Keystore de subida** creado y `android/key.properties` rellenado.
- **Rediseño del _trade dress_** (riesgo de IP).
- **Decidir qué hacer con el "modo de prueba"** (`core/test_mode/test_mode.dart`):
  hoy un pulsado largo en el título desbloquea todo gratis. Conviene desactivarlo
  en builds de release antes de publicar con IAP.
- **Verificar `flutter build appbundle --release` en local** (este entorno remoto
  no tiene Android SDK: `dl.google.com` está bloqueado por la política de red).

### Post-MVP (no bloquea)
- **Vías de ganar gemas gratis** además del VIP diario (misiones, hitos).
- **Pase de temporada** (cosméticos estacionales).
- **Backend** (validación de recibos, vencimiento de suscripción, ranking global,
  analítica agregada) → `docs/BACKEND-PAGOS.md`, archivado.

_Hecho recientemente:_ producto "Quitar anuncios" retirado del catálogo (ya no
hay anuncios; `adsRemoved` se conserva por estabilidad de esquema). **Beneficios
VIP reales** implementados (`features/monetization/domain/entities/vip_perks.dart`):
**gemas diarias** reclamables en la Tienda (`claimVipDaily`, +25 💎/día) y
**multiplicador de monedas ×1.5** en carrera (`BrixRunGame.coinMultiplier`, leído
vía `StoreRepository.entitlementsSync()`).

## 6. Acciones del usuario (no-código)

- Publicar en **Google Play** y **dar de alta los productos** (mismos SKUs que en
  `store_product.dart`). App Store, más adelante (`ios/` aún no existe).
- **Política de privacidad** + formularios de Data Safety / categoría Kids.
- **Rediseño visual del _trade dress_** (minifigura, studs, acabado plástico) —
  es el riesgo de IP real. Painters afectados: `character_preview.dart`,
  `coin_component.dart`, `background_component.dart`, `obstacle_component.dart`,
  `scenery_component.dart`, `appearance_colors.dart`.
- ~~Backend para validar recibos~~ → **descartado en el MVP v1**. El diseño
  queda archivado en `docs/BACKEND-PAGOS.md` por si se retoma.

## 7. Notas operativas

- **Algunas sesiones remotas no traen toolchain Flutter/Dart** (se puede
  instalar el SDK: `storage.googleapis.com` está permitido). **El Android SDK NO
  se puede instalar** ahí: `dl.google.com` está bloqueado → la build de Android
  se verifica siempre en local. Objetivo: `analyze` en 0 issues.
- El proyecto **no tiene `analysis_options.yaml`** a propósito: añadir
  `flutter_lints` saca 28 avisos cosméticos (`prefer_const`, llaves en `if`).
  Si se añade, limpiarlos en un cambio aparte.
- **Rama de desarrollo actual:** `claude/gallery-duplicate-button-2gew4c`
  (PR → `main`).
- **No tocar** el nombre del repo/URLs `/lego-custom-character/` (GitHub Pages)
  sin renombrar el repo en GitHub.
- Docs relacionadas: `MONETIZACION.md`, `BACKEND-PAGOS.md`, `JUGABILIDAD.md`,
  `ARQUITECTURA.md`, `DESARROLLO.md`. Documentación de tiendas (política de
  privacidad, términos, ficha, formularios, checklist) en **`docs/publicacion/`**
  (borradores con marcadores `[...]` por rellenar).
