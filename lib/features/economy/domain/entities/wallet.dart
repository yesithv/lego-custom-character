import 'package:equatable/equatable.dart';

class Wallet extends Equatable {
  final int coins;
  final DateTime? lastRouletteDate;
  final List<String> unlockedParts;
  final int runStreak;
  final DateTime? lastPlayDate;
  final int totalCoinsEarned;

  /// Última recompensa reclamada en la ruleta (para mostrar "HOY GANASTE"
  /// cuando ya se giró). `label` es el texto corto (p. ej. "50" o "Jetpack")
  /// y `emoji` el icono (🪙, 💎, …). Nulos si nunca se ha girado.
  final String? lastRouletteRewardLabel;
  final String? lastRouletteRewardEmoji;

  const Wallet({
    this.coins = 0,
    this.lastRouletteDate,
    this.unlockedParts = const [],
    this.runStreak = 0,
    this.lastPlayDate,
    this.totalCoinsEarned = 0,
    this.lastRouletteRewardLabel,
    this.lastRouletteRewardEmoji,
  });

  bool get canClaimRoulette {
    if (lastRouletteDate == null) return true;
    // Comparar por día natural LOCAL. En web, Hive puede devolver la fecha en
    // UTC; sin `toLocal()` un giro de noche se guarda como el día siguiente y
    // bloqueaba la ruleta durante todo el día natural siguiente.
    final now = DateTime.now();
    final l = lastRouletteDate!.toLocal();
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
    String? lastRouletteRewardLabel,
    String? lastRouletteRewardEmoji,
  }) =>
      Wallet(
        coins: coins ?? this.coins,
        lastRouletteDate: lastRouletteDate ?? this.lastRouletteDate,
        unlockedParts: unlockedParts ?? this.unlockedParts,
        runStreak: runStreak ?? this.runStreak,
        lastPlayDate: lastPlayDate ?? this.lastPlayDate,
        totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
        lastRouletteRewardLabel:
            lastRouletteRewardLabel ?? this.lastRouletteRewardLabel,
        lastRouletteRewardEmoji:
            lastRouletteRewardEmoji ?? this.lastRouletteRewardEmoji,
      );

  @override
  List<Object?> get props => [
        coins,
        lastRouletteDate,
        unlockedParts,
        runStreak,
        lastPlayDate,
        totalCoinsEarned,
        lastRouletteRewardLabel,
        lastRouletteRewardEmoji,
      ];
}
