import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/core/services/audio_service.dart';
import 'package:run_for_win/core/services/sfx_player.dart';

/// Reproductor de mentira que **anota lo que le piden**. Lo que se está fijando
/// aquí es que cada clip se prepare UNA sola vez y que reproducir sea solo
/// relanzarlo: preparar en cada disparo era el micro-tirón de los efectos.
class _SpyPlayer implements SfxPlayer {
  static final List<_SpyPlayer> created = [];

  _SpyPlayer() {
    created.add(this);
  }

  String? preparedAsset;
  int prepares = 0;
  int restarts = 0;
  int releases = 0;

  @override
  Future<void> prepare(String assetPath) async {
    prepares++;
    preparedAsset = assetPath;
  }

  @override
  Future<void> restart() async => restarts++;

  @override
  Future<void> release() async => releases++;
}

/// Un reproductor que revienta al prepararse, para comprobar que un efecto roto
/// no se lleva por delante al resto.
class _BrokenPlayer implements SfxPlayer {
  @override
  Future<void> prepare(String assetPath) async =>
      throw StateError('sin códec');
  @override
  Future<void> restart() async {}
  @override
  Future<void> release() async {}
}

void main() {
  late AudioService audio;

  setUp(() {
    _SpyPlayer.created.clear();
    audio = AudioService.instance;
    audio.muteAll = false;
    audio.sfxPlayerFactory = _SpyPlayer.new;
  });

  tearDown(() async {
    await audio.dispose();
    audio.muteAll = true;
    audio.sfxPlayerFactory = AudioplayersSfxPlayer.new;
  });

  List<_SpyPlayer> forAsset(String name) => _SpyPlayer.created
      .where((p) => p.preparedAsset == 'audio/$name')
      .toList();

  group('Precarga', () {
    test('deja todos los efectos preparados antes de la partida', () async {
      await audio.preload();

      expect(_SpyPlayer.created, isNotEmpty);
      for (final p in _SpyPlayer.created) {
        expect(p.prepares, 1, reason: 'cada clip se prepara una sola vez');
        expect(p.preparedAsset, startsWith('audio/'));
        expect(p.restarts, 0, reason: 'precargar no hace sonar nada');
      }
    });

    test('las monedas llevan más copias que los sonidos de menú', () async {
      await audio.preload();
      // Con el imán, las monedas llegan en ráfaga y deben poder solaparse;
      // la ruleta no se solapa nunca consigo misma.
      expect(forAsset('coin.wav').length,
          greaterThan(forAsset('roulette_spin.wav').length));
    });

    test('un efecto que falla al prepararse no aborta los demás', () async {
      var n = 0;
      // El tercer reproductor construido revienta.
      audio.sfxPlayerFactory = () => (n++ == 2) ? _BrokenPlayer() : _SpyPlayer();

      await audio.preload();

      expect(_SpyPlayer.created.length, greaterThan(3),
          reason: 'la precarga continuó tras el fallo');
    });
  });

  group('Reproducir no vuelve a preparar', () {
    test('el clip ya preparado solo se relanza', () async {
      await audio.preload();
      final jump = forAsset('jump.wav');

      audio.playJump();
      await pumpEventQueue();

      expect(jump.map((p) => p.restarts).reduce((a, b) => a + b), 1);
      for (final p in jump) {
        expect(p.prepares, 1, reason: 'sonar no puede volver a preparar');
      }
    });

    test('repetir el efecto no dispara ninguna preparación más', () async {
      await audio.preload();
      final coin = forAsset('coin.wav');

      for (var i = 0; i < 12; i++) {
        audio.playCoin();
      }
      await pumpEventQueue();

      expect(coin.map((p) => p.restarts).reduce((a, b) => a + b), 12);
      for (final p in coin) {
        expect(p.prepares, 1);
      }
    });

    test('las reproducciones rotan entre las copias del pool', () async {
      await audio.preload();
      final coin = forAsset('coin.wav');
      expect(coin.length, greaterThan(1));

      // Una reproducción por copia: cada una debe haber sonado exactamente vez.
      for (var i = 0; i < coin.length; i++) {
        audio.playCoin();
        await pumpEventQueue();
      }
      for (final p in coin) {
        expect(p.restarts, 1, reason: 'sin rotación, una sola copia sonaría');
      }
    });
  });

  group('Sin precarga previa', () {
    test('el primer disparo arma el pool y suena igual', () async {
      audio.playHit();
      await pumpEventQueue();

      final hit = forAsset('hit.wav');
      expect(hit, isNotEmpty);
      expect(hit.map((p) => p.restarts).reduce((a, b) => a + b), 1);
    });

    test('dos disparos seguidos no construyen el pool dos veces', () async {
      // Sin guardar el `Future` del pool en curso, la segunda llamada llegaría
      // antes de que la primera terminase y crearía reproductores de más.
      audio.playHit();
      audio.playHit();
      await pumpEventQueue();

      expect(forAsset('hit.wav').every((p) => p.prepares == 1), isTrue);
      expect(forAsset('hit.wav').length, lessThanOrEqualTo(2));
    });
  });

  group('Corte global de audio', () {
    test('con muteAll no se crea ni se toca ningún reproductor', () async {
      audio.muteAll = true;
      await audio.preload();
      audio.playCoin();
      await pumpEventQueue();

      expect(_SpyPlayer.created, isEmpty);
    });
  });

  group('Liberación', () {
    test('dispose suelta todos los reproductores', () async {
      await audio.preload();
      final all = List.of(_SpyPlayer.created);

      await audio.dispose();

      expect(all.every((p) => p.releases == 1), isTrue);
    });
  });
}
