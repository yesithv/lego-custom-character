# Música del juego — estado, flujo de producción y roadmap

> Documento de referencia para la música de fondo por mundo de **Run For Win**.
> Cubre lo hecho en el **MVP v1** (2 pistas por mundo, MP3) y deja guardados los
> **prompts para la v2** (volver a 4 pistas por mundo + API de validación de pagos).

## 1. Decisión firme del MVP v1

- **2 pistas por mundo** (16 en total). Una **enérgica** (`_1`) y una
  **contrastante/tranquila** (`_2`), elegibles por el jugador antes de correr.
- Formato **`.mp3`** (antes eran `.wav` sintetizados a mano; se migraron).
- Música generada con **Suno** (IA) y masterizada en **REAPER**.
- ⚠️ **Para el MVP se dejan solo 2 por mundo.** Las 4 por mundo son objetivo de
  la **v2** (ver §6).

## 2. Qué hicimos (migración a MP3)

- Reescrito el catálogo en
  `lib/features/runner/domain/entities/world_music.dart`: 2 `WorldTrack` por
  mundo, apuntando a `music/<mundo>_1.mp3` y `music/<mundo>_2.mp3`.
- Creados 16 MP3 **marcador de posición** en `assets/audio/music/` (para que el
  juego suene y los tests pasen hasta pegar los definitivos de Suno).
- Borrados los 26 `.wav` antiguos (dejaban de usarse y engordaban el APK, porque
  `pubspec.yaml` empaqueta toda la carpeta `assets/audio/music/`).
- Actualizado el test `test/world_music_test.dart`: valida **exactamente 2
  pistas** por mundo y extensión **`.mp3`**. Verde (13/13 con `music_track_test`).
- La reproducción es en bucle infinito (`AudioService.playMusic`,
  `ReleaseMode.loop`, volumen `0.55`), así que las pistas deben buclear sin corte.

### Nombres de fichero exactos (no cambiar)

El juego busca estos nombres; basta con sobrescribir el marcador de posición con
el MP3 de Suno usando el **mismo nombre**, sin tocar código:

```
brix_city_1.mp3   brix_city_2.mp3
medieval_1.mp3    medieval_2.mp3
galaxy_1.mp3      galaxy_2.mp3
jungle_1.mp3      jungle_2.mp3
dark_city_1.mp3   dark_city_2.mp3
ocean_1.mp3       ocean_2.mp3
tundra_1.mp3      tundra_2.mp3
robot_city_1.mp3  robot_city_2.mp3
```

## 3. Características recomendadas de las pistas

| Parámetro | Valor | Motivo |
|---|---|---|
| Formato | MP3, 128 kbps, CBR | Coherente con el resto del audio; APK ligero (Kids). |
| Sample rate | 44100 Hz | Estándar. |
| Canales | Estéreo (o Mono si el estéreo no aporta) | Mono pesa la mitad y casi no se nota en altavoz de móvil. |
| Duración | 60–90 s bucleados | Va en loop; no hace falta más y reduce peso. |
| Voces | **Instrumental, sin voces** | Público <13 (COPPA) y no distrae del juego. |
| Loudness | Normalizar todas a **−14 LUFS** | Que ningún mundo suene más fuerte que otro. |
| Estética | Chiptune / 8-bit / synth alegre | Coherencia sonora entre mundos. |

### El bucle (punto crítico)

Suno no entrega bucles perfectos. Flujo para que el loop no se note:

1. Genera en Suno y descarga (pide en el prompt: *seamless loop, no intro, no
   fade out, no ending*).
2. Recorta intro larga y **silencio/fade final**; corta a compás.
3. Aplica **crossfade de ~0,5–1 s** entre final e inicio (Audacity/REAPER).
4. Exporta a MP3 128 kbps y **normaliza** todas al mismo LUFS.
5. Guarda con el nombre exacto de §2.

> ⚠️ **MP3 no es gapless:** LAME mete ~50 ms de padding al inicio y `audioplayers`
> puede dejar oír un micro-hueco al reengancharse. En pistas enérgicas no se nota;
> si en una tranquila molesta, exporta **esa** pista en **OGG Vorbis** (gapless de
> verdad; `audioplayers` lo reproduce en Android) y cambia solo su extensión en
> `world_music.dart`.

## 4. Ajustes de exportación en REAPER (Render to File)

