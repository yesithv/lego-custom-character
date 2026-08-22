import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/monetization/data/datasources/store_local_datasource.dart';
import 'package:run_for_win/features/monetization/data/models/entitlements_model.dart';
import 'package:run_for_win/features/monetization/data/repositories/stub_store_repository.dart';
import 'package:run_for_win/features/monetization/domain/entities/store_product.dart';
import 'package:run_for_win/features/monetization/domain/entities/vip_perks.dart';

class _FakeStoreDs implements StoreLocalDatasource {
  EntitlementsModel model;
  _FakeStoreDs(this.model);
  @override
  EntitlementsModel get() => model;
  @override
  Future<void> save(EntitlementsModel m) async => model = m;
}

EntitlementsModel _ent({
  int gems = 0,
  int earned = 0,
  bool subscriptionActive = false,
  List<String> owned = const [],
  DateTime? lastVipClaim,
}) =>
    EntitlementsModel(
      gems: gems,
      adsRemoved: false,
      subscriptionActive: subscriptionActive,
      ownedProductIds: List.of(owned),
      totalGemsEarned: earned,
      lastVipClaimMs: lastVipClaim?.millisecondsSinceEpoch,
    );

StubStoreRepository _repo(EntitlementsModel m) =>
    StubStoreRepository(_FakeStoreDs(m));

StoreProduct _product(String id) =>
    storeCatalog.firstWhere((p) => p.id == id);

void main() {
  group('buy', () {
    test('paquete de gemas acredita gemas y ganado', () async {
      final repo = _repo(_ent(gems: 0, earned: 0));
      final small = _product('gems_small'); // 200 gemas
      final r = await repo.buy(small);
      expect(r.success, isTrue);
      expect(r.entitlements.gems, small.gemAmount);
      expect(r.entitlements.totalGemsEarned, small.gemAmount);
    });

    test('las gemas (consumible) se pueden comprar más de una vez', () async {
      final repo = _repo(_ent());
      final small = _product('gems_small');
      await repo.buy(small);
      final r = await repo.buy(small);
      expect(r.success, isTrue);
      expect(r.entitlements.gems, small.gemAmount * 2);
    });

    test('suscripción activa el VIP y queda poseída', () async {
      final repo = _repo(_ent());
      final r = await repo.buy(_product('vip_monthly'));
      expect(r.success, isTrue);
      expect(r.entitlements.subscriptionActive, isTrue);
      expect(r.entitlements.owns('vip_monthly'), isTrue);
    });

    test('no se puede recomprar un no-consumible ya poseído', () async {
      final repo = _repo(_ent(subscriptionActive: true, owned: ['vip_monthly']));
      final r = await repo.buy(_product('vip_monthly'));
      expect(r.success, isFalse);
      expect(r.error, isNotNull);
    });

    test('pack de bienvenida concede sus gemas y queda poseído', () async {
      final repo = _repo(_ent());
      final bundle = _product('bundle_starter'); // 150 gemas
      final r = await repo.buy(bundle);
      expect(r.success, isTrue);
      expect(r.entitlements.gems, bundle.gemAmount);
      expect(r.entitlements.owns('bundle_starter'), isTrue);
    });
  });

  group('spendGems', () {
    test('gasta cuando hay saldo', () async {
      final repo = _repo(_ent(gems: 100, earned: 100));
      final r = await repo.spendGems(30);
      expect(r.success, isTrue);
      expect(r.entitlements.gems, 70);
      expect(r.entitlements.gemsSpent, 30);
    });

    test('falla y no descuenta sin saldo', () async {
      final repo = _repo(_ent(gems: 10, earned: 10));
      final r = await repo.spendGems(30);
      expect(r.success, isFalse);
      expect(r.entitlements.gems, 10);
    });
  });

  group('grantGems (faucet)', () {
    test('suma gemas y ganado', () async {
      final repo = _repo(_ent(gems: 5, earned: 5));
      final e = await repo.grantGems(20);
      expect(e.gems, 25);
      expect(e.totalGemsEarned, 25);
    });

    test('grantGems(0) no cambia nada', () async {
      final repo = _repo(_ent(gems: 5, earned: 5));
      final e = await repo.grantGems(0);
      expect(e.gems, 5);
    });
  });

  group('claimVipDaily', () {
    test('sin VIP no otorga nada', () async {
      final repo = _repo(_ent(subscriptionActive: false));
      final r = await repo.claimVipDaily();
      expect(r.gemsGranted, 0);
    });

    test('VIP que nunca reclamó recibe las gemas diarias', () async {
      final repo = _repo(_ent(subscriptionActive: true));
      final r = await repo.claimVipDaily();
      expect(r.gemsGranted, VipPerks.dailyGems);
      expect(r.entitlements.gems, VipPerks.dailyGems);
    });

    test('VIP que ya reclamó hoy no recibe de nuevo', () async {
      final repo = _repo(
        _ent(subscriptionActive: true, lastVipClaim: DateTime.now()),
      );
      final r = await repo.claimVipDaily();
      expect(r.gemsGranted, 0);
    });
  });
}
