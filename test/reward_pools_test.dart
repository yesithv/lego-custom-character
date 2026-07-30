import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/economy/data/datasources/wallet_local_datasource.dart';
import 'package:run_for_win/features/economy/data/models/wallet_model.dart';
import 'package:run_for_win/features/economy/data/repositories/wallet_repository_impl.dart';
import 'package:run_for_win/features/economy/domain/entities/part_catalog.dart';
import 'package:run_for_win/features/economy/domain/entities/reward.dart';
import 'package:run_for_win/features/economy/domain/entities/reward_pools.dart';

/// Datasource en memoria: reemplaza a Hive para poder probar la lógica de
/// premios sin abrir cajas ni tocar disco.
class _FakeDatasource implements WalletLocalDatasource {
  WalletModel model;
  _FakeDatasource(this.model);

  @override
  WalletModel getWallet() => model;

  @override
  Future<void> saveWallet(WalletModel m) async => model = m;
}

WalletModel _emptyWallet({List<String>? parts}) => WalletModel(
      coins: 0,
      unlockedParts: parts ?? [],
      runStreak: 0,
      totalCoinsEarned: 0,
    );

void main() {
  final allTables = <String, List<WeightedReward>>{
    'ruleta': roulettePrizeTable,
    'cofre común': commonChestPrizeTable,
    'cofre VIP': vipChestPrizeTable,
  };

  group('Integridad de las tablas de premios', () {
    test('todo premio de accesorio existe en el catálogo (es equipable)', () {
      for (final entry in allTables.entries) {
        for (final w in entry.value) {
          final prize = w.prize;
          if (prize is PartReward) {
            expect(
              partCatalog.containsKey(prize.partId),
              isTrue,
              reason:
                  'En "${entry.key}" el premio "${prize.partId}" no existe en '
                  'partCatalog → no se podría equipar.',
            );
          }
        }
      }
    });

    test('nombre y rareza del premio coinciden con el catálogo', () {
      for (final table in allTables.values) {
        for (final w in table) {
          final prize = w.prize;
          if (prize is PartReward) {
            final cat = partCatalog[prize.partId]!;
            expect(prize.partName, cat.name);
            expect(prize.rarity, cat.rarity);
          }
        }
      }
    });

    test('ningún premio es un accesorio premium (exclusivo de la Tienda)', () {
      for (final table in allTables.values) {
        for (final w in table) {
          final prize = w.prize;
          if (prize is PartReward) {
            expect(partCatalog[prize.partId]!.premium, isFalse);
          }
        }
      }
    });

    test('todas las tablas tienen pesos positivos y al menos un accesorio', () {
      for (final entry in allTables.entries) {
        final table = entry.value;
        expect(table, isNotEmpty, reason: entry.key);
        expect(table.every((w) => w.weight > 0), isTrue, reason: entry.key);
        expect(
          table.any((w) => w.prize is PartReward),
          isTrue,
          reason: 'La tabla "${entry.key}" no reparte ningún accesorio.',
        );
      }
    });
  });

  group('Escalabilidad (el pool se deriva del catálogo)', () {
    test('droppableAccessories = no premium y no gratis', () {
      final pool = droppableAccessories.toList();
      expect(pool, isNotEmpty);
      for (final e in pool) {
        expect(e.premium, isFalse);
        expect(e.isFree, isFalse);
        expect(partCatalog.containsKey(e.id), isTrue);
      }
    });

    test('todo accesorio no-premium y no-gratis del catálogo puede caer', () {
      // Garantía de escalabilidad: si mañana agregamos un accesorio rare/epic
      // al catálogo, entra solo al reparto de la ruleta o los cofres.
      final droppableIds = droppableAccessories.map((e) => e.id).toSet();
      final prizeIds = allTables.values
          .expand((t) => t)
          .map((w) => w.prize)
          .whereType<PartReward>()
          .map((p) => p.partId)
          .toSet();
      expect(
        droppableIds.difference(prizeIds),
        isEmpty,
        reason: 'Estos accesorios del catálogo no salen en ninguna tabla: '
            '${droppableIds.difference(prizeIds)}',
      );
    });

    test('partRewardFromCatalog sincroniza con el catálogo y valida el id', () {
      final r = partRewardFromCatalog('jetpack');
      expect(r.partId, 'jetpack');
      expect(r.partName, partCatalog['jetpack']!.name);
      expect(r.rarity, partCatalog['jetpack']!.rarity);

      expect(
        () => partRewardFromCatalog('id_que_no_existe'),
        throwsArgumentError,
      );
    });
  });

  group('Un premio ganado es siempre útil', () {
    test('un accesorio ganado se agrega a unlockedParts y existe en catálogo',
        () async {
      final repo = WalletRepositoryImpl(_FakeDatasource(_emptyWallet()));
      var gotAccessory = false;
      for (var i = 0; i < 400; i++) {
        final res = await repo.openChest(isVip: true);
        if (res.reward is PartReward) {
          gotAccessory = true;
          final id = (res.reward as PartReward).partId;
          expect(partCatalog.containsKey(id), isTrue);
          expect(res.wallet.unlockedParts, contains(id));
        }
      }
      expect(gotAccessory, isTrue,
          reason: 'En 400 aperturas VIP nunca cayó un accesorio.');
    });

    test('accesorio duplicado se convierte en monedas (nunca premio vacío)',
        () async {
      // El jugador ya posee TODOS los accesorios que pueden caer.
      final owned = droppableAccessories.map((e) => e.id).toList();
      final ds = _FakeDatasource(_emptyWallet(parts: owned));
      final repo = WalletRepositoryImpl(ds);

      for (var i = 0; i < 200; i++) {
        final before = ds.model.coins;
        final res = await repo.openChest(isVip: true);
        // Todo premio es monedas: nunca un accesorio repetido inservible.
        expect(res.reward, isA<CoinsReward>());
        // El saldo sube y no se añaden piezas nuevas.
        expect(res.wallet.coins, greaterThan(before));
        expect(res.wallet.unlockedParts.length, owned.length);
      }
    });
  });
}
