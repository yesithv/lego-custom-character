import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/economy/data/datasources/wallet_local_datasource.dart';
import 'package:run_for_win/features/economy/data/models/wallet_model.dart';
import 'package:run_for_win/features/economy/data/repositories/wallet_repository_impl.dart';
import 'package:run_for_win/features/economy/domain/usecases/claim_daily_roulette.dart';
import 'package:run_for_win/features/economy/domain/usecases/earn_coins.dart';
import 'package:run_for_win/features/economy/domain/usecases/open_chest.dart';
import 'package:run_for_win/features/economy/domain/usecases/record_run.dart';
import 'package:run_for_win/features/economy/domain/usecases/unlock_part.dart';
import 'package:run_for_win/features/economy/presentation/bloc/wallet_bloc.dart';
import 'package:run_for_win/features/economy/presentation/bloc/wallet_event.dart';
import 'package:run_for_win/features/economy/presentation/bloc/wallet_state.dart';

class _FakeWalletDs implements WalletLocalDatasource {
  WalletModel model;
  _FakeWalletDs(this.model);
  @override
  WalletModel getWallet() => model;
  @override
  Future<void> saveWallet(WalletModel m) async => model = m;
}

WalletModel _wallet({
  int coins = 0,
  int earned = 0,
  List<String> unlockedParts = const [],
  DateTime? lastRouletteDate,
}) =>
    WalletModel(
      coins: coins,
      unlockedParts: List.of(unlockedParts),
      runStreak: 0,
      totalCoinsEarned: earned,
      lastRouletteDate: lastRouletteDate,
    );

/// Construye un WalletBloc sobre el repo real + un datasource fake en memoria,
/// de modo que se prueba toda la cadena bloc → usecase → repo → datasource.
WalletBloc _bloc(WalletModel seed) {
  final repo = WalletRepositoryImpl(_FakeWalletDs(seed));
  return WalletBloc(
    repository: repo,
    earnCoins: EarnCoins(repo),
    claimDailyRoulette: ClaimDailyRoulette(repo),
    openChest: OpenChest(repo),
    recordRun: RecordRun(repo),
    unlockPart: UnlockPart(repo),
  );
}

void main() {
  test('estado inicial', () {
    final b = _bloc(_wallet());
    expect(b.state, const WalletState());
    expect(b.state.status, WalletStatus.initial);
    b.close();
  });

  blocTest<WalletBloc, WalletState>(
    'LoadWallet emite loading y luego ready con el monedero',
    build: () => _bloc(_wallet(coins: 120, earned: 120)),
    act: (b) => b.add(const LoadWallet()),
    expect: () => [
      isA<WalletState>().having((s) => s.status, 'status', WalletStatus.loading),
      isA<WalletState>()
          .having((s) => s.status, 'status', WalletStatus.ready)
          .having((s) => s.wallet.coins, 'coins', 120),
    ],
  );

  blocTest<WalletBloc, WalletState>(
    'EarnCoinsEvent acredita monedas',
    build: () => _bloc(_wallet(coins: 100, earned: 100)),
    act: (b) => b.add(const EarnCoinsEvent(50)),
    expect: () => [
      isA<WalletState>()
          .having((s) => s.wallet.coins, 'coins', 150)
          .having((s) => s.wallet.totalCoinsEarned, 'earned', 150),
    ],
  );

  blocTest<WalletBloc, WalletState>(
    'SpendCoinsEvent descuenta cuando alcanza',
    build: () => _bloc(_wallet(coins: 100, earned: 100)),
    act: (b) => b.add(const SpendCoinsEvent(30)),
    expect: () => [
      isA<WalletState>().having((s) => s.wallet.coins, 'coins', 70),
    ],
  );

  blocTest<WalletBloc, WalletState>(
    'SpendCoinsEvent no descuenta si no alcanza',
    build: () => _bloc(_wallet(coins: 20, earned: 20)),
    act: (b) => b.add(const SpendCoinsEvent(50)),
    expect: () => [
      isA<WalletState>().having((s) => s.wallet.coins, 'coins', 20),
    ],
  );

  blocTest<WalletBloc, WalletState>(
    'UnlockPartEvent desbloquea y cobra',
    build: () => _bloc(_wallet(coins: 100)),
    act: (b) =>
        b.add(const UnlockPartEvent(partId: 'cape_red', cost: 60)),
    expect: () => [
      isA<WalletState>()
          .having((s) => s.wallet.coins, 'coins', 40)
          .having((s) => s.wallet.unlockedParts, 'parts', contains('cape_red')),
    ],
  );

  blocTest<WalletBloc, WalletState>(
    'UnlockPartEvent sin saldo no emite estado nuevo',
    build: () => _bloc(_wallet(coins: 10)),
    act: (b) =>
        b.add(const UnlockPartEvent(partId: 'cape_red', cost: 60)),
    expect: () => const <WalletState>[],
  );

  blocTest<WalletBloc, WalletState>(
    'RecordRunEvent acredita y sube la racha',
    build: () => _bloc(_wallet(coins: 0, earned: 0)),
    act: (b) => b.add(const RecordRunEvent(25)),
    expect: () => [
      isA<WalletState>()
          .having((s) => s.wallet.coins, 'coins', 25)
          .having((s) => s.wallet.runStreak, 'streak', 1),
    ],
  );

  blocTest<WalletBloc, WalletState>(
    'ClaimRouletteEvent (primer giro del día) entrega premio y abre diálogo',
    build: () => _bloc(_wallet(coins: 0)),
    act: (b) => b.add(const ClaimRouletteEvent()),
    expect: () => [
      isA<WalletState>()
          .having((s) => s.status, 'status', WalletStatus.claiming),
      isA<WalletState>()
          .having((s) => s.status, 'status', WalletStatus.ready)
          .having((s) => s.showRewardDialog, 'showRewardDialog', true)
          .having((s) => s.lastReward, 'lastReward', isNotNull),
    ],
  );

  blocTest<WalletBloc, WalletState>(
    'ClaimRouletteEvent ya reclamado hoy: vuelve a ready sin premio',
    build: () => _bloc(_wallet(coins: 0, lastRouletteDate: DateTime.now())),
    act: (b) => b.add(const ClaimRouletteEvent()),
    expect: () => [
      isA<WalletState>()
          .having((s) => s.status, 'status', WalletStatus.claiming),
      isA<WalletState>()
          .having((s) => s.status, 'status', WalletStatus.ready)
          .having((s) => s.showRewardDialog, 'showRewardDialog', false),
    ],
  );

  blocTest<WalletBloc, WalletState>(
    'OpenChestEvent entrega premio y abre diálogo',
    build: () => _bloc(_wallet(coins: 0)),
    act: (b) => b.add(const OpenChestEvent()),
    expect: () => [
      isA<WalletState>()
          .having((s) => s.status, 'status', WalletStatus.chestOpening),
      isA<WalletState>()
          .having((s) => s.status, 'status', WalletStatus.ready)
          .having((s) => s.showRewardDialog, 'showRewardDialog', true)
          .having((s) => s.lastReward, 'lastReward', isNotNull),
    ],
  );
}
