import 'package:audioplayers/audioplayers.dart';

/// Un reproductor de **efectos cortos**, detrás de interfaz.
///
/// El proyecto pone los servicios externos tras una interfaz con su
/// implementación intercambiable (Store, Analytics, Score); el audio era la
/// excepción. Tenerlo así permite además probar la política del pool —cuántas
/// copias, cómo rotan, que el clip se prepara UNA vez y luego solo se relanza—
/// sin invocar canales de plataforma.
abstract class SfxPlayer {
  /// Deja [assetPath] (relativo a `assets/`) cargado y listo para sonar de
  /// inmediato. Se llama una sola vez por reproductor.
  Future<void> prepare(String assetPath);

  /// Lanza el clip desde el principio, **sin volver a prepararlo**.
  Future<void> restart();

  /// Suelta los recursos nativos.
  Future<void> release();
}

/// Implementación sobre `audioplayers`.
///
/// Los tres ajustes de [prepare] son lo que quita los micro-tirones de los
/// efectos en pleno juego, y los tres importan:
///
/// - **`ReleaseMode.stop`.** Por defecto (`release`) el reproductor SUELTA el
///   audio nativo y los datos en cuanto el efecto termina, así que la
///   reproducción siguiente lo vuelve a crear y preparar entero. Ese era el
///   tirón, y no pasaba solo la primera vez: pasaba en CADA moneda y CADA
///   salto. Con `stop` los recursos sobreviven entre reproducciones.
/// - **`PlayerMode.lowLatency`.** En Android usa `SoundPool`, pensado justo
///   para clips cortos que se repiten, y que comparte la muestra decodificada
///   entre reproductores del mismo asset (así el pool no multiplica memoria);
///   en iOS recorta la preparación y en web es un no-op inocuo.
/// - **`setSource` al preparar y no al reproducir.** Es lo que recomienda la
///   propia librería: «to reduce preparation latency, instead consider calling
///   setSource beforehand and then resume separately».
///
/// Y por eso [restart] es `stop` + `resume` en vez de `play`: `play` rehace el
/// `setSource` —con su preparación— en cada llamada. `stop` devuelve el clip al
/// segundo 0 conservando los recursos y `resume` lo dispara ya preparado.
class AudioplayersSfxPlayer implements SfxPlayer {
  final AudioPlayer _player;

  AudioplayersSfxPlayer([AudioPlayer? player])
      : _player = player ?? AudioPlayer();

  @override
  Future<void> prepare(String assetPath) async {
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.setPlayerMode(PlayerMode.lowLatency);
    await _player.setSource(AssetSource(assetPath));
  }

  @override
  Future<void> restart() async {
    await _player.stop();
    await _player.resume();
  }

  @override
  Future<void> release() => _player.dispose();
}
