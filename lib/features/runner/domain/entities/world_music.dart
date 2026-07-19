/// Catálogo de música ambientada por mundo.
///
/// A partir de esta versión la música ya no es una elección personal del
/// personaje: cada mundo ofrece su propio repertorio temático y el jugador
/// decide, justo antes de correr, si quiere música y cuál de las pistas del
/// mundo suena de fondo.
///
/// Cada pista tiene su propio fichero de audio, sintetizado a medida con un
/// estilo chiptune acorde al mundo (ver `tool/gen_music.py`). El mundo define
/// la escala/tonalidad y cada pista un estilo (tempo, timbre, percusión).
class WorldTrack {
  final String name;
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
}

/// Repertorio temático por identificador de mundo.
const worldMusicCatalog = <String, List<WorldTrack>>{
  'lego_city': [
    WorldTrack(
      name: 'Ritmo de Ciudad',
      description: 'Groove urbano de calles de bloques',
      emoji: '🏙️',
      asset: 'music/lego_city_1.wav',
    ),
    WorldTrack(
      name: 'Hora Punta',
      description: 'Energía acelerada entre semáforos',
      emoji: '🚦',
      asset: 'music/lego_city_2.wav',
    ),
    WorldTrack(
      name: 'Arcade del Centro',
      description: 'Chiptune alegre de plaza Brix',
      emoji: '🎮',
      asset: 'music/lego_city_3.wav',
    ),
    WorldTrack(
      name: 'Atardecer en la Avenida',
      description: 'Lo-fi tranquilo al caer la tarde',
      emoji: '🌇',
      asset: 'music/lego_city_4.wav',
    ),
  ],
  'medieval': [
    WorldTrack(
      name: 'Marcha del Castillo',
      description: 'Fanfarria épica de torres y murallas',
      emoji: '🏰',
      asset: 'music/medieval_1.wav',
    ),
    WorldTrack(
      name: 'Justa del Torneo',
      description: 'Galope frenético hacia la catapulta',
      emoji: '⚔️',
      asset: 'music/medieval_2.wav',
    ),
    WorldTrack(
      name: 'Taberna del Reino',
      description: 'Melodía juglar de laúd 8-bit',
      emoji: '🍺',
      asset: 'music/medieval_3.wav',
    ),
    WorldTrack(
      name: 'Bosque Encantado',
      description: 'Calma mística junto al foso',
      emoji: '🌲',
      asset: 'music/medieval_4.wav',
    ),
  ],
  'galaxy': [
    WorldTrack(
      name: 'Órbita Estelar',
      description: 'Synthwave cósmico entre asteroides',
      emoji: '🌌',
      asset: 'music/galaxy_1.wav',
    ),
    WorldTrack(
      name: 'Salto Hiperespacial',
      description: 'Pulso veloz a la velocidad de la luz',
      emoji: '🚀',
      asset: 'music/galaxy_2.wav',
    ),
    WorldTrack(
      name: 'Consola de la Estación',
      description: 'Bleeps arcade de la nave nodriza',
      emoji: '🛸',
      asset: 'music/galaxy_3.wav',
    ),
  ],
  'jungle': [
    WorldTrack(
      name: 'Corazón de la Selva',
      description: 'Ritmo tribal entre lianas',
      emoji: '🥁',
      asset: 'music/jungle_1.wav',
    ),
    WorldTrack(
      name: 'Río de Bloques',
      description: 'Lo-fi húmedo bajo la fronda',
      emoji: '🌿',
      asset: 'music/jungle_2.wav',
    ),
    WorldTrack(
      name: 'Templo Perdido',
      description: 'Aventura chiptune entre ruinas',
      emoji: '🗿',
      asset: 'music/jungle_3.wav',
    ),
  ],
  'dark_city': [
    WorldTrack(
      name: 'Niebla del Cementerio',
      description: 'Synth oscuro y espectral',
      emoji: '🕸️',
      asset: 'music/dark_city_1.wav',
    ),
    WorldTrack(
      name: 'Carrera Embrujada',
      description: 'Persecución frenética de sombras',
      emoji: '👻',
      asset: 'music/dark_city_2.wav',
    ),
    WorldTrack(
      name: 'Casa Encantada 8-bit',
      description: 'Chiptune tétrico de Halloween',
      emoji: '🎃',
      asset: 'music/dark_city_3.wav',
    ),
  ],
  'ocean': [
    WorldTrack(
      name: 'Corrientes Profundas',
      description: 'Lo-fi flotante entre burbujas',
      emoji: '🫧',
      asset: 'music/ocean_1.wav',
    ),
    WorldTrack(
      name: 'Arrecife de Neón',
      description: 'Synth submarino y luminoso',
      emoji: '🐠',
      asset: 'music/ocean_2.wav',
    ),
    WorldTrack(
      name: 'Fiesta del Coral',
      description: 'Chiptune burbujeante y alegre',
      emoji: '🐙',
      asset: 'music/ocean_3.wav',
    ),
  ],
  'tundra': [
    WorldTrack(
      name: 'Viento Polar',
      description: 'Synth gélido y cristalino',
      emoji: '❄️',
      asset: 'music/tundra_1.wav',
    ),
    WorldTrack(
      name: 'Ventisca Veloz',
      description: 'Carrera trepidante sobre el hielo',
      emoji: '🌨️',
      asset: 'music/tundra_2.wav',
    ),
    WorldTrack(
      name: 'Refugio Nevado',
      description: 'Lo-fi cálido entre témpanos',
      emoji: '🏔️',
      asset: 'music/tundra_3.wav',
    ),
  ],
  'robot_city': [
    WorldTrack(
      name: 'Circuito Sintético',
      description: 'Synthwave metálico de fábrica',
      emoji: '🤖',
      asset: 'music/robot_city_1.wav',
    ),
    WorldTrack(
      name: 'Sobrecarga',
      description: 'Techno-pop a máxima revolución',
      emoji: '⚡',
      asset: 'music/robot_city_2.wav',
    ),
    WorldTrack(
      name: 'Núcleo de Datos',
      description: 'Chiptune de engranajes y pantallas',
      emoji: '💾',
      asset: 'music/robot_city_3.wav',
    ),
  ],
};

/// Repertorio del mundo [worldId]; usa Ciudad Brix como respaldo.
List<WorldTrack> worldTracksFor(String worldId) =>
    worldMusicCatalog[worldId] ?? worldMusicCatalog['lego_city']!;
