# Estado del proyecto y decisiones (handoff entre sesiones)

> Documento de contexto para nuevas sesiones de Claude Code. Resume las
> **decisiones firmes**, lo **construido** y lo **pendiente**. Mantenerlo al día
> al cerrar cada bloque de trabajo.

_Última actualización: rama `claude/vip-benefits` (beneficios VIP)._

## 1. Qué es el proyecto

**Run For Win**: endless runner pseudo-3D (estilo Subway Surfers, 3 carriles,
Flutter + Flame) con un **creador de personajes de bloques** (marca **Brix**) y
peleas contra un jefe al final de cada mundo. Actualmente corre en **web**
(GitHub Pages) como demo; el objetivo es publicar **nativo en iOS + Android**.

## 2. Decisiones de producto (firmes)

- **Público: niños (<13)** → aplica COPPA / GDPR-K / reglas de tiendas Kids.
- **Marca:** el producto se llama **"Run For Win"**; el estilo de bloques es
  **"Brix"** (rebranded fuera de LEGO por riesgo de IP). Codename de código:
  `BrixRun` (`BrixRunApp`, `BrixRunGame`). Paquete Dart: `run_for_win`.
- **Plataformas objetivo:** iOS + Android nativo. La web queda como demo/funnel.
- **Monetización: solo IAP, SIN anuncios en NINGUNA plataforma** (decisión del
  usuario). Motor de ingresos: **cosméticos (IAP) + gemas + suscripción VIP**.
  → No se construye `AdService` ni anuncios recompensados.
- **Cumplimiento infantil:** compuerta parental antes de comprar; analítica
  **first-party** (sin SDK de terceros, requisito iOS Kids); **sin loot boxes con
  dinero real**; **sin pay-to-win**.

## 3. Arquitectura clave

- **Clean Architecture por features** (`domain/` · `data/` · `presentation/`),
  BLoC (`flutter_bloc ^8`), inyección con `get_it` (`core/di/injection.dart`).
- **Patrón interfaz + stub** para todo servicio externo, para no romper la web ni
  depender aún de nativo. Cambiar a la implementación real = **una línea en
  `injection.dart`**:
  - `StoreRepository` → `StubStoreRepository` (compras simuladas).
  - `AnalyticsService` → `LocalAnalyticsService` (analítica local).
  - `ScoreRepository` → `ScoreLocalRepository` (ranking local).
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

### Monetización y economía
- **Rebrand LEGO → Brix** (visible + interno: ids, paquete, assets).
- **Tienda** (`features/monetization`, `/store`) con catálogo (packs de gemas,
  suscripción VIP, pack cosmético) — **compras simuladas (stub)**.
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

### Pulido de juego (calidad, no monetización)
- Atajo **"▶ Jugar"** en galería + **"Guardar y jugar"** (icono bandera) en el
  editor, llevando al selector de mundos con el corredor preseleccionado.
- **Recompensas de victoria** subidas (+500 monedas, +2500 score, +400/embestida).
- **Efecto de derrota del jefe**: estallido de escombros + ondas + desvanecido.
- **Sacudida de pantalla** (embestida y K.O.).
- **Movimiento del jefe en pelea**: respiración, embestida al atacar, inclinación.

## 5. Pendiente (roadmap de monetización, IAP-only)

- **Vías de ganar gemas gratis** además del VIP diario (misiones, hitos).
- **Pase de temporada** (cosméticos estacionales).
- **Pago real**: adaptador `in_app_purchase` que sustituya el stub.

_Hecho recientemente:_ producto "Quitar anuncios" retirado del catálogo (ya no
hay anuncios; `adsRemoved` se conserva por estabilidad de esquema). **Beneficios
VIP reales** implementados (`features/monetization/domain/entities/vip_perks.dart`):
**gemas diarias** reclamables en la Tienda (`claimVipDaily`, +25 💎/día) y
**multiplicador de monedas ×1.5** en carrera (`BrixRunGame.coinMultiplier`, leído
vía `StoreRepository.entitlementsSync()`).

## 6. Acciones del usuario (no-código)

- `flutter create .` para generar `android/` e `ios/` (aún no existen).
- Publicar en **Play Store / App Store** y **dar de alta los productos** (mismos
  SKUs que en `store_product.dart`).
- **Política de privacidad** + formularios de Data Safety / categoría Kids.
- **Rediseño visual del _trade dress_** (minifigura, studs, acabado plástico) —
  es el riesgo de IP real. Painters afectados: `character_preview.dart`,
  `coin_component.dart`, `background_component.dart`, `obstacle_component.dart`,
  `scenery_component.dart`, `appearance_colors.dart`.
- (Recomendado) **Backend** (p. ej. Firebase) para validar recibos y recibir la
  analítica agregada (hoy es local por dispositivo).

## 7. Notas operativas

- **Algunas sesiones remotas no tienen toolchain Flutter/Dart** → los cambios se
  revisan por inspección; **verificar con `flutter analyze` / `flutter run` en
  local**. Objetivo: `analyze` en 0 issues.
- **Rama de desarrollo actual:** `claude/vip-benefits` (PR → `main`). PR #27
  (todo lo anterior) ya está mergeado en `main`.
- **No tocar** el nombre del repo/URLs `/lego-custom-character/` (GitHub Pages)
  sin renombrar el repo en GitHub.
- Docs relacionadas: `MONETIZACION.md`, `JUGABILIDAD.md`, `ARQUITECTURA.md`,
  `DESARROLLO.md`. Documentación de tiendas (política de privacidad, términos,
  ficha, formularios, checklist) en **`docs/publicacion/`** (borradores con
  marcadores `[...]` por rellenar).
