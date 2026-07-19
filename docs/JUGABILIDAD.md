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

---

## El editor de personajes

Un personaje (`Character`) tiene: `id`, `name`, `type`, `specialPower` opcional, `appearance`, marcas de tiempo y estadísticas (`totalCoinsEarned`, `bestRunScore`). (El campo heredado `musicTrack` se conserva solo por compatibilidad con datos guardados; la música ya no se elige por personaje — ver [Música de partida](#música-de-partida)).

La apariencia (`CharacterAppearance`) se compone por capas:

- **Cara:** tono de piel (`SkinTone` — 3 realistas + 6 fantásticos), ojos (`EyeStyle`, 10 estilos), boca (7), cejas (5), extra facial (freckles, blush, scar, tatuaje, pintura de guerra, monóculo…).
- **Cabeza:** `headwearType` = pelo / casco / sombrero. Cada uno con sus variantes (`HairStyle` 11 peinados, `HelmetStyle` 13 cascos —incluidos capuchas de superhéroe como Iron Man, Spider-Man, Black Panther…—, `HatStyle` 8 sombreros).
- **Torso:** 22 diseños (`TorsoDesign`: policía, bombero, astronauta, ninja, pirata, superhéroe, samurái, robot, alien, táctico, comando, dorado…), con opción de capa (`hasCape`).
- **Manos:** guantes (`GloveType`: boxeo, medieval, superhéroe, garras).
- **Piernas y pies:** diseño (`LegDesign`, 11 opciones), tipo (`LegType`: pantalón, shorts, falda, armadura, traje espacial) y calzado (`ShoeType`: 8 tipos).
- **Accesorios:** 8 ranuras (`rightHand`, `leftHand`, `back`, `shoulders`, `waist`, `neck`, `face`, `feet`).

El personaje se dibuja por código (formas y colores), no con sprites, y se guarda en Hive (caja `characters`).

> **Estabilidad de enums:** Hive persiste los enums por **índice**, así que los valores nuevos se **añaden siempre al final** de cada enum (ver comentarios en `character.dart`). Nunca reordenes ni intercales valores: romperías los personajes ya guardados.

## Personajes precargados (presets)

`preset_characters.dart` define una lista de `PresetCharacter`: personajes listos (nombre + apariencia + tipo) agrupados por **colección** (p. ej. *Ninjas dorados*, *Superhéroes*). Desde la galería de presets (`/presets`) el usuario elige uno y se carga en el editor como un personaje **nuevo y editable** (se pasa como `state.extra` a `/editor`), de modo que puede ajustar boca, pelo, accesorios, etc., antes de guardarlo.

## Música de partida

La música es **temática de cada mundo** y se elige justo antes de correr, no por personaje. En la pantalla previa (`PreRunPage`, tras seleccionar un mundo) el jugador:

1. Decide con un interruptor si quiere música de fondo (activada por defecto).
2. Si la activa, elige una de las **3–4 pistas ambientadas en ese mundo** (p. ej. en el Reino Medieval: *Marcha del Castillo*, *Justa del Torneo*, *Taberna del Reino*, *Bosque Encantado*). Puede escuchar cada una con ▶ antes de decidir.

El repertorio por mundo está en `runner/domain/entities/world_music.dart` (`worldMusicCatalog`, `worldTracksFor(worldId)`). Cada pista tiene su **propio fichero** en `assets/audio/music/<mundo>_<n>.wav`, sintetizado a medida con un estilo chiptune acorde al mundo: el mundo aporta la escala/tonalidad y la progresión, y cada pista un estilo (tempo, timbre, percusión). Los WAV se generan de forma determinista con `tool/gen_music.py` (Python puro, sin dependencias).

La pista elegida (o `null` si la música está desactivada) se pasa al `RunnerPage` como `musicAsset`. El runner la reproduce con `AudioService.playMusic(asset)` en `ReleaseMode.loop` y volumen `0.55`; si es `null`, corre en silencio. `toggleMute()` la silencia en caliente sin cortar la pista. Los fallos de reproducción (p. ej. autoplay bloqueado en web) se ignoran silenciosamente.

---

## El endless runner

### Perspectiva pseudo-3D

El runner simula 3D con matemática de perspectiva (estilo Subway Surfers). Los objetos aparecen en el horizonte (`depth 0`) y se acercan a la cámara (`depth 1` = nivel del jugador).

| Concepto | Valor / fórmula |
|----------|-----------------|
| Línea de horizonte | `horizonY = size.y * 0.37` |
| Nivel del jugador | `playerBaseY = size.y * 0.81` |
| Punto de fuga (X) | `vanishX = size.x / 2` |
| Separación de carriles | `laneSep = size.x * 0.265` |
| Escala por profundidad | `0.07 + 0.93 * depth` (diminuto en el horizonte, tamaño real junto al jugador) |
| Avance de profundidad | `depthRate = 0.42 * (speed / 220)` unidades/seg |

Hay **3 carriles**. `perspectivePos(lane, depth)` interpola entre el punto de fuga y la posición del carril al nivel del jugador.

### Controles

| Gesto | Acción |
|-------|--------|
| Swipe arriba / tap | Saltar |
| Swipe abajo | Deslizarse (pasar por debajo de barreras) |
| Swipe izquierda / derecha | Cambiar de carril |

### Zonas de dificultad

La dificultad aumenta según los metros recorridos (`meters`):

| Zona | Rango | Bonus de velocidad | Extra |
|------|-------|--------------------|-------|
| `inicio` | 0–499 m | +0 | — |
| `nucleo` | 500–1499 m | +60 | — |
| `caos` | ≥ 1500 m | +160 | 20% de probabilidad de un segundo obstáculo en otro carril |

### Velocidad y spawning

- **Velocidad inicial:** `220 px/s`. Sube `+12` cada `5 s`, con tope en `900`.
- **Velocidad efectiva** = `speed + bonus de zona`.
- **Obstáculos:** intervalo de spawn = `(2.2 - velEfectiva/900)` acotado a `[0.65, 2.2]` s. Tipos por probabilidad: barrera 20%, pincho 15%, bloque 65%.
- **Monedas:** una cada `0.9 s`, en carril aleatorio.
- **Power-ups:** uno cada `12 s`, tipo shield o magnet (50/50).
- **Escenografía lateral:** `SceneryComponent` a los lados de la pista cada `0.55 s` (variantes temáticas por mundo). Se siembra al inicio para que el mundo no arranque vacío.

> Obstáculos, monedas y power-ups **solo** aparecen en la fase `running`. Al empezar la pelea contra el jefe (`bossFight`) dejan de generarse, pero la escenografía sigue avanzando para que el mundo no se congele.

### Colisiones

Detección manual por proximidad de profundidad (`_checkDepthCollisions`), no por hitboxes:

- Ventana de impacto: `depth ∈ [0.87, 1.11]` **y** mismo carril que el jugador.
- Un obstáculo se marca como **evadido** al superar `depth ≥ 1.16` sin colisión.
- **Salto:** con `jumpProgress ∈ (0.14, 0.88)` se libran **todos** los obstáculos.
- **Deslizamiento:** solo libra las **barreras** (`ObstacleType.barrier`).
- **Monedas:** se recogen en la ventana de impacto si coinciden de carril; con **imán** activo también valen los carriles adyacentes (`|lane - playerLane| == 1`).

### Puntuación

```
score = (meters + coins*5 + obstacleStreak*2) * multiplier + bossBonusScore
```

- `meters = distanciaRecorrida / 100`.
- `bossBonusScore` acumula los bonus de la pelea: `+300` por cada embestida al jefe y `+1000` al vencerlo (ver [Peleas contra jefes](#peleas-contra-jefes)).
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
| 🛡️ Shield | 5 s | Absorbe un golpe sin morir. |
| 🧲 Magnet | 5 s | Atrae monedas de los carriles adyacentes. |

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

Al alcanzar `bossTriggerMeters` (por defecto **2000 m**; parametrizable para tests) la partida entra en una máquina de fases (`GamePhase`):

```
running → bossIntro → bossFight → bossDefeated → victory
```

- **`bossIntro`:** aparece el `BossComponent` con la animación de entrada y un cartel con el nombre/emoji del jefe.
- **`bossFight`:** el jefe lanza ataques a intervalos; el jugador los esquiva y carga la embestida.
- **`bossDefeated`:** tras agotar sus corazones, 1.5 s de animación de derrota.
- **`victory`:** overlay de victoria y, 400 ms después, fin de carrera.

### Corazones, ataques y embestida

- El jefe tiene **3 corazones** (`maxBossHearts`).
- **Cada ataque esquivado** carga la embestida `+0.2` (`dashCharge`). Al llegar a `1.0` el jugador **embiste** automáticamente: quita **1 corazón**, suma **+300** al score y limpia los ataques en vuelo.
- El jefe se **enfurece** al perder corazones: el intervalo entre ataques baja de `1.15 s → 0.90 s → 0.70 s`. Enfurecido, a veces lanza un segundo proyectil en otro carril (35% en ataques de proyectil).

### Tipos de ataque (cada uno se contrarresta con un control)

| Ataque | Cómo se esquiva |
|--------|-----------------|
| `projectile` | Viaja por un carril → **cambiar de carril** (o saltar). |
| `shockwave` | Onda baja a todo lo ancho → **saltar**. |
| `sweep` | Barrido alto a todo lo ancho → **deslizarse**. |

Ser golpeado por un ataque del jefe equivale a un golpe normal: con escudo se consume el escudo; sin escudo, fin de partida.

### Recompensas por victoria

Al vencer al jefe: **+150 monedas** (`victoryCoinBonus`) y **+1000** al score (`bossBonusScore`), luego `onRunComplete(coins)`.

### Jefes por mundo

`boss_config.dart` define un jefe por mundo, cada uno con nombre, emoji, colores y **pesos de ataque** propios (su "personalidad"):

| Mundo | Jefe |
|-------|------|
| `lego_city` | 🏗️ Capataz Demoledor |
| `medieval` | 🐉 Dragón Oscuro |
| `galaxy` | 👾 Overlord Zenth |
| `jungle` | 🦍 Gran Gorila |
| `dark_city` | 🦹 Señor Sombra |
| `ocean` | 🐙 Kraken Abisal |
| `tundra` | ❄️ Yeti Glacial |
| `robot_city` | 🤖 Mega-Bot X9 |

`bossFor(worldId)` cae en el jefe de `lego_city` si el ID no existe.

---

## Economía

El monedero (`Wallet`) guarda: `coins`, `unlockedParts`, `runStreak`, `lastRouletteDate`, `lastPlayDate`, `totalCoinsEarned`.

### Ruleta diaria

Reclamable una vez por día natural (`canClaimRoulette` compara año/mes/día con `lastRouletteDate`). Premio por tabla ponderada (peso total = 100):

| Premio | Peso |
|--------|------|
| 50 monedas | 30 |
| 100 monedas | 25 |
| 200 monedas | 15 |
| 500 monedas | 10 |
| Pieza: Capa (común) | 10 |
| Pieza: Escudo (común) | 5 |
| Pieza: Jetpack (rara) | 4 |
| Pieza: Medallón dorado (épica) | 1 |

### Cofres

Dos tablas de premios ponderadas:

**Cofre común**

| Premio | Peso |
|--------|------|
| 30 monedas | 50 |
| 75 monedas | 25 |
| Sombrero (común) | 15 |
| Alas (raras) | 8 |
| Corona épica | 2 |

**Cofre VIP** (se obtiene con racha ≥ 3, ver abajo)

| Premio | Peso |
|--------|------|
| 150 monedas | 30 |
| Jetpack (raro) | 25 |
| Varita mágica (rara) | 25 |
| Capa dorada (épica) | 15 |
| Espada legendaria (legendaria) | 5 |

Las piezas repetidas no se duplican: si ya está en `unlockedParts`, no se vuelve a añadir.

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

Emojis de rareza (en recompensas): común ⚙️, rara 💎, épica ⚡, legendaria 👑.

---

## Misiones

Siempre hay **3 misiones activas** (caja `missions`, guardadas como JSON). Se generan a partir de 13 plantillas, eligiendo 3 de **tipos distintos** al azar.

Tipos de misión (`MissionType`) y ejemplos de objetivo:

| Tipo | Ejemplos (objetivo → recompensa) |
|------|----------------------------------|
| `collectCoins` | 10 → 50, 25 → 100, 50 → 200 monedas |
| `runMeters` | 200 → 50, 500 → 100, 1000 → 200 |
| `evadeObstacles` | 5 → 50, 10 → 100, 20 → 200 (seguidos) |
| `surviveSeconds` | 30 → 75, 60 → 150 |
| `useJump` | 5 → 50, 15 → 100 |

Al terminar una carrera, `advanceMissions(MissionRunData)` suma el progreso correspondiente a cada misión (monedas, metros, obstáculos evadidos, segundos, saltos). Cuando **todas** las misiones activas se completan, se regeneran automáticamente 3 nuevas.

---

## Ranking

Puntuaciones locales por mundo (caja `scores`, `ScoreModel`). Al terminar una carrera se registra la puntuación bajo el `worldId` correspondiente. La pantalla `/ranking/:worldId` muestra la tabla de ese mundo.

> El repositorio de ranking está detrás de la interfaz `ScoreRepository`. Para pasar a un ranking online (p. ej. Firebase) basta con sustituir `ScoreLocalRepository` por otra implementación en `injection.dart`.

---

## Mundos

8 mundos temáticos definidos en `world_config.dart` (paletas de color, incluidos colores de obstáculo por mundo) y `world_selection_page.dart` (metadatos y estado). Cada mundo tiene colores de cielo, midground, suelo y acento propios, y su propio [jefe](#jefes-por-mundo).

| ID | Nombre | Estado | Jefe |
|----|--------|--------|------|
| `lego_city` | Ciudad Brix 🏙️ | Disponible | 🏗️ Capataz Demoledor |
| `medieval` | Reino Medieval 🏰 | Disponible | 🐉 Dragón Oscuro |
| `galaxy` | Galaxia Brix 🚀 | Bloqueado | 👾 Overlord Zenth |
| `jungle` | Jungla Salvaje 🌿 | Bloqueado | 🦍 Gran Gorila |
| `dark_city` | Ciudad Oscura 🕷️ | Bloqueado | 🦹 Señor Sombra |
| `ocean` | Fondo del Mar 🐙 | Bloqueado | 🐙 Kraken Abisal |
| `tundra` | Tundra ❄️ | Bloqueado | ❄️ Yeti Glacial |
| `robot_city` | Ciudad Robot 🤖 | Bloqueado | 🤖 Mega-Bot X9 |

`colorsFor(worldId)` cae en `lego_city` si el ID no existe.

---

## Modo de prueba (desarrollo)

Interruptor global en memoria definido en `lib/core/test_mode/test_mode.dart`
(`TestMode.instance`). Sirve para probar cualquier pantalla al instante.

**Cómo activarlo:** en la pantalla de inicio, **mantén pulsado el título
"RUN FOR WIN"**. Se abre una hoja inferior con el interruptor y el detalle de
lo que desbloquea. Mientras está encendido aparece la banda "🧪 MODO PRUEBA
ACTIVO" en el inicio.

Con el modo de prueba encendido:

- 🎡 La ruleta diaria siempre se puede girar (`Wallet.canClaimRoulette`).
- 🧩 Todos los accesorios de pago quedan disponibles gratis (`_AccessorySlot`).
- 🗺️ Todos los mundos/pistas bloqueados quedan disponibles (`world_selection_page`).
- 🏁 La pista se acorta a `TestMode.shortTrackMeters` (20 m): el jefe aparece enseguida.
- 💪 El jefe baja a `TestMode.weakBossHearts` (1 corazón): una embestida y a la victoria.

Los cambios de pista y jefe se leen al construir la partida, así que aplican en
la siguiente carrera que inicies tras encender/apagar el modo.