- **Source:** Master mix · **Bounds:** Entire project (proyecto = solo el loop).
- **Sample rate:** 44100 Hz · **Channels:** Stereo (o Mono).
- **Format:** MP3 (LAME) · **Mode:** CBR, `q=2 (recommended)` · **Bitrate:** 128 kbps.
- **Tail:** **desactivado** (una cola de reverb rompe el bucle).
- **Normalización:** activar a **−14 LUFS** para dejar todas las pistas parejas.
- **File name:** el nombre exacto de la pista (p. ej. `brix_city_1`), no un título
  libre. Con el mismo preset se sacan las demás cambiando solo el nombre.

## 5. Prompts del MVP v1 (2 por mundo — EN USO)

Cada bloque va listo para copiar y pegar en Suno.

### 🏙️ Brix City
**`brix_city_1.mp3` — Ritmo de Ciudad** (enérgica)
```
Upbeat chiptune city pop, playful and energetic, bright 8-bit arpeggios over a funky electro groove, cheerful whistle-synth melody, claps and snappy drums, sunny daytime urban vibe for a kids game. 120 BPM, major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady driving groove, clean punchy mobile-friendly mix.
```
**`brix_city_2.mp3` — Atardecer en la Avenida** (tranquila)
```
Chill lo-fi chiptune, mellow and warm, soft 8-bit keys and gentle boom-bap drums, relaxed sunset-in-the-city mood, cozy and friendly for a kids game. 90 BPM, major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady laid-back groove, clean warm mobile-friendly mix.
```

### 🏰 Medieval
**`medieval_1.mp3` — Marcha del Castillo** (enérgica)
```
Heroic medieval chiptune march, epic 8-bit fanfare with bright trumpet-synths and galloping snare rhythm, adventurous and brave, castle-and-tournament energy for a kids game. 110 BPM, major key, triumphant. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady marching groove, clean punchy mobile-friendly mix.
```
**`medieval_2.mp3` — Taberna del Reino** (juglar)
```
Jolly medieval tavern jig, playful 8-bit lute and fiddle-synth melody, bouncy hand-clap and tambourine rhythm, cheerful minstrel folk dance, cozy kingdom-inn mood for a kids game. 118 BPM, major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady dancing groove, clean punchy mobile-friendly mix.
```

### 🌌 Galaxy
**`galaxy_1.mp3` — Órbita Estelar** (cósmica)
```
Cosmic synthwave chiptune, spacey retro-futuristic arpeggios, shimmering neon pads and pulsing bass, floating starfield wonder with forward drive for a kids space runner. 120 BPM, uplifting minor-to-major. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady driving pulse, clean punchy mobile-friendly mix.
```
**`galaxy_2.mp3` — Salto Hiperespacial** (veloz)
```
Fast high-energy space chiptune, racing arpeggios and turbo-charged synth bass, warp-speed hyperspace rush, thrilling and futuristic for a kids space runner. 138 BPM, driving. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, relentless steady pulse, clean punchy mobile-friendly mix.
```

### 🌿 Jungle
**`jungle_1.mp3` — Corazón de la Selva** (tribal)
```
Tribal jungle chiptune adventure, energetic hand-drum and tom rhythms, bouncy 8-bit marimba melody, exotic bird-like synth leads, humid green vine-swinging energy for a kids game. 115 BPM, playful and rhythmic. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady percussive groove, clean punchy mobile-friendly mix.
```
**`jungle_2.mp3` — Templo Perdido** (aventura misteriosa)
```
Mysterious jungle-temple chiptune, adventurous 8-bit melody over soft tribal percussion, ancient-ruins wonder with a hint of intrigue, curious explorer mood for a kids game. 108 BPM, minor key playful. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady exploring groove, clean punchy mobile-friendly mix.
```

### 🕸️ Dark City
**`dark_city_1.mp3` — Carrera Embrujada** (persecución)
```
Spooky chase chiptune, fast bouncy minor-key 8-bit melody, driving ghost-run rhythm, playful haunted energy, exciting but not scary for a kids game. 124 BPM, minor key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady racing groove, clean punchy mobile-friendly mix.
```
**`dark_city_2.mp3` — Casa Encantada 8-bit** (Halloween travieso)
```
Playful Halloween chiptune, mischievous 8-bit melody with eerie organ-synth and ghostly bells, bouncy pumpkin-parade groove, cartoon-spooky and fun, not frightening, for a kids game. 112 BPM, minor key playful. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady bouncing groove, clean punchy mobile-friendly mix.
```

