import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService instance = AudioService._();
  AudioService._();

  /// Silencio de **solo la música de fondo**. Los efectos de sonido (monedas,
  /// saltos, escudo, imán, golpes…) suenan siempre; el botón del juego apaga la
  /// música, no los efectos.
  bool musicMuted = false;

  /// Corta **todo** el audio (música + efectos). No hay UI para esto: existe
  /// para los tests, que lo activan y así evitan invocar los canales de
  /// plataforma de audioplayers.
  bool muteAll = false;

  // Un pool rotatorio de reproductores por sonido: permite que varias copias
  // del mismo efecto suenen solapadas (p. ej. la ráfaga de monedas del imán)
  // sin que cada nueva reproducción corte la anterior.
  final _pools = <String, List<AudioPlayer>>{};
  final _poolIndex = <String, int>{};
  static const int _poolSize = 4;

  // Dedicated looping player for background music
  AudioPlayer? _musicPlayer;
  String? _currentMusicAsset;

  /// Alterna el silencio de la música de fondo (no afecta a los efectos).
  void toggleMusicMute() {
    musicMuted = !musicMuted;
    // Silencia/reactiva la música de fondo en caliente sin cortar la pista
    _musicPlayer?.setVolume(musicMuted ? 0.0 : _musicVolume);
  }

  void playJump() => _play('jump.wav');
  void playCoin() => _play('coin.wav');
  void playSlide() => _play('slide.wav');
  void playHit() => _play('hit.wav');
  void playPowerup() => _play('powerup.wav');
  void playUnlock() => _play('unlock.wav');
  void playRouletteSpin() => _play('roulette_spin.wav');
  void playChestOpen() => _play('chest_open.wav');

  /// Sonido al atrapar el escudo: tono enérgico de power-up.
  void playShield() => _play('powerup.wav');

  /// Sonido al atrapar el imán: chispa magnética + destello de moneda para
  /// anticipar la lluvia de monedas que atraerá.
  void playMagnet() {
    _play('unlock.wav');
    _play('coin.wav');
  }

  static const double _musicVolume = 0.55;

  /// Reproduce [asset] (ruta relativa a assets/audio/) en bucle como música
  /// de fondo. Si ya suena esa misma pista no la reinicia.
  Future<void> playMusic(String asset) async {
    if (muteAll) return;
    if (_currentMusicAsset == asset && _musicPlayer != null) return;
    await stopMusic();
    _currentMusicAsset = asset;
    final player = AudioPlayer();
    _musicPlayer = player;
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(musicMuted ? 0.0 : _musicVolume);
    try {
      await player.play(AssetSource('audio/$asset'));
    } catch (_) {
      // Ignora fallos de reproducción (p. ej. autoplay bloqueado en web)
    }
  }

  /// Pausa la música de fondo sin perder la posición (para la pausa del juego).
  Future<void> pauseMusic() async {
    try {
      await _musicPlayer?.pause();
    } catch (_) {}
  }

  /// Reanuda la música tras una pausa, salvo que esté silenciada.
  Future<void> resumeMusic() async {
    if (musicMuted || muteAll) return;
    try {
      await _musicPlayer?.resume();
    } catch (_) {}
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
    for (final pool in _pools.values) {
      for (final p in pool) {
        p.dispose();
      }
    }
    _pools.clear();
    _poolIndex.clear();
    _musicPlayer?.dispose();
    _musicPlayer = null;
    _currentMusicAsset = null;
  }

  void _play(String name) {
    // Los efectos siempre suenan salvo el corte global de audio (tests): el
    // botón de silencio del juego solo apaga la música.
    if (muteAll) return;
    final pool = _pools.putIfAbsent(
      name,
      () => List.generate(_poolSize, (_) => AudioPlayer()),
    );
    // Rota al siguiente reproductor libre para no cortar el que ya suena.
    final idx = _poolIndex[name] ?? 0;
    _poolIndex[name] = (idx + 1) % _poolSize;
    final player = pool[idx];
    // Reproducimos directo (sin `stop()` previo): en un reproductor recién
    // creado ese stop podía no resolver en algunas plataformas y dejar el
    // efecto sin sonar. `play()` ya reinicia la pista desde el principio.
    player.play(AssetSource('audio/$name')).catchError((_) {});
  }
}
