# Jugabilidad y economía

Documentación de las reglas del juego tal como están implementadas. Todos los valores citados provienen del código (`brix_run_game.dart`, `boss_config.dart`, `wallet_repository_impl.dart`, `part_catalog.dart`, `mission_repository_impl.dart`, `music_catalog.dart`). Si cambias el balance del juego, actualiza también este documento.

## Índice

- [El editor de personajes](#el-editor-de-personajes)
- [Personajes precargados (presets)](#personajes-precargados-presets)
- [Música de partida](#música-de-partida)
- [El endless runner](#el-endless-runner)
  - [Perspectiva pseudo-3D](#perspectiva-pseudo-3d)
  - [Controles](#controles)
  - [Zonas de dificultad](#zonas-de-dificultad)
  - [Velocidad y spawning](#velocidad-y-spawning)
  - [Colisiones](#colisiones)
  - [Puntuación](#puntuación)
  - [Power-ups](#power-ups)
  - [Tipos de personaje (bonus)](#tipos-de-personaje-bonus)
- [Peleas contra jefes](#peleas-contra-jefes)
- [Economía](#economía)
  - [Ruleta diaria](#ruleta-diaria)
  - [Cofres](#cofres)
  - [Streak de juego](#streak-de-juego)
  - [Tienda de piezas](#tienda-de-piezas)
- [Misiones](#misiones)
- [Ranking](#ranking)
- [Mundos](#mundos)
- [Modo de prueba (desarrollo)](#modo-de-prueba-desarrollo)

---

## El editor de personajes

Un personaje (`Character`) tiene: `id`, `name`, `type`, `specialPower` opcional, `appearance`, marcas de tiempo y estadísticas (`totalCoinsEarned`, `bestRunScore`). (El campo heredado `musicTrack` se conserva solo por compatibilidad con datos guardados; la música ya no se elige por personaje — ver [Música de partida](#música-de-partida)).

La apariencia (`CharacterAppearance`) se compone por capas:

- **Cara:** tono de piel (`SkinTone` — 3 realistas + 6 fantásticos), ojos (`EyeStyle`, 11 estilos), boca (7), cejas (5), extra facial (freckles, blush, scar, tatuaje, pintura de guerra, monóculo…).
- **Cabeza:** `headwearType` = pelo / casco / sombrero. Cada uno con sus variantes (`HairStyle` 16 peinados, `HelmetStyle` 14 cascos —incluidas capuchas de superhéroe como Iron Man, Spider-Man, Black Panther, Deadpool, Wolverine…—, `HatStyle` 8 sombreros).
- **Torso:** 28 diseños (`TorsoDesign`: policía, bombero, astronauta, ninja, pirata, superhéroe, samurái, robot, alien, táctico, comando, dorado, y heroínas como Spider-Gwen, Wonder Woman, Captain Marvel…), con opción de capa (`hasCape`).
- **Manos:** guantes (`GloveType`: boxeo, medieval, superhéroe, garras, energía, telaraña; más `none`).
- **Piernas y pies:** diseño (`LegDesign`, 13 opciones), tipo (`LegType`: pantalón, shorts, falda, armadura, traje espacial) y calzado (`ShoeType`: 11 tipos).
- **Accesorios:** 8 ranuras (`rightHand`, `leftHand`, `back`, `shoulders`, `waist`, `neck`, `face`, `feet`).

El personaje se dibuja por código (formas y colores), no con sprites, y se guarda en Hive (caja `characters`).

> **Estabilidad de enums:** Hive persiste los enums por **índice**, así que los valores nuevos se **añaden siempre al final** de cada enum (ver comentarios en `character.dart`). Nunca reordenes ni intercales valores: romperías los personajes ya guardados.

## Personajes precargados (presets)

`preset_characters.dart` define una lista de `PresetCharacter`: personajes listos (nombre + apariencia + tipo) agrupados por **colección** (p. ej. *Ninjas dorados*, *Superhéroes*). Desde la galería de presets (`/presets`) el usuario elige uno y se carga en el editor como un personaje **nuevo y editable** (se pasa como `state.extra` a `/editor`), de modo que puede ajustar boca, pelo, accesorios, etc., antes de guardarlo.

## Música de partida

La música es **temática de cada mundo** y se elige justo antes de correr, no por personaje. En la pantalla previa (`PreRunPage`, tras seleccionar un mundo) el jugador:

1. Decide con un interruptor si quiere música de fondo (activada por defecto).
2. Si la activa, elige una de las **2 pistas ambientadas en ese mundo** —una enérgica (`_1`) y otra más tranquila (`_2`)— (p. ej. en el Reino Medieval: *Marcha del Castillo* y *Taberna del Reino*). Puede escuchar cada una con ▶ antes de decidir. Los nombres/descripciones se traducen a cada idioma (claves `music_<id>_name`/`_desc`).

El repertorio por mundo está en `runner/domain/entities/world_music.dart` (`worldMusicCatalog`, `worldTracksFor(worldId)`). Cada pista tiene su **propio fichero** en `assets/audio/music/<mundo>_<n>.mp3`. La producción actual (Suno + REAPER) y los prompts están documentados en [`MUSICA.md`](MUSICA.md); el sintetizador chiptune `tool/gen_music.py` es el enfoque anterior y ya no genera los audios en uso. La v2 contempla volver a 4 pistas por mundo.

La pista elegida (o `null` si la música está desactivada) se pasa al `RunnerPage` como `musicAsset`. El runner la reproduce con `AudioService.playMusic(asset)` en `ReleaseMode.loop` y volumen `0.55`; si es `null`, corre en silencio. `toggleMusicMute()` la silencia en caliente sin cortar la pista. Los fallos de reproducción (p. ej. autoplay bloqueado en web) se ignoran silenciosamente.

---

## El endless runner

### Perspectiva pseudo-3D

El runner simula 3D con matemática de perspectiva (estilo Subway Surfers). Los objetos aparecen en el horizonte (`depth 0`) y se acercan a la cámara (`depth 1` = nivel del jugador).

| Concepto | Valor / fórmula |
|----------|-----------------|
| Línea de horizonte | `horizonY = size.y * 0.37` |
| Nivel del jugador | `playerBaseY = size.y * 0.88` |
| Punto de fuga (X) | `vanishX = size.x / 2` |
| Separación de carriles | `laneSep = size.x * 0.265` |
| Escala por profundidad | `0.07 + 0.93 * depth` (diminuto en el horizonte, tamaño real junto al jugador) |
| Avance de profundidad | `depthRate = 0.42 * (speed / 220)` unidades/seg |

Hay **3 carriles**. `perspectivePos(lane, depth)` interpola entre el punto de fuga y la posición del carril al nivel del jugador.

> **Posición del corredor (global a todas las pistas).** `playerBaseY` es la
> **única** fuente de verdad de la altura del corredor: no depende del `worldId`,
> así que el corredor se sitúa igual en las 8 pistas. Se bajó de `0.81 → 0.88`
> para dejar más recorrido visible por delante (más tiempo de reacción ante los
> obstáculos). **Invariante clave:** como la colisión se decide en `depth == 1.0`
> y `perspectivePos(*, 1.0).y` vale exactamente `playerBaseY`, al mover al
> corredor el punto donde los obstáculos lo golpean baja **junto con él**, sin
> tocar la lógica de colisión. Cubierto por `test/player_position_test.dart`.

### Controles

| Gesto | Acción |
|-------|--------|
| Swipe arriba / tap | Saltar |
| Swipe abajo | Deslizarse (pasar por debajo de barreras) |
| Swipe izquierda / derecha | Cambiar de carril |

> **HUD lateral (solo display, `IgnorePointer`).** Para despejar la vista de la
> parte alta de la pista, el **dock de power-ups** (izquierda) y la **barra de
> distancia** (derecha) se colocan bien abajo en `runner_page.dart`: el dock en
> `Align(-1.0, 0.55)` y la barra en `Positioned(top: 230, bottom: 90)`. Así queda
> despejada la esquina superior por donde entran los obstáculos.

### Zonas de dificultad

La dificultad aumenta según los metros recorridos (`meters`):

| Zona | Rango | Bonus de velocidad | Extra |
|------|-------|--------------------|-------|
| `inicio` | 0–199 m | +0 | — |
| `nucleo` | 200–599 m | +60 | — |
| `caos` | ≥ 600 m | +160 | 20% de probabilidad de un segundo obstáculo en otro carril |

> Los umbrales se mueven con la longitud de las pistas (`worldTrackMeters` en
> `world_config.dart`) para que la progresión caiga siempre en el mismo punto
> relativo: `inicio` cubre el primer ~40 % de la pista inicial y `caos` solo
> aparece en los mundos avanzados. Histórico: 500/1500 → 400/1200 → 200/600.

### Velocidad y spawning

- **Velocidad inicial:** `220 px/s`. Sube `+12` cada `5 s`, con tope en `900`.
- **Velocidad efectiva** = `speed + bonus de zona`.
- **Obstáculos:** intervalo de spawn = `(2.2 - velEfectiva/900)` acotado a `[0.65, 2.2]` s. Tipos por probabilidad: barrera 20%, pincho 15%, bloque 65%.
- **Monedas:** una cada `0.9 s`, en carril aleatorio.
- **Power-ups:** uno cada `12 s`, de **tres tipos equiprobables** (shield / magnet / boost, 1/3 cada uno; `PowerupType.values[_rng.nextInt(3)]`).
- **Escenografía lateral:** `SceneryComponent` a los lados de la pista cada `0.55 s` (variantes temáticas por mundo). Se siembra al inicio para que el mundo no arranque vacío.

> Obstáculos, monedas y power-ups **solo** aparecen en la fase `running`. Al empezar la pelea contra el jefe (`bossFight`) dejan de generarse, pero la escenografía sigue avanzando para que el mundo no se congele.

### Colisiones

Detección manual por proximidad de profundidad (`_checkDepthCollisions`), no por hitboxes:

- El obstáculo se resuelve al cruzar el **plano del corredor** (`_collisionDepth = 1.0`), que se dibuja justo a la altura de `playerBaseY` (ver invariante en [Perspectiva pseudo-3D](#perspectiva-pseudo-3d)): el golpe ocurre donde está el personaje, no en un punto fijo de la pantalla.
- Ventana de impacto de monedas/power-ups: `depth ∈ [0.87, 1.11]` **y** mismo carril que el jugador.
- Un obstáculo se marca como **evadido** al superar `depth ≥ 1.16` sin colisión.
- **Salto:** con `jumpProgress ∈ (0.10, 0.90)` se libran **todos** los obstáculos.
- **Deslizamiento:** solo libra las **barreras** (`ObstacleType.barrier`).
- **Monedas:** se recogen en la ventana de impacto si coinciden de carril; con **imán** activo también valen los carriles adyacentes (`|lane - playerLane| == 1`).

### Puntuación

```
score = (meters + coins*5 + obstacleStreak*2) * multiplier + bossBonusScore
```

- `meters = distanciaRecorrida / 100`. **No se muestran en el HUD durante la
  carrera** (el avance lo indica la barra vertical de progreso de la derecha);
  aparecen en el resumen de fin de carrera.
- `bossBonusScore` acumula los bonus de la pelea: `+400` por cada embestida al jefe (`_dashScoreBonus`) y `+2500` al vencerlo (`_victoryScoreBonus`) (ver [Peleas contra jefes](#peleas-contra-jefes)).
- El **multiplicador** depende de la racha de obstáculos evadidos (`obstacleStreak`):

| Racha evadida | Multiplicador |
|---------------|---------------|
| < 10 | ×1 |
| 10–24 | ×2 |
| 25–49 | ×3 |
| ≥ 50 | ×5 |

### Power-ups

| Power-up | Duración | Efecto |
|----------|----------|--------|
| 🛡️ Shield | 10 s | Absorbe un golpe sin morir (`_shieldPowerupDuration`). |
| 🧲 Magnet | 5 s | Atrae monedas de los carriles adyacentes (`_magnetDuration`). |
| ⚡ Boost | 4 s | Ráfaga de velocidad (`_boostDuration`, `+230` a la velocidad) con líneas cinéticas y sacudida. |

Al recibir un golpe con escudo activo (de power-up o de héroe), se consume el escudo y se sobrevive. Sin escudo, la partida termina: el jugador "muere", suena el golpe, aparece el overlay `gameOver` y, 500 ms después, se pausa el motor y se llama a `onRunComplete(coins)`.

### Tipos de personaje (bonus)

El `CharacterType` otorga ventajas al empezar la partida (`onLoad`):

| Tipo | Bonus |
|------|-------|
| `hero` | Empieza con **escudo** (un golpe gratis). |
| `mysterious` | Empieza con `obstacleStreak = 10` y **multiplicador ×2**. |
| `villain` | Cada moneda vale **2** en vez de 1 (`collectCoin`). |
| `neutral` | Sin bonus. |

---

## Peleas contra jefes

Al alcanzar `bossTriggerMeters` la partida entra en una máquina de fases (`GamePhase`). Por defecto ese umbral es la **longitud de la pista del mundo** (`trackMetersFor(worldId)`, de **500 m** en Ciudad Brix a **1100 m** en Metrópolis Robot; **20 m** en modo de prueba), así que el jefe aparece al final de cada pista. El constructor acepta `bossTriggerMeters` para forzarlo en los tests:

```
running → bossIntro → bossFight → bossDefeated → victory
```

- **`bossIntro`:** aparece el `BossComponent` con la animación de entrada y un cartel con el nombre/emoji del jefe.
- **`bossFight`:** el jefe lanza ataques a intervalos; el jugador los esquiva y carga la embestida.
- **`bossDefeated`:** tras agotar sus corazones, 1.5 s de animación de derrota.
- **`victory`:** overlay de victoria y, 400 ms después, fin de carrera.

### Corazones, ataques y embestida

- El jefe tiene **3 corazones** (`maxBossHearts`).
- **Cada ataque esquivado** carga la embestida `+0.2` (`_chargePerDodge`). Al llegar a `1.0` el jugador **embiste** automáticamente: quita **1 corazón**, suma **+400** al score y limpia los ataques en vuelo.
- El jefe se **enfurece** al perder corazones: el intervalo entre ataques baja de `1.15 s → 0.90 s → 0.70 s`. Enfurecido, a veces lanza un segundo proyectil en otro carril (35% en ataques de proyectil).

### Tipos de ataque (cada uno se contrarresta con un control)

| Ataque | Cómo se esquiva |
|--------|-----------------|
| `projectile` | Viaja por un carril → **cambiar de carril** (o saltar). |
| `shockwave` | Onda baja a todo lo ancho → **saltar**. |
| `sweep` | Barrido alto a todo lo ancho → **deslizarse**. |

Ser golpeado por un ataque del jefe equivale a un golpe normal: con escudo se consume el escudo; sin escudo, fin de partida.

### Recompensas por victoria

Al vencer al jefe: **+200 monedas** (`victoryCoinBonus`) y **+2500** al score (`bossBonusScore`), además de **+400** al score por cada embestida acertada (`_dashScoreBonus`). Luego `onRunComplete(coins)`.

> El bonus de victoria bajó de **500 → 200** para frenar la inflación de monedas
> (con 500, una sola victoria compraba cualquier épico y abría el 2.º mundo). Ver
> `docs/ECONOMIA.md`.

### Jefes por mundo

`boss_config.dart` define un jefe por mundo, cada uno con nombre, emoji, colores y **pesos de ataque** propios (su "personalidad"):

| Mundo | Jefe |
|-------|------|
| `brix_city` | 🏗️ Capataz Demoledor |
| `medieval` | 🐉 Dragón Oscuro |
| `galaxy` | 👾 Overlord Zenth |
| `jungle` | 🦍 Gran Gorila |
| `dark_city` | 🦹 Señor Sombra |
| `ocean` | 🐙 Kraken Abisal |
| `tundra` | ❄️ Yeti Glacial |
| `robot_city` | 🤖 Mega-Bot X9 |

`bossFor(worldId)` cae en el jefe de `brix_city` si el ID no existe.

---

## Economía

El monedero (`Wallet`) guarda: `coins`, `unlockedParts`, `runStreak`, `lastRouletteDate`, `lastPlayDate`, `totalCoinsEarned`.

### Sistema de premios (ruleta y cofres)

Los premios se construyen en `reward_pools.dart` con `buildRewardTable`, que
combina **recompensas fijas de monedas** con un **pool de accesorios derivado del
catálogo** (`droppableAccessories`: piezas del `partCatalog` que **no** son
`premium` ni gratuitas — en la práctica, rares/epics y cualquier legendaria
futura). El pool se normaliza a una `accessoryFraction` objetivo, así la
proporción monedas/accesorios se mantiene estable aunque el catálogo crezca.
Dentro del bucket de accesorios, el peso por rareza es común 12 · rara 6 · épica
2 · legendaria 1. Si el accesorio premiado **ya se posee**, se entrega su valor en
**monedas de consuelo** (`coinValueForRarity`: común 50 · rara 150 · épica 350 ·
legendaria 750), para que ningún premio se sienta vacío.

### Ruleta diaria

Reclamable una vez por día natural (`canClaimRoulette` compara año/mes/día con
`lastRouletteDate`). Monedas fijas + **20 %** de accesorio rare/epic
(`accessoryFraction: 0.20`):

| Premio de monedas | Peso |
|-------------------|------|
| 50 monedas | 30 |
| 100 monedas | 25 |
| 200 monedas | 15 |
| 500 monedas | 10 |

Más accesorios **rare/epic** del catálogo (≈20 % del total), elegidos por peso de rareza.

### Cofres

**Cofre común** (fin de carrera): monedas modestas + **30 %** de accesorio rare/epic.

| Premio de monedas | Peso |
|-------------------|------|
| 30 monedas | 50 |
| 75 monedas | 25 |

**Cofre VIP** (se obtiene con racha ≥ 3): monedas generosas + **65 %** de accesorio
**rare/epic/legendary**.

| Premio de monedas | Peso |
|-------------------|------|
| 150 monedas | 30 |

Las piezas repetidas no se duplican: si ya está en `unlockedParts`, se entrega el equivalente en monedas de consuelo.

### Streak de juego

`recordRunCompletion(coins)` se llama al terminar cada carrera:

- Suma las monedas ganadas al monedero y a `totalCoinsEarned`.
- Actualiza la **racha de días** (`runStreak`): se incrementa si la última partida fue en un día distinto dentro de las últimas 24 h; si no, se reinicia a 1.
- Con `runStreak >= 3`, `earnVipChest` es `true` → el jugador puede abrir cofre VIP.

### Tienda de piezas

`part_catalog.dart` define el catálogo de accesorios (~60 entradas) repartidas entre las 8 ranuras; muchas piezas comunes (incluidas las femeninas) son gratuitas. Coste por rareza:

| Rareza | Coste (monedas) |
|--------|-----------------|
| `common` | 0 (gratis) |
| `rare` | 200 |
| `epic` | 500 |
| `legendary` | 1000 |

`UnlockPart(partId, cost)` descuenta monedas y añade la pieza a `unlockedParts` solo si hay saldo suficiente; devuelve `success: false` si no.

**Piezas premium (exclusivas de la Tienda):** algunas piezas llevan el flag
`CatalogEntry.premium` (hoy `capa vampiro` y `botas propulsión`). **No se compran
con monedas**: en el editor aparecen bloqueadas con 💎 y llevan a la canjería de
gemas. Es lo que da a las gemas un uso real sin quedar "dominadas" por un precio
en monedas más barato. Ver `docs/ECONOMIA.md`.

Emojis de rareza (en recompensas): común ⚙️, rara 💎, épica ⚡, legendaria 👑.

---

## Misiones

Siempre hay **3 misiones activas** (caja `missions`, guardadas como JSON). Se generan a partir de 13 plantillas, eligiendo 3 de **tipos distintos** al azar.

Tipos de misión (`MissionType`) y ejemplos de objetivo:

| Tipo | Ejemplos (objetivo → recompensa) |
|------|----------------------------------|
| `collectCoins` | 10 → 50, 25 → 100, 50 → 200 monedas |
| `runMeters` | 100 → 50, 250 → 100, 450 → 200 |
| `evadeObstacles` | 5 → 50, 10 → 100, 20 → 200 (seguidos) |
| `surviveSeconds` | 30 → 75, 60 → 150 |
| `useJump` | 5 → 50, 15 → 100 |

Al terminar una carrera, `advanceMissions(MissionRunData)` suma el progreso correspondiente a cada misión (monedas, metros, obstáculos evadidos, segundos, saltos). Cuando **todas** las misiones activas se completan, se regeneran automáticamente 3 nuevas.

**Recompensa al completar (se paga de verdad):** cuando una misión pasa a
completada, `runner_page` acredita su `rewardCoins` al monedero (`EarnCoinsEvent`)
y regala **+1 💎** por misión (faucet gratuito de gemas). Antes las recompensas
se mostraban pero **nunca se otorgaban** — corregido. Ver `docs/ECONOMIA.md`.

---

## Ranking

Puntuaciones locales por mundo (caja `scores`, `ScoreModel`). Al terminar una carrera se registra la puntuación bajo el `worldId` correspondiente. La pantalla `/ranking/:worldId` muestra la tabla de ese mundo.

> En el **MVP v1 el ranking es local por dispositivo**: la app no habla con ningún servidor. El repositorio está detrás de la interfaz `ScoreRepository`, así que un ranking global sería otra implementación registrada en `injection.dart` — fuera del alcance de esta versión.

---

## Mundos

8 mundos temáticos definidos en `world_config.dart` (paletas de color, incluidos colores de obstáculo por mundo) y `world_selection_page.dart` (metadatos y estado). Cada mundo tiene colores de cielo, midground, suelo y acento propios, y su propio [jefe](#jefes-por-mundo).

| ID | Nombre | Desbloqueo | Jefe |
|----|--------|-----------|------|
| `brix_city` | Ciudad Brix 🏙️ | Inicial | 🏗️ Capataz Demoledor |
| `medieval` | Reino Medieval 🏰 | Inicial | 🐉 Dragón Oscuro |
| `galaxy` | Galaxia Brix 🚀 | 🪙 500 acumuladas | 👾 Overlord Zenth |
| `jungle` | Jungla Salvaje 🌿 | 🪙 1200 acumuladas | 🦍 Gran Gorila |
| `dark_city` | Ciudad Oscura 🕷️ | 🪙 2200 acumuladas | 🦹 Señor Sombra |
| `ocean` | Fondo del Mar 🐙 | 🪙 3500 acumuladas | 🐙 Kraken Abisal |
| `tundra` | Tundra ❄️ | 🪙 5500 acumuladas | ❄️ Yeti Glacial |
| `robot_city` | Ciudad Robot 🤖 | 🪙 8000 acumuladas | 🤖 Mega-Bot X9 |

`colorsFor(worldId)` cae en `brix_city` si el ID no existe.

### Desbloqueo de mundos

Un mundo bloqueado se abre cuando el jugador ha **ganado en total**
(`Wallet.totalCoinsEarned`) al menos su `unlockCost`. Como ese total **nunca
baja al gastar monedas**, el desbloqueo es **permanente** y no necesita
persistencia extra. La tarjeta del mundo muestra una barra de progreso
`ganadas / coste` y, al tocar uno aún bloqueado, un aviso con cuántas faltan.
El [modo de prueba](#modo-de-prueba-desarrollo) desbloquea todos.

---

## Modo de prueba (desarrollo)

Interruptor global en memoria definido en `lib/core/test_mode/test_mode.dart`
(`TestMode.instance`). Sirve para probar cualquier pantalla al instante.

**Cómo activarlo:** en la pantalla de inicio, **mantén pulsado el título
"RUN FOR WIN" durante 10 segundos seguidos** (deliberadamente largo y sin
ninguna pista visual: desbloquea contenido de pago, así que no debe encontrarse
por accidente). Se abre una hoja inferior con el interruptor y el detalle de lo
que desbloquea. Mientras está encendido aparece la banda "🧪 MODO PRUEBA
ACTIVO" en el inicio.

Con el modo de prueba encendido:

- 🎡 La ruleta diaria siempre se puede girar (`Wallet.canClaimRoulette`).
- 🧩 Todos los accesorios de pago quedan disponibles gratis (`_AccessorySlot`).
- 🗺️ Todos los mundos/pistas bloqueados quedan disponibles (`world_selection_page`).
- 🏁 La pista se acorta a `TestMode.shortTrackMeters` (20 m): el jefe aparece enseguida.
- 💪 El jefe baja a `TestMode.weakBossHearts` (1 corazón): una embestida y a la victoria.

Los cambios de pista y jefe se leen al construir la partida, así que aplican en
la siguiente carrera que inicies tras encender/apagar el modo.

**Seguridad en release:** como el modo de prueba desbloquea contenido de pago, en
la **build de release** que se publica queda **inerte** (no se puede activar):
`TestMode.isAvailable` es `false` salvo que se compile con
`--dart-define=BRIX_TESTMODE=true`. Sigue funcionando en debug/profile. Así, el
atajo del título no abre nada en la app publicada. Ver el README.
