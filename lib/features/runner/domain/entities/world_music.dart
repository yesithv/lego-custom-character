/// Catálogo de música ambientada por mundo.
///
/// A partir de esta versión la música ya no es una elección personal del
/// personaje: cada mundo ofrece su propio repertorio temático y el jugador
/// decide, justo antes de correr, si quiere música y cuál de las pistas del
/// mundo suena de fondo.
///
/// Cada pista tiene su propio fichero de audio `.mp3` en `assets/audio/music/`,
/// con un estilo acorde al mundo. Cada mundo ofrece **dos** pistas contrastadas
/// (una enérgica y otra más tranquila) para que el jugador elija antes de correr.
/// Los ficheros se reproducen en bucle (ver `AudioService.playMusic`), así que
/// conviene que estén recortados para buclear sin corte perceptible.
class WorldTrack {
  /// Nombre en español (fuente de datos / respaldo). El nombre mostrado se
  /// traduce por [id] con las claves `music_<id>_name` (ver AppLocalizations).
  final String name;

  /// Descripción en español (respaldo). Se traduce por [id] con la clave
  /// `music_<id>_desc`.
  final String description;
  final String emoji;

  /// Ruta del asset relativa a `assets/audio/`.
  final String asset;

  const WorldTrack({
    required this.name,
    required this.description,
    required this.emoji,
    required this.asset,
  });

  /// Identificador estable de la pista, derivado del nombre del fichero de
  /// audio (p. ej. `music/brix_city_1.mp3` → `brix_city_1`). Se usa como sufijo
  /// de las claves de traducción `music_<id>_name` / `music_<id>_desc`.
  String get id =>
      asset.replaceFirst('music/', '').replaceFirst('.mp3', '');
}

/// Repertorio temático por identificador de mundo.
const worldMusicCatalog = <String, List<WorldTrack>>{
  'brix_city': [
    WorldTrack(
      name: 'Ritmo de Ciudad',
      description: 'Groove urbano alegre de calles de bloques',
      emoji: '🏙️',
      asset: 'music/brix_city_1.mp3',
    ),
    WorldTrack(
      name: 'Atardecer en la Avenida',
      description: 'Lo-fi tranquilo al caer la tarde',
      emoji: '🌇',
      asset: 'music/brix_city_2.mp3',
    ),
  ],
  'medieval': [
    WorldTrack(
      name: 'Marcha del Castillo',
      description: 'Fanfarria épica de torres y murallas',
      emoji: '🏰',
      asset: 'music/medieval_1.mp3',
    ),
    WorldTrack(
      name: 'Taberna del Reino',
      description: 'Melodía juglar de laúd 8-bit',
      emoji: '🍺',
      asset: 'music/medieval_2.mp3',
    ),
  ],
  'galaxy': [
    WorldTrack(
      name: 'Órbita Estelar',
      description: 'Synthwave cósmico entre asteroides',
      emoji: '🌌',
      asset: 'music/galaxy_1.mp3',
    ),
    WorldTrack(
      name: 'Salto Hiperespacial',
      description: 'Pulso veloz a la velocidad de la luz',
      emoji: '🚀',
      asset: 'music/galaxy_2.mp3',
    ),
  ],
  'jungle': [
    WorldTrack(
      name: 'Corazón de la Selva',
      description: 'Ritmo tribal entre lianas',
      emoji: '🥁',
      asset: 'music/jungle_1.mp3',
    ),
    WorldTrack(
      name: 'Templo Perdido',
      description: 'Aventura chiptune entre ruinas',
      emoji: '🗿',
      asset: 'music/jungle_2.mp3',
    ),
  ],
  'dark_city': [
    WorldTrack(
      name: 'Carrera Embrujada',
      description: 'Persecución frenética de sombras',
      emoji: '👻',
      asset: 'music/dark_city_1.mp3',
    ),
    WorldTrack(
      name: 'Casa Encantada 8-bit',
      description: 'Chiptune travieso de Halloween',
      emoji: '🎃',
      asset: 'music/dark_city_2.mp3',
    ),
  ],
  'ocean': [
    WorldTrack(
      name: 'Arrecife de Neón',
      description: 'Synth submarino y luminoso',
      emoji: '🐠',
      asset: 'music/ocean_1.mp3',
    ),
    WorldTrack(
      name: 'Corrientes Profundas',
      description: 'Lo-fi flotante entre burbujas',
      emoji: '🫧',
      asset: 'music/ocean_2.mp3',
    ),
  ],
  'tundra': [
    WorldTrack(
      name: 'Ventisca Veloz',
      description: 'Carrera trepidante sobre el hielo',
      emoji: '🌨️',
      asset: 'music/tundra_1.mp3',
    ),
    WorldTrack(
      name: 'Viento Polar',
      description: 'Synth gélido y cristalino',
      emoji: '❄️',
      asset: 'music/tundra_2.mp3',
    ),
  ],
  'robot_city': [
    WorldTrack(
      name: 'Circuito Sintético',
      description: 'Synthwave metálico de fábrica',
      emoji: '🤖',
      asset: 'music/robot_city_1.mp3',
    ),
    WorldTrack(
      name: 'Sobrecarga',
      description: 'Techno-pop a máxima revolución',
      emoji: '⚡',
      asset: 'music/robot_city_2.mp3',
    ),
  ],
};

/// Repertorio del mundo [worldId]; usa Ciudad Brix como respaldo.
List<WorldTrack> worldTracksFor(String worldId) =>
    worldMusicCatalog[worldId] ?? worldMusicCatalog['brix_city']!;
