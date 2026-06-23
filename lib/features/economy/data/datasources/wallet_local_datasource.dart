import 'package:hive/hive.dart';

import '../models/wallet_model.dart';

abstract class WalletLocalDatasource {
  WalletModel getWallet();
  Future<void> saveWallet(WalletModel model);
}

const _walletKey = 'wallet';

class WalletLocalDatasourceImpl implements WalletLocalDatasource {
  final Box<WalletModel> _box;
  WalletLocalDatasourceImpl(this._box);

  @override
  WalletModel getWallet() =>
      _box.get(_walletKey) ??
      WalletModel(
        coins: 0,
        unlockedParts: [],
        runStreak: 0,
        totalCoinsEarned: 0,
      );

  @override
  Future<void> saveWallet(WalletModel model) => _box.put(_walletKey, model);
}
