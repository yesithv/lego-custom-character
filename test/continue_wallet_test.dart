import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/economy/data/datasources/wallet_local_datasource.dart';
import 'package:run_for_win/features/economy/data/models/wallet_model.dart';
import 'package:run_for_win/features/economy/data/repositories/wallet_repository_impl.dart';

/// Datasource en memoria (mismo patrón que reward_pools_test): evita Hive.
class _FakeDatasource implements WalletLocalDatasource {
  WalletModel model;
  _FakeDatasource(this.model);

  @override
  WalletModel getWallet() => model;

  @override
  Future<void> saveWallet(WalletModel m) async => model = m;
}

WalletModel _wallet({required int coins, required int earned}) => WalletModel(
      coins: coins,
      unlockedParts: const [],
      runStreak: 0,
      totalCoinsEarned: earned,
    );

void main() {
  group('Pagar una continuación con monedas', () {
    test('baja el saldo pero NO lo ganado (la billetera lo refleja como gasto)',
        () async {
      // Jugador con 400 monedas, todas ganadas jugando.
      final repo = WalletRepositoryImpl(_FakeDatasource(_wallet(coins: 400, earned: 400)));

      // Coste de la 1.ª continuación: 100 monedas.
      final after = await repo.spendCoins(100);

      expect(after.coins, 300, reason: 'El saldo baja por el coste del revive.');
      expect(after.totalCoinsEarned, 400,
          reason: 'Lo ganado de por vida no se toca al gastar.');
      // Identidad de la billetera: gastado = ganado − saldo.
      expect(after.totalCoinsEarned - after.coins, 100,
          reason: 'Los 100 pagados aparecen como "gastado".');
    });

    test('no gasta si no alcanza el saldo (guarda anti-negativo)', () async {
      final repo = WalletRepositoryImpl(_FakeDatasource(_wallet(coins: 50, earned: 200)));

      final after = await repo.spendCoins(100);

      expect(after.coins, 50, reason: 'Sin saldo suficiente, no se descuenta.');
      expect(after.totalCoinsEarned, 200);
    });
  });
}
