import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final int coins;
  final DateTime? lastRouletteDate;
  final List<String> unlockedParts;
  final int runStreak;
  final DateTime? lastPlayDate;
  final int totalCoinsEarned;

  const Wallet({
    this.coins = 0,
    this.lastRouletteDate,
    this.unlockedParts = const [],
    this.runStreak = 0,
    this.lastPlayDate,
    this.totalCoinsEarned = 0,
  });

  bool get canClaimRoulette {
    if (lastRouletteDate == null) return true;
    final now = DateTime.now();
    final l = lastRouletteDate!;
    return now.year != l.year || now.month != l.month || now.day != l.day;
  }

  bool get earnVipChest => runStreak >= 3;

  Wallet copyWith({
    int? coins,
    DateTime? lastRouletteDate,
    List<String>? unlockedParts,
    int? runStreak,
    DateTime? lastPlayDate,
    int? totalCoinsEarned,
  }) =>
      Wallet(
        coins: coins ?? this.coins,
        lastRouletteDate: lastRouletteDate ?? this.lastRouletteDate,
        unlockedParts: unlockedParts ?? this.unlockedParts,
        runStreak: runStreak ?? this.runStreak,
        lastPlayDate: lastPlayDate ?? this.lastPlayDate,
        totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      );

  @override
  List<Object?> get props => [
        coins,
        lastRouletteDate,
        unlockedParts,
        runStreak,
        lastPlayDate,
        totalCoinsEarned,
      ];
}
