import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class EarnCoins {
  final WalletRepository repository;
  EarnCoins(this.repository);
  Future<Wallet> call(int amount) => repository.earnCoins(amount);
}
