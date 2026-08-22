# Auditoría de performance, pruebas y estructura (2026-08)

> Registro de la auditoría hecha en la rama `claude/code-audit-performance-wvvqw8`
> (PR #71). Objetivo doble del usuario: **(1)** que el juego no se sienta lento
> ni se congele (jank), y **(2)** mejorar la estructura/legibilidad del código y
> su cobertura de pruebas. Todos los cambios se hicieron **sin alterar el
> comportamiento ni lo visual** (verificado con `flutter analyze`, `flutter test`
> y `flutter build web` en cada commit).

## Resumen

| Métrica | Antes | Después |
|---|---|---|
| Tests | 111 | **184** (+73) |
| `flutter analyze` | sin `analysis_options` | **0 issues** con `flutter_lints` |
| CI en PR/push | solo `build web` | **`analyze` + `test`** + `build` (deploy depende de ellos) |
| `runner_page.dart` | 2865 líneas | **498** (+ 2 archivos `part`) |
| `brix_run_game.dart` | 1077 líneas | **756** (+ 4 sistemas) |

---

## Fase 1 — Performance (quitar el jank)

Principio: **ningún frame debe hacer trabajo evitable**. Orden por impacto.

1. **HUD sin reconstrucción por frame.**
   `runner_page.dart` (ahora `runner_hud.dart`). El HUD usaba un `Ticker` que
   llamaba `setState(() {})` en **cada frame**, reconstruyendo todo su árbol
   (gradientes, sombras, `CustomPaint`, corazones) 60 veces/s aunque nada
   cambiara.
   - Nuevo **`HudData`** (`game/hud_data.dart`): instantánea **discreta** del
     estado del HUD (segundos enteros, carga en %, progreso en milésimas) con
     `==` por campos.
   - `BrixRunGame` la publica en un `ValueNotifier<HudData>` (`_publishHud`); el
     HUD la escucha con `ValueListenableBuilder` + `RepaintBoundary`, así solo se
     reconstruye cuando algún valor cambia de verdad (unas pocas veces/seg).

2. **`notifyListeners()` por frame eliminado.**
   El bucle `update()` llamaba `notifyListeners()` cada frame sin ningún oyente
   real (el HUD usaba su propio `Ticker`). Se sustituyó todo por `_publishHud()`.

3. **Sin trabajo caro en los `render()`.**
   - `lightenColor`/`darkenColor` (`appearance_colors.dart`) **memoizan** el
     round-trip HSL (claves acotadas: colores de paletas const × cantidades
     fijas). `obstacle_component` y `boss_painters` delegan en ellos.
   - `background_component` (mundo *galaxy*): las 60 estrellas se generan **una
     sola vez** en fracciones de pantalla (mismo orden de RNG → idénticas) en vez
     de crear `Random(77)` + 60 círculos cada frame.
   - `coin_component`: de ~7 `Paint()` por moneda por frame a `Paint` estáticos
     reutilizados.

4. **Colisiones sin `whereType().toList()` por frame.**
   `_checkDepthCollisions`/`_checkBossAttacks` recorrían todo el árbol y
   materializaban una lista nueva 3-4 veces por frame. Ahora `BrixRunGame`
   mantiene listas tipadas (`activeObstacles`/`activeCoins`/`activePowerups`/
   `activeBossAttacks`) que cada componente actualiza solo en `onMount`/`onRemove`.

5. **Precarga de audio.**
   `AudioService.preload()` (llamado desde `main`) carga todos los efectos `.wav`
   en la caché al arrancar, para que la primera reproducción de cada uno no
   decodifique el asset en pleno juego (micro-tirón).

### Diferido a propósito
- **Object pooling de spawnables:** los componentes se crean solo unos pocos por
  segundo (obstáculo 0.65–2.2 s, moneda 0.9 s, escenografía 0.55 s) — no es
  fuente de jank. La presión de GC real era por frame (paints/HSL/listas), ya
  resuelta. El pooling añadía complejidad/riesgo desproporcionados.

---

## Fase 2 — Pruebas (cobertura + edge cases + UI)

Se activaron los dev-deps ya declarados pero sin usar (`bloc_test`, `mocktail`).
Nuevos archivos en `test/`:

- `wallet_bloc_test.dart` / `wallet_repository_test.dart` — economía: earn/spend
  (guarda anti-negativo), unlock (cobro/guarda/no duplica), ruleta, cofre y
  **racha por días** de `recordRunCompletion` (primera, día siguiente, hueco).
- `mission_bloc_test.dart` / `ranking_bloc_test.dart` — blocs de misiones y
  ranking (detección de recién completadas, recarga por mundo, lista vacía).
- `stub_store_repository_test.dart` — compra (gems consumible recomprable,
  suscripción, no-consumible ya poseído, pack de bienvenida), `spendGems`,
  `grantGems`, `claimVipDaily`.
- `character_editor_bloc_test.dart` — guardar (válido / sin nombre / límite
  gratis) y borrar.
- `game_loop_test.dart` / `hud_data_test.dart` — zonas de dificultad,
  multiplicador VIP fraccionario, doble de moneda del villano, tiers de racha,
  activación de power-ups, y la igualdad por campos de `HudData`.
- `world_config_test.dart` / `mission_card_test.dart` — fallbacks de mundo
  desconocido y smoke de UI.

**CI:** nuevo job `test` (`flutter analyze` + `flutter test`) en push y PR; el
`deploy` pasa a depender de `[test, build]`. Antes el CI solo compilaba la web:
ahora "verde" también exige análisis limpio y pruebas en verde.

---

## Fase 3 — Estructura

1. **Linter.** `analysis_options.yaml` con `package:flutter_lints/flutter.yaml`.
   Solo había 4 avisos (`unnecessary_getters_setters`): los campos
   `collected`/`evaded`/`collided` de los componentes pasaron a campos públicos
   directos. `analyze` queda en 0 issues, verificado por el CI.

2. **`runner_page.dart` partido** (2865 → 498) con `part`/`part of` (sin tocar
   privacidad ni imports):
   - `runner_page.dart` — `RunnerPage` + `_RunnerPageState` (orquestador).
   - `runner_hud.dart` — `_HudOverlay` y los chips del HUD.
   - `runner_overlays.dart` — pause / continue / game over / victory + auxiliares.

3. **Motor descompuesto en sistemas** (`brix_run_game.dart` 1077 → 756).
   Colaboradores reales en `game/systems/` (declarados como `part` de la misma
   librería, para operar sobre el estado del juego vía una referencia sin ampliar
   la API pública, que sigue igual — `phase`/`bossHearts`/`dashCharge`/
   `onAttackDodged`…):
   - `BossFightController` — máquina de fases del jefe, ataques, embestida, derrota.
   - `SpawnSystem` — fábrica de obstáculos/monedas/power-ups/escenografía.
   - `TutorialDirector` — secuencia guiada de 4 pasos.
   - `CollisionSystem` — colisiones por profundidad.

---

## Notas de mantenimiento

- **`pubspec.lock` no se tocó**: la auditoría se verificó con la Flutter stable
  del entorno; el CI resuelve dependencias igual que en `main`.
- Toda la lógica de economía/balance y los `typeId` de Hive se conservan
  (próximo `typeId` libre sigue siendo **6**).
- Documentos relacionados actualizados: `ARQUITECTURA.md` (sistemas del motor y
  split del runner_page) y `ESTADO-PROYECTO.md` (nota del linter).