### 🌊 Ocean
**`ocean_1.mp3` — Arrecife de Neón** (luminosa)
```
Luminous underwater synth chiptune, bright bubbly 8-bit plucks and glowing neon pads, upbeat aquatic reef energy, colorful and lively for a kids game. 112 BPM, major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady flowing groove, clean punchy mobile-friendly mix.
```
**`ocean_2.mp3` — Corrientes Profundas** (flotante)
```
Dreamy underwater lo-fi chiptune, floating soft pads with gentle bubbly plucks, calm slow-current mood, soothing deep-sea drift for a kids game. 96 BPM, mellow major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady gentle groove, clean warm mobile-friendly mix.
```

### ❄️ Tundra
**`tundra_1.mp3` — Ventisca Veloz** (carrera)
```
Brisk icy chiptune, sparkling glassy synths over a fast skating rhythm, energetic snow-race rush, frosty and thrilling for a kids game. 122 BPM, bright major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady gliding groove, clean punchy mobile-friendly mix.
```
**`tundra_2.mp3` — Viento Polar** (cristalina calma)
```
Crystalline calm chiptune, delicate glockenspiel-synth bells and cool shimmering pads, serene frozen-tundra wonder, peaceful and pretty for a kids game. 92 BPM, bright major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady gentle groove, clean airy mobile-friendly mix.
```

### 🤖 Robot City
**`robot_city_1.mp3` — Circuito Sintético** (synthwave metálico)
```
Metallic synthwave chiptune, driving electro beat with glitchy robotic bleeps and neon-green factory energy, cool futuristic groove for a kids game. 126 BPM, driving. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady mechanical groove, clean punchy mobile-friendly mix.
```
**`robot_city_2.mp3` — Sobrecarga** (techno-pop al máximo)
```
High-octane techno-pop chiptune, fast four-on-the-floor beat, aggressive-but-fun synth stabs and turbo robot bleeps, maximum-overdrive factory energy for a kids game. 140 BPM, relentless. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady pounding groove, clean punchy mobile-friendly mix.
```

## 6. Roadmap v2 (NO tocar en el MVP)

Objetivos de la próxima versión, una vez publicado el MVP:

1. **Volver a 4 pistas por mundo** (16 pistas nuevas, `_3` y `_4`). Habrá que:
   - Añadir los `WorldTrack` en `world_music.dart`.
   - Cambiar el test `world_music_test.dart` de `expect(length, 2)` a `3`/`4`.
   - Añadir los MP3 `music/<mundo>_3.mp3` y `music/<mundo>_4.mp3`.
2. **Integrar una API de validación de pagos** (hoy el MVP es autónomo, sin
   backend; los pagos los cobra Google Play). Diseño archivado en
   `docs/BACKEND-PAGOS.md`.

### Prompts guardados para la v2 (2 nuevos por mundo → completar 4)

Listos para generar cuando llegue la v2. Estilos elegidos para **contrastar** con
las dos pistas que ya existen en cada mundo.

#### 🏙️ Brix City
**`brix_city_3.mp3` — Hora Punta** (acelerada)
```
Fast energetic chiptune funk, busy 8-bit synth stabs and rush-hour drive, honking-horn synth accents, exciting downtown traffic energy for a kids game. 128 BPM, major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady driving groove, clean punchy mobile-friendly mix.
```
**`brix_city_4.mp3` — Arcade del Centro** (arcade alegre)
```
Cheerful classic arcade chiptune, catchy square-wave melody and coin-bleep accents, bright playful 8-bit game-hall energy for a kids game. 132 BPM, major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady bouncy groove, clean punchy mobile-friendly mix.
```

#### 🏰 Medieval
**`medieval_3.mp3` — Justa del Torneo** (galope)
```
Fast galloping medieval chiptune, driving horse-race snare and heroic 8-bit brass, jousting-tournament excitement, brave and thrilling for a kids game. 128 BPM, major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady galloping groove, clean punchy mobile-friendly mix.
```
**`medieval_4.mp3` — Bosque Encantado** (mística calma)
```
Mystical medieval chiptune, gentle harp-synth and soft flute-lead, enchanted-forest wonder, calm and magical for a kids game. 90 BPM, major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady gentle groove, clean airy mobile-friendly mix.
```

