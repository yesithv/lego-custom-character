import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:run_for_win/features/monetization/data/datasources/store_local_datasource.dart';
import 'package:run_for_win/features/monetization/data/models/entitlements_model.dart';
import 'package:run_for_win/features/monetization/data/repositories/in_app_purchase_store_repository.dart';

class _FakeStoreDs implements StoreLocalDatasource {
  EntitlementsModel model = EntitlementsModel(
    gems: 0,
    adsRemoved: false,
    subscriptionActive: false,
    ownedProductIds: const [],
    totalGemsEarned: 0,
  );
  @override
  EntitlementsModel get() => model;
  @override
  Future<void> save(EntitlementsModel m) async => model = m;
}

/// Doble de la tienda de la plataforma que **cuenta los viajes**. Es lo que se
/// está midiendo: cada `queryProductDetails` real es 1-3 s contra Google Play /
/// StoreKit, y el objetivo del cambio es que ocurra una sola vez por sesión.
class _FakeIap extends Fake implements InAppPurchase {
  _FakeIap({this.available = true, this.knownIds = const {}});

  bool available;
  Set<String> knownIds;

  int availabilityChecks = 0;
  int queries = 0;
  final List<Set<String>> queriedIds = [];

  final _purchases = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _purchases.stream;

  @override
  Future<bool> isAvailable() async {
    availabilityChecks++;
    return available;
  }

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async {
    queries++;
    queriedIds.add(Set.of(ids));
    return ProductDetailsResponse(
      productDetails: [
        for (final id in ids)
          if (knownIds.contains(id))
            ProductDetails(
              id: id,
              title: id,
              description: id,
              price: '\$$id',
              rawPrice: 1.0,
              currencyCode: 'USD',
            ),
      ],
      notFoundIDs: ids.difference(knownIds).toList(),
    );
  }

  void dispose() => _purchases.close();
}

void main() {
  late _FakeIap iap;
  late InAppPurchaseStoreRepository repo;

  void build({bool available = true, Set<String> known = const {'a', 'b'}}) {
    iap = _FakeIap(available: available, knownIds: known);
    repo = InAppPurchaseStoreRepository(_FakeStoreDs(), iap: iap);
  }

  tearDown(() {
    repo.dispose();
    iap.dispose();
  });

  group('Los precios se piden a la tienda una sola vez', () {
    test('la segunda consulta no vuelve a viajar a la tienda', () async {
      build();
      final first = await repo.loadPrices({'a', 'b'});
      final second = await repo.loadPrices({'a', 'b'});

      expect(iap.queries, 1, reason: 'la segunda apertura sale de la caché');
      expect(second, first, reason: 'y devuelve exactamente lo mismo');
      expect(first, {'a': '\$a', 'b': '\$b'});
    });

    test('solo se preguntan los ids que faltan', () async {
      build(known: {'a', 'b', 'c'});
      await repo.loadPrices({'a'});
      await repo.loadPrices({'a', 'b', 'c'});

      expect(iap.queries, 2);
      expect(iap.queriedIds[0], {'a'});
      expect(iap.queriedIds[1], {'b', 'c'},
          reason: 'el id ya cacheado no se vuelve a pedir');
    });

    test('un id que la tienda no reconoce no se reintenta', () async {
      // Un producto sin dar de alta en la consola no va a aparecer por
      // insistir, y reintentarlo costaría el viaje completo cada vez.
      build(known: {'a'});
      final first = await repo.loadPrices({'a', 'fantasma'});
      expect(first, {'a': '\$a'});

      await repo.loadPrices({'a', 'fantasma'});
      expect(iap.queries, 1);
    });

    test('cada llamada devuelve solo los ids pedidos', () async {
      build(known: {'a', 'b'});
      await repo.loadPrices({'a', 'b'});
      expect(await repo.loadPrices({'b'}), {'b': '\$b'});
    });
  });

  group('Cuando la tienda no está disponible', () {
    test('no se cachea el fallo: la siguiente apertura reintenta', () async {
      // Sin red o con la tienda aún inicializando, callarse para siempre
      // dejaría los precios de relleno hasta reiniciar la app.
      build(available: false);
      expect(await repo.loadPrices({'a'}), isEmpty);
      expect(iap.queries, 0, reason: 'ni se intenta consultar');

      iap.available = true;
      expect(await repo.loadPrices({'a'}), {'a': '\$a'});
      expect(iap.queries, 1);
    });

    test('tras recuperarse, sigue cacheando con normalidad', () async {
      build(available: false);
      await repo.loadPrices({'a'});
      iap.available = true;
      await repo.loadPrices({'a'});
      await repo.loadPrices({'a'});

      expect(iap.queries, 1);
    });
  });

  group('Sin ids pendientes no se toca la tienda', () {
    test('un conjunto vacío no dispara ni la comprobación de disponibilidad',
        () async {
      build();
      expect(await repo.loadPrices({}), isEmpty);
      expect(iap.availabilityChecks, 0);
      expect(iap.queries, 0);
    });
  });
}
