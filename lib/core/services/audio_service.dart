import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService instance = AudioService._();
  AudioService._();

  bool muted = false;

  // One dedicated player per sound type avoids cutting off overlapping effects
  final _players = <String, AudioPlayer>{};

  // Dedicated looping player for background music
  AudioPlayer? _musicPlayer;
  String? _currentMusicAsset;

  void toggleMute() {
    muted = !muted;
    // Silencia/reactiva la música de fondo en caliente sin cortar la pista
    _musicPlayer?.setVolume(muted ? 0.0 : _musicVolume);
  }

  void playJump() => _play('jump.mp3');
  void playCoin() => _play('coin.mp3');
  void playHit() => _play('hit.mp3');
  void playPowerup() => _play('powerup.mp3');
  void playUnlock() => _play('unlock.mp3');
  void playRouletteSpin() => _play('roulette_spin.mp3');
  void playChestOpen() => _play('chest_open.mp3');

  static const double _musicVolume = 0.55;

  /// Reproduce [asset] (ruta relativa a assets/audio/) en bucle como música
  /// de fondo. Si ya suena esa misma pista no la reinicia.
  Future<void> playMusic(String asset) async {
    if (_currentMusicAsset == asset && _musicPlayer != null) return;
    await stopMusic();
    _currentMusicAsset = asset;
    final player = AudioPlayer();
    _musicPlayer = player;
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(muted ? 0.0 : _musicVolume);
    try {
      await player.play(AssetSource('audio/$asset'));
    } catch (_) {
      // Ignora fallos de reproducción (p. ej. autoplay bloqueado en web)
    }
  }

  Future<void> stopMusic() async {
    final player = _musicPlayer;
    _musicPlayer = null;
    _currentMusicAsset = null;
    if (player != null) {
      try {
        await player.stop();
      } catch (_) {}
      await player.dispose();
    }
  }

  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    _players.clear();
    _musicPlayer?.dispose();
    _musicPlayer = null;
    _currentMusicAsset = null;
  }

  void _play(String name) {
    if (muted) return;
    final player = _players.putIfAbsent(name, () => AudioPlayer());
    player.stop().then((_) {
      player.play(AssetSource('audio/$name')).catchError((_) {});
    }).catchError((_) {});
  }
}
