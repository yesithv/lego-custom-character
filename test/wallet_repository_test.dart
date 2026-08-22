import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/economy/data/datasources/wallet_local_datasource.dart';
import 'package:run_for_win/features/economy/data/models/wallet_model.dart';
import 'package:run_for_win/features/economy/data/repositories/wallet_repository_impl.dart';

/// Fake en memoria del datasource del monedero (mismo patrón que
/// `continue_economy_test.dart`), para probar `WalletRepositoryImpl` sin Hive.
class _FakeWalletDs implements WalletLocalDatasource {
  WalletModel model;
  _FakeWalletDs(this.model);
  @override
  WalletModel getWallet() => model;
  @override
  Future<void> saveWallet(WalletModel m) async => model = m;
}

WalletModel _wallet({
  int coins = 0,
  int earned = 0,
  int runStreak = 0,
  DateTime? lastPlayDate,
  List<String> unlockedParts = const [],
}) =>
    WalletModel(
      coins: coins,
      unlockedParts: List.of(unlockedParts),
      runStreak: runStreak,
      totalCoinsEarned: earned,
      lastPlayDate: lastPlayDate,
    );

WalletRepositoryImpl _repo(WalletModel m) =>
    WalletRepositoryImpl(_FakeWalletDs(m));

void main() {
  group('earnCoins', () {
    test('suma al saldo y a lo ganado de por vida', () async {
      final repo = _repo(_wallet(coins: 10, earned: 10));
      final w = await repo.earnCoins(40);
      expect(w.coins, 50);
      expect(w.totalCoinsEarned, 50);
    });

    test('ganar 0 no cambia nada', () async {
      final repo = _repo(_wallet(coins: 10, earned: 10));
      final w = await repo.earnCoins(0);
      expect(w.coins, 10);
      expect(w.totalCoinsEarned, 10);
    });
  });

  group('spendCoins (guarda anti-negativo)', () {
    test('descuenta cuando alcanza', () async {
      final repo = _repo(_wallet(coins: 100, earned: 100));
      final w = await repo.spendCoins(30);
      expect(w.coins, 70);
      expect(w.totalCoinsEarned, 100, reason: 'gastar no baja lo ganado');
    });

    test('no descuenta si no alcanza (saldo intacto)', () async {
      final repo = _repo(_wallet(coins: 20, earned: 20));
      final w = await repo.spendCoins(50);
      expect(w.coins, 20);
    });

    test('gastar exactamente el saldo lo deja en 0', () async {
      final repo = _repo(_wallet(coins: 50, earned: 50));
      final w = await repo.spendCoins(50);
      expect(w.coins, 0);
    });
  });

  group('unlockPart', () {
    test('desbloquea y cobra cuando alcanza', () async {
      final repo = _repo(_wallet(coins: 100));
      final r = await repo.unlockPart('cape_red', 60);
      expect(r.success, isTrue);
      expect(r.wallet.coins, 40);
      expect(r.wallet.unlockedParts, contains('cape_red'));
    });

    test('falla y no cobra si no alcanza', () async {
      final repo = _repo(_wallet(coins: 20));
      final r = await repo.unlockPart('cape_red', 60);
      expect(r.success, isFalse);
      expect(r.wallet.coins, 20);
      expect(r.wallet.unlockedParts, isEmpty);
    });

    test('no duplica una pieza ya poseída', () async {
      final repo = _repo(_wallet(coins: 100, unlockedParts: ['cape_red']));
      final r = await repo.unlockPart('cape_red', 10);
      expect(r.success, isTrue);
      expect(
        r.wallet.unlockedParts.where((p) => p == 'cape_red').length,
        1,
        reason: 'no se duplica la pieza',
      );
    });
  });

  group('recordRunCompletion — racha por días', () {
    test('primera carrera: racha a 1 y fija lastPlayDate', () async {
      final repo = _repo(_wallet(coins: 0, earned: 0));
      final w = await repo.recordRunCompletion(30);
      expect(w.runStreak, 1);
      expect(w.lastPlayDate, isNotNull);
      expect(w.coins, 30);
      expect(w.totalCoinsEarned, 30);
    });

    test('jugar al día siguiente incrementa la racha', () async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final repo = _repo(_wallet(runStreak: 4, lastPlayDate: yesterday));
      final w = await repo.recordRunCompletion(0);
      expect(w.runStreak, 5);
    });

    test('un hueco de varios días reinicia la racha a 1', () async {
      final old = DateTime.now().subtract(const Duration(days: 5));
      final repo = _repo(_wallet(runStreak: 7, lastPlayDate: old));
      final w = await repo.recordRunCompletion(0);
      expect(w.runStreak, 1);
    });
  });
}
