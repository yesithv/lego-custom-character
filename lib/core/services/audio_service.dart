import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'sfx_player.dart';

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

  // ── Efectos de sonido ──────────────────────────────────────────────────────
  //
  // Cada efecto tiene un pool rotatorio de reproductores: permite que varias
  // copias del MISMO sonido suenen solapadas (la ráfaga de monedas del imán)
  // sin que cada nueva reproducción corte la anterior.

  /// Los efectos y cuántas copias simultáneas necesita cada uno.
  ///
  /// Más allá de lo que el sonido pide, un reproductor de más solo es memoria
  /// nativa ocupada: las monedas sí llegan en ráfaga con el imán, pero el cofre
  /// y la ruleta no se solapan nunca consigo mismos.
  static const Map<String, int> _sfx = {
    'coin.wav': 4,
    'jump.wav': 2,
    'slide.wav': 2,
    'hit.wav': 2,
    'powerup.wav': 2,
    'unlock.wav': 2,
    'roulette_spin.wav': 1,
    'chest_open.wav': 1,
  };

  /// Pools listos o **en preparación**, por nombre de efecto. Guardar el
  /// `Future` (y no solo la lista) evita que una reproducción que llegue antes
  /// de que termine el precargado use reproductores a medio preparar, y que dos
  /// llamadas seguidas construyan el pool dos veces.
  final _pools = <String, Future<List<SfxPlayer>>>{};
  final _poolIndex = <String, int>{};

  /// Fábrica de reproductores de efectos. Los tests la sustituyen por un doble
  /// para verificar la política del pool sin canales de plataforma.
  @visibleForTesting
  SfxPlayer Function() sfxPlayerFactory = AudioplayersSfxPlayer.new;

  // Dedicated looping player for background music
  AudioPlayer? _musicPlayer;
  String? _currentMusicAsset;

  /// Alterna el silencio de la música de fondo (no afecta a los efectos).
  void toggleMusicMute() {
    musicMuted = !musicMuted;
    // Silencia/reactiva la música de fondo en caliente sin cortar la pista
    _musicPlayer?.setVolume(musicMuted ? 0.0 : _musicVolume);
  }

  /// Deja todos los efectos **listos para sonar sin latencia**.
  ///
  /// Se llama al arrancar, sin `await`: no bloquea el primer frame y los pools
  /// se van armando de fondo. Es idempotente y traga cualquier fallo (un efecto
  /// que no se pueda preparar se preparará al usarse).
  ///
  /// Los pools se arman **uno detrás de otro, no todos a la vez**: son 16
  /// reproductores nativos y lanzarlos en paralelo concentraría el trabajo en
  /// un par de frames del menú. En serie se reparte solo.
  Future<void> preload() async {
    if (muteAll) return;
    for (final name in _sfx.keys) {
      try {
        await _pool(name);
      } catch (_) {
        // Un efecto que falle al prepararse no debe abortar el resto.
        _pools.remove(name);
      }
    }
  }

  /// Devuelve el pool de [name], creándolo si hace falta.
  Future<List<SfxPlayer>> _pool(String name) =>
      _pools[name] ??= _buildPool(name);

  /// Construye el pool de [name] y deja sus reproductores preparados. El porqué
  /// de cada ajuste está en [AudioplayersSfxPlayer.prepare]: ahí es donde se
  /// arregla el micro-tirón.
  Future<List<SfxPlayer>> _buildPool(String name) async {
    final pool = List.generate(_sfx[name] ?? 1, (_) => sfxPlayerFactory());
    for (final player in pool) {
      await player.prepare('audio/$name');
    }
    _poolIndex[name] = 0;
    return pool;
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

  Future<void> dispose() async {
    // Los pools pueden estar aún armándose: se espera a cada uno antes de
    // soltarlo, para no dejar reproductores nativos huérfanos.
    final pools = _pools.values.toList();
    _pools.clear();
    _poolIndex.clear();
    for (final pending in pools) {
      try {
        for (final p in await pending) {
          await p.release();
        }
      } catch (_) {}
    }
    _musicPlayer?.dispose();
    _musicPlayer = null;
    _currentMusicAsset = null;
  }

  void _play(String name) {
    // Los efectos siempre suenan salvo el corte global de audio (tests): el
    // botón de silencio del juego solo apaga la música.
    if (muteAll) return;
    unawaited(_playSfx(name));
  }

  /// Lanza un efecto. Dispara y olvida: nunca se espera desde el bucle de
  /// juego, y cualquier fallo se traga (el audio no puede tumbar la partida).
  Future<void> _playSfx(String name) async {
    try {
      final pool = await _pool(name);
      // Rota al siguiente reproductor para no cortar el que ya suena.
      final idx = _poolIndex[name] ?? 0;
      _poolIndex[name] = (idx + 1) % pool.length;
      await pool[idx].restart();
    } catch (_) {
      // Silencio antes que un crash.
    }
  }
}
