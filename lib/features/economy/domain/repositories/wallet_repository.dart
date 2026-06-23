import '../entities/reward.dart';
import '../entities/wallet.dart';

abstract class WalletRepository {
  Future<Wallet> getWallet();
  Future<Wallet> earnCoins(int amount);
  Future<Wallet> spendCoins(int amount);
  Future<({Wallet wallet, Reward reward})> claimDailyRoulette();
  Future<({Wallet wallet, Reward reward})> openChest({required bool isVip});
  Future<Wallet> recordRunCompletion(int coinsEarned);
  Future<({Wallet wallet, bool success})> unlockPart(String partId, int cost);
}
