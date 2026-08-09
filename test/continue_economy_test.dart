import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/economy/data/datasources/wallet_local_datasource.dart';
import 'package:run_for_win/features/economy/data/models/wallet_model.dart';
import 'package:run_for_win/features/economy/data/repositories/wallet_repository_impl.dart';
import 'package:run_for_win/features/monetization/data/datasources/store_local_datasource.dart';
import 'package:run_for_win/features/monetization/data/models/entitlements_model.dart';
import 'package:run_for_win/features/monetization/data/repositories/stub_store_repository.dart';
import 'package:run_for_win/features/runner/domain/entities/continue_cost.dart';

/// Contabilidad de la economía al **retomar la carrera pagando** (revive).
///
/// Modela la secuencia EXACTA de operaciones que hace `RunnerPage`:
///  - al morir se **abona** a la billetera el delta de monedas recogidas en la
///    carrera aún no abonadas (`earnCoins`), para que cuenten como saldo
///    gastable al revivir;
///  - revivir **gasta** del saldo (`spendCoins`/`spendGems`);
///  - al terminar la carrera se acredita solo el **remanente** no abonado
///    (`recordRunCompletion`), sin doble conteo.
///
/// Patrón de fakes en memoria como en `reward_pools_test`/`continue_wallet_test`.

// ── Billetera (monedas) ──────────────────────────────────────────────────────
class _FakeWalletDs implements WalletLocalDatasource {
  WalletModel model;
  _FakeWalletDs(this.model);
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

// ── Entitlements (gemas) ─────────────────────────────────────────────────────
class _FakeStoreDs implements StoreLocalDatasource {
  EntitlementsModel model;
  _FakeStoreDs(this.model);
  @override
  EntitlementsModel get() => model;
  @override
  Future<void> save(EntitlementsModel m) async => model = m;
}

EntitlementsModel _entitlements({required int gems, required int earned}) =>
    EntitlementsModel(
      gems: gems,
      adsRemoved: false,
      subscriptionActive: false,
      ownedProductIds: [],
      totalGemsEarned: earned,
    );

/// ¿Le alcanza al jugador el saldo `coins` para pagar `offer`? (misma lógica que
/// `_ContinueOverlay._affordable` para la rama de monedas).
bool affordableCoins(int coins, ContinueOffer offer) => coins >= offer.amount;

void main() {
  group('Revive: las monedas de la carrera se abonan y son gastables', () {
    test('recoger en carrera hace el revive asequible; el gasto se refleja',
        () async {
      // Saldo previo 50; el jugador recoge 80 en la carrera.
      final repo = WalletRepositoryImpl(_FakeWalletDs(_wallet(coins: 50, earned: 50)));
      final offer = continueOfferFor(0); // 1.ª continuación: 100 monedas

      // Antes de abonar, con solo el saldo previo NO alcanzaría.
      expect(affordableCoins(50, offer), isFalse,
          reason: '50 < 100: sin las monedas de la carrera no llega.');

      // Al morir se abonan las 80 recogidas.
      var w = await repo.earnCoins(80);
      expect(w.coins, 130);
      expect(w.totalCoinsEarned, 130);
      expect(affordableCoins(w.coins, offer), isTrue,
          reason: 'Con billetera + carrera (130) ya alcanza los 100.');

      // Revivir gasta el coste.
      w = await repo.spendCoins(offer.amount);
      expect(w.coins, 30, reason: '130 − 100 = 30.');
      expect(w.totalCoinsEarned, 130,
          reason: 'Gastar no baja lo ganado de por vida.');
      expect(w.totalCoinsEarned - w.coins, 100,
          reason: 'gastado = ganado − saldo = lo pagado por revivir.');
    });
  });

  group('Revive: sin doble conteo al terminar la carrera', () {
    test('el remanente se acredita una sola vez', () async {
      // Saldo previo 50. Carrera: recoge 80 → muere → abona 80 (banked=80) →
      // revive (−100) → recoge 20 más (total carrera 100) → termina.
      final repo = WalletRepositoryImpl(_FakeWalletDs(_wallet(coins: 50, earned: 50)));

      await repo.earnCoins(80); // abono al morir (delta 80)
      const banked = 80;
      await repo.spendCoins(100); // revive

      // Al terminar: total recogido en la carrera = 100; ya se abonaron 80.
      const raceCoinsTotal = 100;
      final remainder = raceCoinsTotal - banked; // 20
      final w = await repo.recordRunCompletion(remainder);

      expect(w.coins, 50, reason: 'Saldo = 50 inicial + 100 recogidas − 100 gastadas.');
      expect(w.totalCoinsEarned, 150,
          reason: 'Ganado = 50 inicial + 100 de la carrera (80 + 20), una vez.');
    });
  });

  group('Revive: saldo insuficiente', () {
    test('sin monedas de carrera y saldo bajo, no alcanza ni se descuenta',
        () async {
      // Reproduce la 1.ª carrera del usuario: 90 de saldo, recoge 0.
      final repo = WalletRepositoryImpl(_FakeWalletDs(_wallet(coins: 90, earned: 90)));
      final offer = continueOfferFor(0); // 100 monedas

      expect(affordableCoins(90, offer), isFalse, reason: '90 < 100.');

      // Aun si se intentara gastar, la guarda anti-negativo lo impide.
      final w = await repo.spendCoins(offer.amount);
      expect(w.coins, 90, reason: 'No se descuenta sin saldo suficiente.');
      expect(w.totalCoinsEarned, 90);
    });
  });

  group('Revive: la racha se actualiza una vez al terminar', () {
    test('recordRunCompletion(0) tras abonar todo aún cierra la carrera', () async {
      final repo = WalletRepositoryImpl(_FakeWalletDs(_wallet(coins: 0, earned: 0)));

      // Todas las monedas de la carrera se abonaron a mitad; remanente 0.
      final w = await repo.recordRunCompletion(0);

      expect(w.runStreak, 1, reason: 'Primera carrera: racha pasa a 1.');
      expect(w.lastPlayDate, isNotNull);
    });
  });

  group('Revive con gemas (paridad de contabilidad)', () {
    test('spendGems baja el saldo pero no lo ganado; refleja el gasto', () async {
      final store = StubStoreRepository(
          _FakeStoreDs(_entitlements(gems: 60, earned: 60)));
      final offer = continueOfferFor(2); // 3.ª continuación: 20 gemas

      expect(offer.isGems, isTrue);
      final r = await store.spendGems(offer.amount);

      expect(r.success, isTrue);
      expect(r.entitlements.gems, 40, reason: '60 − 20 = 40.');
      expect(r.entitlements.totalGemsEarned, 60,
          reason: 'Gastar gemas no baja lo ganado.');
      expect(r.entitlements.gemsSpent, 20,
          reason: 'gemsSpent = ganado − saldo = lo pagado por revivir.');
    });

    test('sin gemas suficientes, spendGems falla y no descuenta', () async {
      final store = StubStoreRepository(
          _FakeStoreDs(_entitlements(gems: 10, earned: 10)));

      final r = await store.spendGems(20);

      expect(r.success, isFalse);
      expect(r.entitlements.gems, 10, reason: 'No se descuenta sin saldo.');
    });
  });
}
