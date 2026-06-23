import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/claim_daily_roulette.dart';
import '../../domain/usecases/earn_coins.dart';
import '../../domain/usecases/open_chest.dart';
import '../../domain/usecases/record_run.dart';
import '../../domain/repositories/wallet_repository.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository repository;
  final EarnCoins earnCoins;
  final ClaimDailyRoulette claimDailyRoulette;
  final OpenChest openChest;
  final RecordRun recordRun;

  WalletBloc({
    required this.repository,
    required this.earnCoins,
    required this.claimDailyRoulette,
    required this.openChest,
    required this.recordRun,
  }) : super(const WalletState()) {
    on<LoadWallet>(_onLoad);
    on<EarnCoinsEvent>(_onEarnCoins);
    on<SpendCoinsEvent>(_onSpendCoins);
    on<ClaimRouletteEvent>(_onClaimRoulette);
    on<OpenChestEvent>(_onOpenChest);
    on<RecordRunEvent>(_onRecordRun);
  }

  Future<void> _onLoad(LoadWallet _, Emitter<WalletState> emit) async {
    emit(state.copyWith(status: WalletStatus.loading));
    final wallet = await repository.getWallet();
    emit(state.copyWith(status: WalletStatus.ready, wallet: wallet));
  }

  Future<void> _onEarnCoins(
      EarnCoinsEvent event, Emitter<WalletState> emit) async {
    final wallet = await earnCoins(event.amount);
    emit(state.copyWith(wallet: wallet));
  }

  Future<void> _onSpendCoins(
      SpendCoinsEvent event, Emitter<WalletState> emit) async {
    final wallet = await repository.spendCoins(event.amount);
    emit(state.copyWith(wallet: wallet));
  }

  Future<void> _onClaimRoulette(
      ClaimRouletteEvent _, Emitter<WalletState> emit) async {
    emit(state.copyWith(status: WalletStatus.claiming));
    final result = await claimDailyRoulette();
    if (result.alreadyClaimed) {
      emit(state.copyWith(status: WalletStatus.ready));
      return;
    }
    emit(state.copyWith(
      status: WalletStatus.ready,
      wallet: result.wallet,
      lastReward: result.reward,
      showRewardDialog: true,
    ));
  }

  Future<void> _onOpenChest(
      OpenChestEvent event, Emitter<WalletState> emit) async {
    emit(state.copyWith(status: WalletStatus.chestOpening));
    final result = await openChest(isVip: event.isVip);
    emit(state.copyWith(
      status: WalletStatus.ready,
      wallet: result.wallet,
      lastReward: result.reward,
      showRewardDialog: true,
    ));
  }

  Future<void> _onRecordRun(
      RecordRunEvent event, Emitter<WalletState> emit) async {
    final wallet = await recordRun(event.coinsEarned);
    emit(state.copyWith(wallet: wallet));
  }
}
