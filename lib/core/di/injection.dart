import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/character_editor/data/datasources/character_local_datasource.dart';
import '../../features/character_editor/data/models/character_model.dart';
import '../../features/character_editor/data/repositories/character_repository_impl.dart';
import '../../features/character_editor/domain/repositories/character_repository.dart';
import '../../features/character_editor/domain/usecases/delete_character.dart';
import '../../features/character_editor/domain/usecases/get_all_characters.dart';
import '../../features/character_editor/domain/usecases/save_character.dart';
import '../../features/analytics/data/datasources/analytics_local_datasource.dart';
import '../../features/analytics/data/local_analytics_service.dart';
import '../../features/analytics/data/models/analytics_event_model.dart';
import '../../features/analytics/domain/analytics_service.dart';
import '../../features/character_editor/presentation/bloc/character_editor_bloc.dart';
import '../../features/economy/data/datasources/wallet_local_datasource.dart';
import '../../features/economy/data/models/wallet_model.dart';
import '../../features/economy/data/repositories/wallet_repository_impl.dart';
import '../../features/economy/domain/repositories/wallet_repository.dart';
import '../../features/economy/domain/usecases/claim_daily_roulette.dart';
import '../../features/economy/domain/usecases/earn_coins.dart';
import '../../features/economy/domain/usecases/open_chest.dart';
import '../../features/economy/domain/usecases/record_run.dart';
import '../../features/economy/domain/usecases/unlock_part.dart';
import '../../features/economy/presentation/bloc/wallet_bloc.dart';
import '../../features/missions/data/datasources/mission_local_datasource.dart';
import '../../features/missions/data/repositories/mission_repository_impl.dart';
import '../../features/missions/domain/repositories/mission_repository.dart';
import '../../features/missions/presentation/bloc/mission_bloc.dart';
import '../../features/monetization/data/datasources/store_local_datasource.dart';
import '../../features/monetization/data/models/entitlements_model.dart';
import '../../features/monetization/data/repositories/stub_store_repository.dart';
import '../../features/monetization/domain/repositories/store_repository.dart';
import '../../features/ranking/data/models/score_model.dart';
import '../../features/ranking/data/repositories/score_local_repository.dart';
import '../../features/ranking/domain/repositories/score_repository.dart';
import '../../features/ranking/presentation/bloc/ranking_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(CharacterModelAdapter());
  Hive.registerAdapter(CharacterAppearanceModelAdapter());
  Hive.registerAdapter(WalletModelAdapter());
  Hive.registerAdapter(ScoreModelAdapter());
  Hive.registerAdapter(EntitlementsModelAdapter());
  Hive.registerAdapter(AnalyticsEventModelAdapter());

  // Open boxes
  await Hive.openBox<CharacterModel>('characters');
  await Hive.openBox<WalletModel>('wallet');
  await Hive.openBox<String>('missions');
  await Hive.openBox<ScoreModel>('scores');
  await Hive.openBox<EntitlementsModel>('entitlements');
  await Hive.openBox<AnalyticsEventModel>('analytics_events');
  await Hive.openBox<dynamic>('analytics_meta');

  // ── Character ─────────────────────────────────────────────────────────────
  sl.registerLazySingleton<CharacterLocalDatasource>(
    () => CharacterLocalDatasourceImpl(Hive.box('characters')),
  );
  sl.registerLazySingleton<CharacterRepository>(
    () => CharacterRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => SaveCharacter(sl()));
  sl.registerLazySingleton(() => GetAllCharacters(sl()));
  sl.registerLazySingleton(() => DeleteCharacter(sl()));
  sl.registerFactory(
    () => CharacterEditorBloc(
      saveCharacter: sl(),
      getAllCharacters: sl(),
      deleteCharacter: sl(),
    ),
  );

  // ── Economy ───────────────────────────────────────────────────────────────
  sl.registerLazySingleton<WalletLocalDatasource>(
    () => WalletLocalDatasourceImpl(Hive.box('wallet')),
  );
  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => EarnCoins(sl()));
  sl.registerLazySingleton(() => ClaimDailyRoulette(sl()));
  sl.registerLazySingleton(() => OpenChest(sl()));
  sl.registerLazySingleton(() => RecordRun(sl()));
  sl.registerLazySingleton(() => UnlockPart(sl()));
  sl.registerFactory(
    () => WalletBloc(
      repository: sl(),
      earnCoins: sl(),
      claimDailyRoulette: sl(),
      openChest: sl(),
      recordRun: sl(),
      unlockPart: sl(),
    ),
  );

  // ── Missions ──────────────────────────────────────────────────────────────
  sl.registerLazySingleton<MissionLocalDatasource>(
    () => MissionLocalDatasourceImpl(Hive.box('missions')),
  );
  sl.registerLazySingleton<MissionRepository>(
    () => MissionRepositoryImpl(sl()),
  );
  sl.registerFactory(
    () => MissionBloc(repository: sl()),
  );

  // ── Ranking ───────────────────────────────────────────────────────────────
  // Swap ScoreLocalRepository → FirebaseScoreRepository here to go online.
  sl.registerLazySingleton<ScoreRepository>(
    () => ScoreLocalRepository(Hive.box('scores')),
  );
  sl.registerFactory(() => RankingBloc(repository: sl()));

  // ── Monetización ──────────────────────────────────────────────────────────
  // Pago real: sustituye StubStoreRepository por InAppPurchaseStoreRepository
  // (ver `data/repositories/in_app_purchase_store_repository.dart`). Ese
  // adaptador SOLO funciona en iOS/Android; para no romper la web, regístralo
  // condicionado a la plataforma, p. ej.:
  //
  //   import 'package:flutter/foundation.dart' show kIsWeb;
  //   sl.registerLazySingleton<StoreRepository>(() => kIsWeb
  //       ? StubStoreRepository(sl())
  //       : InAppPurchaseStoreRepository(sl()));
  //
  // Requisitos: `flutter pub get`, plataformas nativas y productos dados de
  // alta en Google Play / App Store con los mismos IDs que `storeCatalog`.
  sl.registerLazySingleton<StoreLocalDatasource>(
    () => StoreLocalDatasourceImpl(Hive.box('entitlements')),
  );
  sl.registerLazySingleton<StoreRepository>(
    () => StubStoreRepository(sl()),
  );

  // ── Analítica (first-party, local) ────────────────────────────────────────
  // Envolver/añadir un sink remoto propio aquí para métricas agregadas.
  sl.registerLazySingleton<AnalyticsLocalDatasource>(
    () => AnalyticsLocalDatasourceImpl(
      events: Hive.box<AnalyticsEventModel>('analytics_events'),
      meta: Hive.box<dynamic>('analytics_meta'),
    ),
  );
  sl.registerLazySingleton<AnalyticsService>(
    () => LocalAnalyticsService(sl()),
  );
}
