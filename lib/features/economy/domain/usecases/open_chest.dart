import '../entities/reward.dart';
import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class OpenChest {
  final WalletRepository repository;
  OpenChest(this.repository);

  Future<({Wallet wallet, Reward reward})> call({required bool isVip}) =>
      repository.openChest(isVip: isVip);
}
