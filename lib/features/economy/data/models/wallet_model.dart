import 'package:hive/hive.dart';

import '../../domain/entities/wallet.dart';

part 'wallet_model.g.dart';

@HiveType(typeId: 2)
class WalletModel extends HiveObject {
  @HiveField(0)
  int coins;
  @HiveField(1)
  DateTime? lastRouletteDate;
  @HiveField(2)
  List<String> unlockedParts;
  @HiveField(3)
  int runStreak;
  @HiveField(4)
  DateTime? lastPlayDate;
  @HiveField(5)
  int totalCoinsEarned;

  WalletModel({
    required this.coins,
    this.lastRouletteDate,
    required this.unlockedParts,
    required this.runStreak,
    this.lastPlayDate,
    required this.totalCoinsEarned,
  });

  factory WalletModel.fromEntity(Wallet w) => WalletModel(
        coins: w.coins,
        lastRouletteDate: w.lastRouletteDate,
        unlockedParts: List.from(w.unlockedParts),
        runStreak: w.runStreak,
        lastPlayDate: w.lastPlayDate,
        totalCoinsEarned: w.totalCoinsEarned,
      );

  Wallet toEntity() => Wallet(
        coins: coins,
        lastRouletteDate: lastRouletteDate,
        unlockedParts: List.unmodifiable(unlockedParts),
        runStreak: runStreak,
        lastPlayDate: lastPlayDate,
        totalCoinsEarned: totalCoinsEarned,
      );
}