#### 🌌 Galaxy
**`galaxy_3.mp3` — Consola de la Estación** (arcade espacial)
```
Retro space-arcade chiptune, quirky 8-bit bleeps and blips over a bouncy groove, spaceship-console playful energy for a kids game. 124 BPM, major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady bouncy groove, clean punchy mobile-friendly mix.
```
**`galaxy_4.mp3` — Nebulosa Serena** (ambiental calma)
```
Serene ambient space chiptune, slow shimmering pads and distant twinkling arpeggios, floating peaceful nebula drift for a kids game. 88 BPM, dreamy major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady gentle drift, clean airy mobile-friendly mix.
```

#### 🌿 Jungle
**`jungle_3.mp3` — Río de Bloques** (lo-fi húmedo)
```
Humid jungle lo-fi chiptune, laid-back groove with soft marimba and gentle water-drop synths, cool riverside shade mood for a kids game. 92 BPM, mellow major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady laid-back groove, clean warm mobile-friendly mix.
```
**`jungle_4.mp3` — Estampida** (frenética)
```
Wild fast jungle chiptune, pounding tribal drums and frantic 8-bit melody, stampede-through-the-vines excitement for a kids game. 130 BPM, playful and driving. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady pounding groove, clean punchy mobile-friendly mix.
```

#### 🕸️ Dark City
**`dark_city_3.mp3` — Niebla del Cementerio** (ambiental oscura)
```
Moody dark chiptune, slow eerie 8-bit melody and foggy synth pads, mysterious graveyard atmosphere, spooky but gentle for a kids game. 96 BPM, minor key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady slow groove, clean mobile-friendly mix.
```
**`dark_city_4.mp3` — Baile de Esqueletos** (danse macabre)
```
Playful danse-macabre chiptune, bouncy xylophone-bone melody and marching skeleton rhythm, mischievous cartoon-spooky dance, fun not scary for a kids game. 116 BPM, minor key playful. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady bouncing groove, clean punchy mobile-friendly mix.
```

#### 🌊 Ocean
**`ocean_3.mp3` — Fiesta del Coral** (burbujeante alegre)
```
Bubbly upbeat underwater chiptune, playful 8-bit steel-drum synths and popping bubble accents, lively coral-party energy for a kids game. 120 BPM, major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady bouncy groove, clean punchy mobile-friendly mix.
```
**`ocean_4.mp3` — Abismo Silencioso** (profunda calma)
```
Deep calm underwater ambient chiptune, slow low pads and sparse twinkling plucks, quiet mysterious abyss drift, soothing for a kids game. 84 BPM, mellow minor-to-major. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady gentle drift, clean warm mobile-friendly mix.
```

#### ❄️ Tundra
**`tundra_3.mp3` — Refugio Nevado** (lo-fi cálido)
```
Cozy winter lo-fi chiptune, warm soft keys and gentle bell accents, snug snow-cabin fireside mood, calm and friendly for a kids game. 88 BPM, warm major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady laid-back groove, clean warm mobile-friendly mix.
```
**`tundra_4.mp3` — Trineo Turbo** (carrera de trineo)
```
Fast fun sled-race chiptune, zippy 8-bit melody and jingle-bell percussion, downhill snow-speed excitement for a kids game. 128 BPM, bright major key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady driving groove, clean punchy mobile-friendly mix.
```

#### 🤖 Robot City
**`robot_city_3.mp3` — Núcleo de Datos** (engranajes chiptune)
```
Precise mechanical chiptune, ticking gear rhythms and blippy data-stream arpeggios, busy robotic factory-core energy for a kids game. 128 BPM, driving. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady mechanical groove, clean punchy mobile-friendly mix.
```
**`robot_city_4.mp3` — Modo Sigilo** (synth oscuro)
```
Cool sneaky robot chiptune, low pulsing synth bass and quiet glitchy bleeps, stealth-mission tension, mysterious but fun for a kids game. 104 BPM, minor key. [Instrumental] no vocals. Seamless loop, no intro, no fade out, no ending, steady low groove, clean mobile-friendly mix.
```
