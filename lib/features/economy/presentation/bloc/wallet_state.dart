import 'package:equatable/equatable.dart';

import '../../domain/entities/reward.dart';
import '../../domain/entities/wallet.dart';

enum WalletStatus { initial, loading, ready, claiming, chestOpening, error }

class WalletState extends Equatable {
  final WalletStatus status;
  final Wallet wallet;
  final Reward? lastReward;
  final bool showRewardDialog;

  const WalletState({
    this.status = WalletStatus.initial,
    this.wallet = const Wallet(),
    this.lastReward,
    this.showRewardDialog = false,
  });

  WalletState copyWith({
    WalletStatus? status,
    Wallet? wallet,
    Reward? lastReward,
    bool? showRewardDialog,
  }) =>
      WalletState(
        status: status ?? this.status,
        wallet: wallet ?? this.wallet,
        lastReward: lastReward ?? this.lastReward,
        showRewardDialog: showRewardDialog ?? this.showRewardDialog,
      );

  @override
  List<Object?> get props =>
      [status, wallet, lastReward, showRewardDialog];
}
