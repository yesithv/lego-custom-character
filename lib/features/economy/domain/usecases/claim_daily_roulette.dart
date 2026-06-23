import '../entities/reward.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class ClaimDailyRoulette {
  final WalletRepository repository;
  ClaimDailyRoulette(this.repository);

  Future<({Wallet wallet, Reward reward, bool alreadyClaimed})> call() async {
    final wallet = await repository.getWallet();
    if (!wallet.canClaimRoulette) {
      return (wallet: wallet, reward: const CoinsReward(0), alreadyClaimed: true);
    }
    final result = await repository.claimDailyRoulette();
    return (wallet: result.wallet, reward: result.reward, alreadyClaimed: false);
  }
}
