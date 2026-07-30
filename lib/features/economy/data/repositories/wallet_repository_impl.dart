import 'dart:math';

import '../../domain/entities/reward.dart';
import '../../domain/entities/reward_pools.dart';
import '../../domain/entities/wallet.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_local_datasource.dart';
import '../models/wallet_model.dart';

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
    final rolled = _weightedPick(roulettePrizeTable);
    final m = _datasource.getWallet();
    final (:coins, :parts, :reward) = _resolvePrize(rolled, m);

    // Etiqueta corta para la tarjeta "HOY GANASTE": el número si son monedas,
    // el nombre de la pieza si es un accesorio.
    final rewardLabel = switch (reward) {
      CoinsReward(:final amount) => '$amount',
      PartReward(:final partName) => partName,
    };

    final updated = m.toEntity().copyWith(
          coins: coins,
          lastRouletteDate: DateTime.now(),
          unlockedParts: parts,
          totalCoinsEarned: reward is CoinsReward
              ? m.totalCoinsEarned + reward.amount
              : m.totalCoinsEarned,
          lastRouletteRewardLabel: rewardLabel,
          lastRouletteRewardEmoji: reward.emoji,
        );
    await _datasource.saveWallet(WalletModel.fromEntity(updated));
    return (wallet: updated, reward: reward);
  }

  @override
  Future<({Wallet wallet, Reward reward})> openChest({required bool isVip}) async {
    final table = isVip ? vipChestPrizeTable : commonChestPrizeTable;
    final rolled = _weightedPick(table);
    final m = _datasource.getWallet();
    final (:coins, :parts, :reward) = _resolvePrize(rolled, m);

    final updated = m.toEntity().copyWith(
          coins: coins,
          unlockedParts: parts,
          totalCoinsEarned: reward is CoinsReward
              ? m.totalCoinsEarned + reward.amount
              : m.totalCoinsEarned,
        );
    await _datasource.saveWallet(WalletModel.fromEntity(updated));
    return (wallet: updated, reward: reward);
  }

  /// Aplica un premio recién sorteado sobre el estado actual del monedero y
  /// devuelve el nuevo saldo, la lista de piezas y el premio *efectivo*.
  ///
  /// Si el premio es un accesorio que el jugador **ya posee**, se convierte en
  /// monedas de consuelo (según su rareza) para que ningún cofre/ruleta se
  /// sienta vacío. Así toda recompensa es siempre útil.
  ({int coins, List<String> parts, Reward reward}) _resolvePrize(
      Reward prize, WalletModel m) {
    if (prize is CoinsReward) {
      return (coins: m.coins + prize.amount, parts: m.unlockedParts, reward: prize);
    }
    final part = prize as PartReward;
    if (m.unlockedParts.contains(part.partId)) {
      final consolation = coinValueForRarity(part.rarity);
      return (
        coins: m.coins + consolation,
        parts: m.unlockedParts,
        reward: CoinsReward(consolation),
      );
    }
    return (
      coins: m.coins,
      parts: [...m.unlockedParts, part.partId],
      reward: part,
    );
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

  @override
  Future<({Wallet wallet, bool success})> unlockPart(
      String partId, int cost) async {
    final m = _datasource.getWallet();
    if (m.coins < cost) return (wallet: m.toEntity(), success: false);
    final parts = List<String>.from(m.unlockedParts);
    if (!parts.contains(partId)) parts.add(partId);
    final updated = m.toEntity().copyWith(
          coins: m.coins - cost,
          unlockedParts: parts,
        );
    await _datasource.saveWallet(WalletModel.fromEntity(updated));
    return (wallet: updated, success: true);
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
