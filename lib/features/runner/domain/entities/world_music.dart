/// Catálogo de música ambientada por mundo.
///
/// A partir de esta versión la música ya no es una elección personal del
/// personaje: cada mundo ofrece su propio repertorio temático y el jugador
/// decide, justo antes de correr, si quiere música y cuál de las pistas del
/// mundo suena de fondo.
///
/// Los ficheros de audio disponibles son limitados, así que varias pistas
/// temáticas comparten el mismo asset pero con nombre y ambientación propios
/// del mundo (p. ej. una «marcha de castillo» en el mundo medieval).
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
      asset: 'music/neon.mp3',
    ),
    WorldTrack(
      name: 'Hora Punta',
      description: 'Energía acelerada entre semáforos',
      emoji: '🚦',
      asset: 'music/rat_rave.mp3',
    ),
    WorldTrack(
      name: 'Arcade del Centro',
      description: 'Chiptune alegre de plaza LEGO',
      emoji: '🎮',
      asset: 'music/chiptune.mp3',
    ),
    WorldTrack(
      name: 'Atardecer en la Avenida',
      description: 'Lo-fi tranquilo al caer la tarde',
      emoji: '🌇',
      asset: 'music/chill.mp3',
    ),
  ],
  'medieval': [
    WorldTrack(
      name: 'Marcha del Castillo',
      description: 'Fanfarria épica de torres y murallas',
      emoji: '🏰',
      asset: 'music/neon.mp3',
    ),
    WorldTrack(
      name: 'Justa del Torneo',
      description: 'Galope frenético hacia la catapulta',
      emoji: '⚔️',
      asset: 'music/rat_rave.mp3',
    ),
    WorldTrack(
      name: 'Taberna del Reino',
      description: 'Melodía juglar de laúd 8-bit',
      emoji: '🍺',
      asset: 'music/chiptune.mp3',
    ),
    WorldTrack(
      name: 'Bosque Encantado',
      description: 'Calma mística junto al foso',
      emoji: '🌲',
      asset: 'music/chill.mp3',
    ),
  ],
  'galaxy': [
    WorldTrack(
      name: 'Órbita Estelar',
      description: 'Synthwave cósmico entre asteroides',
      emoji: '🌌',
      asset: 'music/neon.mp3',
    ),
    WorldTrack(
      name: 'Salto Hiperespacial',
      description: 'Pulso veloz a la velocidad de la luz',
      emoji: '🚀',
      asset: 'music/rat_rave.mp3',
    ),
    WorldTrack(
      name: 'Consola de la Estación',
      description: 'Bleeps arcade de la nave nodriza',
      emoji: '🛸',
      asset: 'music/chiptune.mp3',
    ),
  ],
  'jungle': [
    WorldTrack(
      name: 'Corazón de la Selva',
      description: 'Ritmo tribal entre lianas',
      emoji: '🥁',
      asset: 'music/rat_rave.mp3',
    ),
    WorldTrack(
      name: 'Río de Bloques',
      description: 'Lo-fi húmedo bajo la fronda',
      emoji: '🌿',
      asset: 'music/chill.mp3',
    ),
    WorldTrack(
      name: 'Templo Perdido',
      description: 'Aventura chiptune entre ruinas',
      emoji: '🗿',
      asset: 'music/chiptune.mp3',
    ),
  ],
  'dark_city': [
    WorldTrack(
      name: 'Niebla del Cementerio',
      description: 'Synth oscuro y espectral',
      emoji: '🕸️',
      asset: 'music/neon.mp3',
    ),
    WorldTrack(
      name: 'Carrera Embrujada',
      description: 'Persecución frenética de sombras',
      emoji: '👻',
      asset: 'music/rat_rave.mp3',
    ),
    WorldTrack(
      name: 'Casa Encantada 8-bit',
      description: 'Chiptune tétrico de Halloween',
      emoji: '🎃',
      asset: 'music/chiptune.mp3',
    ),
  ],
  'ocean': [
    WorldTrack(
      name: 'Corrientes Profundas',
      description: 'Lo-fi flotante entre burbujas',
      emoji: '🫧',
      asset: 'music/chill.mp3',
    ),
    WorldTrack(
      name: 'Arrecife de Neón',
      description: 'Synth submarino y luminoso',
      emoji: '🐠',
      asset: 'music/neon.mp3',
    ),
    WorldTrack(
      name: 'Fiesta del Coral',
      description: 'Chiptune burbujeante y alegre',
      emoji: '🐙',
      asset: 'music/chiptune.mp3',
    ),
  ],
  'tundra': [
    WorldTrack(
      name: 'Viento Polar',
      description: 'Synth gélido y cristalino',
      emoji: '❄️',
      asset: 'music/neon.mp3',
    ),
    WorldTrack(
      name: 'Ventisca Veloz',
      description: 'Carrera trepidante sobre el hielo',
      emoji: '🌨️',
      asset: 'music/rat_rave.mp3',
    ),
    WorldTrack(
      name: 'Refugio Nevado',
      description: 'Lo-fi cálido entre témpanos',
      emoji: '🏔️',
      asset: 'music/chill.mp3',
    ),
  ],
  'robot_city': [
    WorldTrack(
      name: 'Circuito Sintético',
      description: 'Synthwave metálico de fábrica',
      emoji: '🤖',
      asset: 'music/neon.mp3',
    ),
    WorldTrack(
      name: 'Sobrecarga',
      description: 'Techno-pop a máxima revolución',
      emoji: '⚡',
      asset: 'music/rat_rave.mp3',
    ),
    WorldTrack(
      name: 'Núcleo de Datos',
      description: 'Chiptune de engranajes y pantallas',
      emoji: '💾',
      asset: 'music/chiptune.mp3',
    ),
  ],
};

/// Repertorio del mundo [worldId]; usa Ciudad LEGO como respaldo.
List<WorldTrack> worldTracksFor(String worldId) =>
    worldMusicCatalog[worldId] ?? worldMusicCatalog['lego_city']!;
