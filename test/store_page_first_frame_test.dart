import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/core/di/injection.dart';
import 'package:run_for_win/features/analytics/domain/analytics_service.dart';
import 'package:run_for_win/features/analytics/domain/entities/analytics_event.dart';
import 'package:run_for_win/features/analytics/domain/entities/analytics_summary.dart';
import 'package:run_for_win/features/monetization/domain/entities/entitlements.dart';
import 'package:run_for_win/features/monetization/domain/entities/store_product.dart';
import 'package:run_for_win/features/monetization/domain/repositories/store_repository.dart';
import 'package:run_for_win/features/monetization/presentation/pages/store_page.dart';

/// Tienda de mentira cuya consulta de precios **tarda**, como la de verdad: un
/// `queryProductDetails` contra Google Play / StoreKit son uno a tres segundos.
/// Es justo esa espera la que antes se comía la pantalla entera.
class _SlowStore implements StoreRepository {
  /// Lo que tarda la tienda de la plataforma en devolver precios.
  static const priceDelay = Duration(seconds: 2);

  final Entitlements _ent = const Entitlements(gems: 40);
  int priceCalls = 0;

  @override
  Entitlements entitlementsSync() => _ent;

  @override
  Future<Entitlements> getEntitlements() async => _ent;

  @override
  Future<Map<String, String>> loadPrices(Set<String> ids) async {
    priceCalls++;
    await Future<void>.delayed(priceDelay);
    return {for (final id in ids) id: 'REAL-$id'};
  }

  @override
  Future<PurchaseResult> buy(StoreProduct product) async =>
      PurchaseResult(success: false, entitlements: _ent);

  @override
  Future<Entitlements> restorePurchases() async => _ent;

  @override
  Future<({Entitlements entitlements, int gemsGranted})> claimVipDaily() async =>
      (entitlements: _ent, gemsGranted: 0);

  @override
  Future<({Entitlements entitlements, bool success})> spendGems(int a) async =>
      (entitlements: _ent, success: false);

  @override
  Future<Entitlements> grantGems(int amount) async => _ent;
}

class _NoopAnalytics implements AnalyticsService {
  @override
  void startSession() {}
  @override
  void track(String event, {Map<String, Object?>? params}) {}
  @override
  Future<AnalyticsSummary> getSummary() async => const AnalyticsSummary(
        totalEvents: 0,
        sessions: 0,
        eventCounts: {},
        firstOpen: null,
        lastActive: null,
        activeDays: 0,
        retainedD1: false,
        retainedD7: false,
      );
  @override
  Future<List<AnalyticsEvent>> recentEvents({int limit = 50}) async => const [];
  @override
  Future<void> clear() async {}
}

void main() {
  late _SlowStore store;

  setUp(() {
    store = _SlowStore();
    sl.registerSingleton<StoreRepository>(store);
    sl.registerSingleton<AnalyticsService>(_NoopAnalytics());
  });

  tearDown(() => sl.reset());

  /// Monta la Tienda en un lienzo alto para que el `ListView` construya TODAS
  /// las tarjetas del catálogo: en el tamaño de prueba por defecto las últimas
  /// quedan fuera de pantalla y el `ListView` perezoso ni las crea.
  Future<void> pumpStore(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: StorePage()));
  }

  testWidgets('el catálogo está completo en el PRIMER frame', (tester) async {
    await pumpStore(tester);

    // Sin bombear nada más: la tienda de la plataforma sigue sin contestar.
    expect(find.byType(CircularProgressIndicator), findsNothing,
        reason: 'esperar a los precios no puede tapar la pantalla');
    for (final p in storeCatalog) {
      expect(find.text(p.priceLabel), findsOneWidget,
          reason: 'el precio de relleno de ${p.id} debe verse ya');
    }

    await tester.pump(const Duration(seconds: 3)); // deja resolver el Future
  });

  testWidgets('los precios reales sustituyen a los de relleno al llegar',
      (tester) async {
    await pumpStore(tester);
    final sample = storeCatalog.first;
    expect(find.text(sample.priceLabel), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));

    expect(find.text('REAL-${sample.id}'), findsOneWidget);
    expect(find.text(sample.priceLabel), findsNothing);
  });

  testWidgets('si la tienda nunca responde, se queda con los de relleno',
      (tester) async {
    await pumpStore(tester);
    await tester.pump(const Duration(milliseconds: 500));

    // A media espera la pantalla sigue completa y usable.
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(storeCatalog.first.priceLabel), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('los precios se piden una sola vez por apertura', (tester) async {
    await pumpStore(tester);
    await tester.pump(const Duration(seconds: 3));
    expect(store.priceCalls, 1);
  });
}
