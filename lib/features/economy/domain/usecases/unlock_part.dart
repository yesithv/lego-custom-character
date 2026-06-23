import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class UnlockPart {
  final WalletRepository repository;
  UnlockPart(this.repository);

  Future<({Wallet wallet, bool success})> call(String partId, int cost) =>
      repository.unlockPart(partId, cost);
}
