// AudioService stub — integrates all audio hooks throughout the codebase.
// To activate real sound: add `audioplayers: ^6.0.0` to pubspec.yaml, run
// flutter pub get, then replace each _play() stub with:
//   AudioPlayer()..play(AssetSource('audio/$name'))
//     .then((_) {}).catchError((_) {});
// Place .mp3 files in assets/audio/ matching the names below.
class AudioService {
  static final AudioService instance = AudioService._();
  AudioService._();

  bool muted = false;

  void toggleMute() => muted = !muted;

  void playJump() => _play('jump.mp3');
  void playCoin() => _play('coin.mp3');
  void playHit() => _play('hit.mp3');
  void playPowerup() => _play('powerup.mp3');
  void playUnlock() => _play('unlock.mp3');
  void playRouletteSpin() => _play('roulette_spin.mp3');
  void playChestOpen() => _play('chest_open.mp3');

  // ignore: unused_element
  void _play(String name) {
    if (muted) return;
    // Stub: no-op until audioplayers is added.
  }
}
