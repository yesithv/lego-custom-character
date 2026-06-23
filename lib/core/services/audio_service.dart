import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService instance = AudioService._();
  AudioService._();

  bool muted = false;

  // One dedicated player per sound type avoids cutting off overlapping effects
  final _players = <String, AudioPlayer>{};

  void toggleMute() => muted = !muted;

  void playJump() => _play('jump.mp3');
  void playCoin() => _play('coin.mp3');
  void playHit() => _play('hit.mp3');
  void playPowerup() => _play('powerup.mp3');
  void playUnlock() => _play('unlock.mp3');
  void playRouletteSpin() => _play('roulette_spin.mp3');
  void playChestOpen() => _play('chest_open.mp3');

  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    _players.clear();
  }

  void _play(String name) {
    if (muted) return;
    final player = _players.putIfAbsent(name, () => AudioPlayer());
    player.stop().then((_) {
      player.play(AssetSource('audio/$name')).catchError((_) {});
    }).catchError((_) {});
  }
}
