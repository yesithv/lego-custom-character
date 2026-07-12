# Guía de desarrollo

Cómo trabajar en Run For Win (codename BrixRun): convenciones, cómo añadir features, el patrón de adapters Hive a mano y pruebas.

## Índice

- [Entorno](#entorno)
- [Comandos habituales](#comandos-habituales)
- [Convenciones de código](#convenciones-de-código)
- [Añadir una feature nueva](#añadir-una-feature-nueva)
- [Adapters de Hive a mano](#adapters-de-hive-a-mano)
- [Añadir un componente al runner](#añadir-un-componente-al-runner)
- [Audio](#audio)
- [Pruebas](#pruebas)
- [Flujo Git y despliegue](#flujo-git-y-despliegue)

---

## Entorno

- Flutter SDK (`environment.sdk: '>=3.0.0 <4.0.0'`; recomendado 3.44+ / Dart 3.12+).
- `flutter pub get` para instalar dependencias.
- Para web: Chrome. Los assets bajo `assets/sprites/**` pueden estar vacíos (los personajes y mundos se dibujan por código).

---

## Comandos habituales

```bash
flutter pub get                 # dependencias
flutter run                     # desarrollo (elige dispositivo)
flutter run -d chrome           # desarrollo web
flutter analyze                 # lints (flutter_lints)
flutter test                    # pruebas
flutter build web --release --base-href "/lego-custom-character/"
```

---

## Convenciones de código

- **Clean Architecture por feature.** Respeta la dirección de dependencias: `presentation → domain ← data`. `domain` nunca importa Flutter, Hive ni otra capa.
- **Entidades inmutables.** Extienden `Equatable`, exponen `copyWith` y declaran `props`. No pongas lógica de persistencia en las entidades.
- **Modelos vs. entidades.** Los `*Model` (capa `data`) convierten a/desde entidad con `toEntity()` / `fromEntity()`. La UI y el dominio solo conocen entidades.
- **Un usecase = una responsabilidad**, invocable con `call()`. El BLoC recibe usecases por constructor.
- **BLoC** con el trío `Event` / `State` / `Bloc`. Estados y eventos con `Equatable`.
- **Inyección** vía `get_it` (`sl`). Registra en `initDependencies()`: `registerLazySingleton` para datasources/repos/usecases, `registerFactory` para BLoCs.
- **Idioma:** nombres de dominio orientados al usuario en español (coinciden con la UI); código y tipos en inglés/estilo Dart.
- **Lints:** se usa `flutter_lints`. Ejecuta `flutter analyze` antes de subir.

---

## Añadir una feature nueva

1. Crea `lib/features/<feature>/` con las carpetas `domain/`, `data/`, `presentation/`.
2. **Domain:** define la entidad (`Equatable` + `copyWith`), el contrato `abstract class <X>Repository` y los usecases.
3. **Data:** crea el `<X>Model` (con `toEntity`/`fromEntity`), el adapter Hive a mano si se persiste, el datasource (envuelve la `Box`) y el `<X>RepositoryImpl`.
4. **Presentation:** BLoC (`Event`/`State`/`Bloc`), páginas y widgets.
5. **Cablea** en `lib/core/di/injection.dart`: registra el adapter, abre la caja, registra datasource → repo → usecases → BLoC.
6. **Ruta**: añade el `GoRoute` en `lib/core/router/app_router.dart`. Si la ruta necesita datos efímeros (`state.extra`), añade su path a la lista de `redirect` para no romper al refrescar.
7. Si el BLoC debe vivir a nivel global, añádelo al `MultiBlocProvider` en `main.dart`; si es local a una pantalla, provéelo ahí.

---

## Adapters de Hive a mano

> **Regla del proyecto:** NO se usan `hive_generator` ni `build_runner`. Los archivos `*_model.g.dart` se escriben **a mano**. Al tocar campos persistidos, actualiza el adapter manualmente.

Patrón (ejemplo real, `score_model.dart` / `score_model.g.dart`):

**El modelo** declara `@HiveType(typeId: N)`, campos `@HiveField(i)` y las conversiones:

```dart
part 'score_model.g.dart';

@HiveType(typeId: 3)
class ScoreModel extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String characterName;
  // ...
  Score toEntity() => Score(id: id, /* ... */);
  static ScoreModel fromEntity(Score s) => ScoreModel()..id = s.id /* ... */;
}
```

**El adapter** (`.g.dart`) implementa `read`/`write` respetando el orden y el número de campos:

```dart
part of 'score_model.dart';

class ScoreModelAdapter extends TypeAdapter<ScoreModel> {
  @override
  final int typeId = 3;

  @override
  ScoreModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScoreModel()..id = fields[0] as String /* ... */;
  }

  @override
  void write(BinaryWriter writer, ScoreModel obj) {
    writer
      ..writeByte(7)          // número total de campos
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.characterName);
      // ... un writeByte(i) + write(valor) por campo
  }

  @override
  int get hashCode => typeId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreModelAdapter && typeId == other.typeId;
}
```

### Checklist al añadir/quitar un campo persistido

1. Añade el campo con un `@HiveField(i)` **nuevo y único** (no reutilices índices).
2. En `write`: incrementa el contador de `writeByte(N)` y añade el par `writeByte(i) + write(valor)`.
3. En `read`: añade la asignación `..campo = fields[i] as Tipo`.
4. Actualiza `toEntity`/`fromEntity`.
5. Para tipos nunca borres ni cambies el significado de un `typeId` o `@HiveField` existente (rompe los datos guardados).

### typeIds registrados

Registrados en `initDependencies()`. Cada `typeId` debe ser único en toda la app:

| Adapter | typeId | Caja |
|---------|--------|------|
| `CharacterModelAdapter` | 0 | `characters` |
| `CharacterAppearanceModelAdapter` | 1 | (anidado en `CharacterModel`) |
| `WalletModelAdapter` | 2 | `wallet` |
| `ScoreModelAdapter` | 3 | `scores` |

> `CharacterModel` persiste, entre otros campos, `musicTrack` (índice del enum `MusicTrack`). Al añadir campos así, actualiza el adapter a mano siguiendo el checklist de arriba.

> Las misiones **no** usan adapter: se serializan como JSON (`String`) en la caja `missions` (clave `active`).

> Verifica los `typeId` reales en cada `*_model.dart` antes de asignar uno nuevo; usa el siguiente entero libre.

### Estabilidad de enums persistidos

Hive guarda los enums por **índice**. Varios enums de dominio se persisten (`MusicTrack`, `SkinTone`, `EyeStyle`, `HelmetStyle`, `TorsoDesign`, etc.). Por eso:

- **Añade valores nuevos siempre al final** del enum (así lo indican los comentarios en `character.dart`).
- **Nunca** reordenes ni intercales valores existentes: cambiaría el significado de los datos ya guardados y corromper­ía los personajes de los usuarios.

---

## Añadir un componente al runner

Los componentes viven en `lib/features/runner/presentation/game/components/` y son `Component`/`PositionComponent` de Flame dibujados por código.

Para un objeto que aparece en el horizonte y avanza hacia el jugador:

1. Da al componente un `lane` (0–2) y un `depth` (0→1).
2. En su `update(dt)`, incrementa `depth` según `game.depthRate`.
3. Posiciónalo con `game.perspectivePos(lane, depth)` y escálalo con `game.perspectiveScale(depth)`.
4. Spawnéalo desde `BrixRunGame` (`add(MiComponente(...))`) con su propio temporizador en `update`.
5. Si debe colisionar, añádelo a `_checkDepthCollisions()` (comparación por `depth` y `lane`), no uses hitboxes de Flame.

El HUD y la pantalla de fin de partida son **overlays** de Flame (`hud`, `gameOver`); el HUD escucha al juego vía `ChangeNotifier`.

---

## Audio

`AudioService.instance` (singleton) reproduce efectos con un `AudioPlayer` por sonido (evita cortar efectos solapados). Métodos de efecto: `playJump`, `playCoin`, `playHit`, `playPowerup`, `playUnlock`, `playRouletteSpin`, `playChestOpen`. Para un sonido nuevo, añade el MP3 en `assets/audio/` (declarado en `pubspec.yaml`) y un método `playX()`.

La **música de fondo** usa un reproductor propio en bucle: `playMusic(asset)` / `stopMusic()`, con volumen `0.55`. `toggleMute()` silencia efectos y música (esta última en caliente, sin cortar la pista). Los MP3 de música van en `assets/audio/music/`.

## Añadir contenido de juego

- **Mundo:** añade su entrada en `world_config.dart` (`WorldColors`, incluidos colores de obstáculo), su `BossConfig` en `boss_config.dart`, y sus metadatos/estado en `world_selection_page.dart` (`WorldData`).
- **Jefe:** cada mundo mapea a un `BossConfig` (nombre, emoji, colores y pesos de ataque). El comportamiento vive en `BossComponent`/`BossAttackComponent`; los tres tipos de ataque (`projectile`, `shockwave`, `sweep`) ya están cableados a los controles.
- **Pista de música (por mundo):** la música es temática de cada mundo y se elige en la pantalla previa a correr. Añade/edita las 3–4 pistas del mundo en `worldMusicCatalog` (`runner/domain/entities/world_music.dart`) y, si hace falta un MP3 nuevo, ponlo en `assets/audio/music/`.
- **Preset:** añade un `PresetCharacter` a la lista de `preset_characters.dart` con su `collection`; aparecerá automáticamente en `/presets`.
- **Accesorio / pieza:** añade un `CatalogEntry` a `part_catalog.dart` en la ranura y rareza correctas (el coste se deriva de la rareza).

---

## Pruebas

- Framework: `flutter_test`, más `bloc_test` y `mocktail` para BLoCs y mocks.
- Las pruebas viven en `test/`. Actualmente:
  - `widget_test.dart` — smoke test de la app.
  - `boss_fight_test.dart` — máquina de fases y lógica de la pelea contra el jefe (usa `bossTriggerMeters` para forzar el trigger).
  - `boss_render_test.dart` — renderizado de jefes y sus pintores.
  - `character_preview_render_test.dart` — que todas las opciones de apariencia se dibujan.
  - `music_track_test.dart` — pista heredada `MusicTrack` (persistencia/compatibilidad).
  - `world_music_test.dart` — catálogo de música temática por mundo.
  - `preset_characters_test.dart` — personajes precargados.
- Ejecuta `flutter test`.
- Al probar BLoCs, mockea los usecases/repositorios con `mocktail` y usa `blocTest` para verificar la secuencia de estados emitida.
- Para probar el juego, `BrixRunGame` acepta `bossTriggerMeters` por constructor para provocar la pelea sin correr 2000 m reales.

---

## Flujo Git y despliegue

- **Nunca** push directo a `main`. Desarrolla en rama feature, sube y abre PR (base `main`). El merge lo hace el usuario.
- El CI (`.github/workflows/deploy-web.yml`) hace **build** en `main`, ramas feature listadas y PRs; **deploy** solo en push a `main` (→ `gh-pages` vía `peaceiris/actions-gh-pages`).
- Si añades una rama feature de larga duración que quieras validar en CI, agrégala a la lista `on.push.branches` del workflow.
- Detalles de configuración de GitHub Pages en el [README](../README.md#despliegue) y en [`CLAUDE.md`](../CLAUDE.md).
