import '../entities/wallet.dart';
import '../repositories/wallet_repository.dart';

class RecordRun {
  final WalletRepository repository;
  RecordRun(this.repository);

  Future<Wallet> call(int coinsEarned) =>
      repository.recordRunCompletion(coinsEarned);
}
