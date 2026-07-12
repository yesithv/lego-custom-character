import 'character.dart';

/// Metadatos de cada pista de música seleccionable para la partida.
class MusicTrackInfo {
  final MusicTrack track;
  final String name;
  final String description;
  final String emoji;

  /// Nombre de archivo bajo assets/audio/music/.
  final String asset;

  const MusicTrackInfo({
    required this.track,
    required this.name,
    required this.description,
    required this.emoji,
    required this.asset,
  });
}

const musicCatalog = <MusicTrack, MusicTrackInfo>{
  MusicTrack.ratRave: MusicTrackInfo(
    track: MusicTrack.ratRave,
    name: 'Fiebre Rata',
    description: 'Hyper-pop meme, rápida y pegajosa',
    emoji: '🐀',
    asset: 'music/rat_rave.mp3',
  ),
  MusicTrack.neon: MusicTrackInfo(
    track: MusicTrack.neon,
    name: 'Turbo Neón',
    description: 'Synthwave retro y motora',
    emoji: '🌆',
    asset: 'music/neon.mp3',
  ),
  MusicTrack.chiptune: MusicTrackInfo(
    track: MusicTrack.chiptune,
    name: 'Bloques 8-bit',
    description: 'Chiptune arcade alegre',
    emoji: '🎮',
    asset: 'music/chiptune.mp3',
  ),
  MusicTrack.chill: MusicTrackInfo(
    track: MusicTrack.chill,
    name: 'Onda Chill',
    description: 'Lo-fi relajado y suave',
    emoji: '🌙',
    asset: 'music/chill.mp3',
  ),
};

MusicTrackInfo musicInfoFor(MusicTrack track) =>
    musicCatalog[track] ?? musicCatalog[MusicTrack.ratRave]!;
