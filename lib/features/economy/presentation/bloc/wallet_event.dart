import 'package:equatable/equatable.dart';

sealed class WalletEvent extends Equatable {
  const WalletEvent();
  @override
  List<Object?> get props => [];
}

class LoadWallet extends WalletEvent {
  const LoadWallet();
}

class EarnCoinsEvent extends WalletEvent {
  final int amount;
  const EarnCoinsEvent(this.amount);
  @override
  List<Object?> get props => [amount];
}

class SpendCoinsEvent extends WalletEvent {
  final int amount;
  const SpendCoinsEvent(this.amount);
  @override
  List<Object?> get props => [amount];
}

class ClaimRouletteEvent extends WalletEvent {
  const ClaimRouletteEvent();
}

class OpenChestEvent extends WalletEvent {
  final bool isVip;
  const OpenChestEvent({this.isVip = false});
  @override
  List<Object?> get props => [isVip];
}

class RecordRunEvent extends WalletEvent {
  final int coinsEarned;
  const RecordRunEvent(this.coinsEarned);
  @override
  List<Object?> get props => [coinsEarned];
}

class UnlockPartEvent extends WalletEvent {
  final String partId;
  final int cost;
  const UnlockPartEvent({required this.partId, required this.cost});
  @override
  List<Object?> get props => [partId, cost];
}
