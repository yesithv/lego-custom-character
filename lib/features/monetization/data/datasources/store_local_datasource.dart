import 'package:hive/hive.dart';

import '../models/entitlements_model.dart';

abstract class StoreLocalDatasource {
  EntitlementsModel get();
  Future<void> save(EntitlementsModel model);
}

const _entitlementsKey = 'entitlements';

class StoreLocalDatasourceImpl implements StoreLocalDatasource {
  final Box<EntitlementsModel> _box;
  StoreLocalDatasourceImpl(this._box);

  @override
  EntitlementsModel get() =>
      _box.get(_entitlementsKey) ??
      EntitlementsModel(
        gems: 0,
        adsRemoved: false,
        subscriptionActive: false,
        ownedProductIds: [],
      );

  @override
  Future<void> save(EntitlementsModel model) =>
      _box.put(_entitlementsKey, model);
}
