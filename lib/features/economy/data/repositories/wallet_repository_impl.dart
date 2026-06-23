import 'dart:math';

import '../../../character_editor/domain/entities/character.dart';
import '../../domain/entities/reward.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_local_datasource.dart';
import '../models/wallet_model.dart';

// Weighted prize table for roulette and chests
const _roulettePrizes = [
  (weight: 30, prize: CoinsReward(50)),
  (weight: 25, prize: CoinsReward(100)),
  (weight: 15, prize: CoinsReward(200)),
  (weight: 10, prize: CoinsReward(500)),
  (weight: 10, prize: PartReward(partId: 'cape', partName: 'Capa', rarity: AccessoryRarity.common)),
  (weight: 5, prize: PartReward(partId: 'shield', partName: 'Escudo', rarity: AccessoryRarity.common)),
  (weight: 4, prize: PartReward(partId: 'jetpack', partName: 'Jetpack', rarity: AccessoryRarity.rare)),
  (weight: 1, prize: PartReward(partId: 'golden_medallion', partName: 'Medallón dorado', rarity: AccessoryRarity.epic)),
];

const _commonChestPrizes = [
  (weight: 50, prize: CoinsReward(30)),
  (weight: 25, prize: CoinsReward(75)),
  (weight: 15, prize: PartReward(partId: 'hat_1', partName: 'Sombrero', rarity: AccessoryRarity.common)),
  (weight: 8, prize: PartReward(partId: 'wings', partName: 'Alas', rarity: AccessoryRarity.rare)),
  (weight: 2, prize: PartReward(partId: 'crown', partName: 'Corona épica', rarity: AccessoryRarity.epic)),
];

const _vipChestPrizes = [
  (weight: 30, prize: CoinsReward(150)),
  (weight: 25, prize: PartReward(partId: 'jetpack', partName: 'Jetpack', rarity: AccessoryRarity.rare)),
  (weight: 25, prize: PartReward(partId: 'magic_wand', partName: 'Varita mágica', rarity: AccessoryRarity.rare)),
  (weight: 15, prize: PartReward(partId: 'golden_cape', partName: 'Capa dorada', rarity: AccessoryRarity.epic)),
  (weight: 5, prize: PartReward(partId: 'legendary_sword', partName: 'Espada legendaria', rarity: AccessoryRarity.legendary)),
];

class WalletRepositoryImpl implements WalletRepository {
  final WalletLocalDatasource _datasource;
  final _rng = Random();

  WalletRepositoryImpl(this._datasource);

  @override
  Future<Wallet> getWallet() async => _datasource.getWallet().toEntity();

  @override
  Future<Wallet> earnCoins(int amount) async {
    final m = _datasource.getWallet();
    final updated = m.toEntity().copyWith(
          coins: m.coins + amount,
          totalCoinsEarned: m.totalCoinsEarned + amount,
        );
    await _datasource.saveWallet(WalletModel.fromEntity(updated));
    return updated;
  }

  @override
  Future<Wallet> spendCoins(int amount) async {
    final m = _datasource.getWallet();
    if (m.coins < amount) return m.toEntity();
    final updated = m.toEntity().copyWith(coins: m.coins - amount);
    await _datasource.saveWallet(WalletModel.fromEntity(updated));
    return updated;
  }

  @override
  Future<({Wallet wallet, Reward reward})> claimDailyRoulette() async {
    final prize = _weightedPick(_roulettePrizes);
    final m = _datasource.getWallet();
    int newCoins = m.coins;
    List<String> parts = List.from(m.unlockedParts);

    if (prize is CoinsReward) {
      newCoins += prize.amount;
    } else if (prize is PartReward) {
      if (!parts.contains(prize.partId)) parts.add(prize.partId);
    }

    final updated = m.toEntity().copyWith(
          coins: newCoins,
          lastRouletteDate: DateTime.now(),
          unlockedParts: parts,
          totalCoinsEarned: prize is CoinsReward
              ? m.totalCoinsEarned + (prize as CoinsReward).amount
              : m.totalCoinsEarned,
        );
    await _datasource.saveWallet(WalletModel.fromEntity(updated));
    return (wallet: updated, reward: prize);
  }

  @override
  Future<({Wallet wallet, Reward reward})> openChest({required bool isVip}) async {
    final table = isVip ? _vipChestPrizes : _commonChestPrizes;
    final prize = _weightedPick(table);
    final m = _datasource.getWallet();
    int newCoins = m.coins;
    List<String> parts = List.from(m.unlockedParts);

    if (prize is CoinsReward) {
      newCoins += prize.amount;
    } else if (prize is PartReward) {
      if (!parts.contains(prize.partId)) parts.add(prize.partId);
    }

    final updated = m.toEntity().copyWith(
          coins: newCoins,
          unlockedParts: parts,
        );
    await _datasource.saveWallet(WalletModel.fromEntity(updated));
    return (wallet: updated, reward: prize);
  }

  @override
  Future<Wallet> recordRunCompletion(int coinsEarned) async {
    final m = _datasource.getWallet();
    final now = DateTime.now();
    final last = m.lastPlayDate;

    final isConsecutive = last != null &&
        now.difference(last).inDays <= 1 &&
        (now.day != last.day || now.month != last.month);

    final newStreak = isConsecutive ? m.runStreak + 1 : 1;

    final updated = m.toEntity().copyWith(
          coins: m.coins + coinsEarned,
          totalCoinsEarned: m.totalCoinsEarned + coinsEarned,
          runStreak: newStreak,
          lastPlayDate: now,
        );
    await _datasource.saveWallet(WalletModel.fromEntity(updated));
    return updated;
  }

  Reward _weightedPick(
      List<({int weight, Reward prize})> table) {
    final total = table.fold(0, (sum, e) => sum + e.weight);
    var roll = _rng.nextInt(total);
    for (final entry in table) {
      roll -= entry.weight;
      if (roll < 0) return entry.prize;
    }
    return table.last.prize;
  }
}
