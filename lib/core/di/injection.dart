import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/character_editor/data/datasources/character_local_datasource.dart';
import '../../features/character_editor/data/models/character_model.dart';
import '../../features/character_editor/data/repositories/character_repository_impl.dart';
import '../../features/character_editor/domain/repositories/character_repository.dart';
import '../../features/character_editor/domain/usecases/delete_character.dart';
import '../../features/character_editor/domain/usecases/get_all_characters.dart';
import '../../features/character_editor/domain/usecases/save_character.dart';
import '../../features/character_editor/presentation/bloc/character_editor_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  await Hive.initFlutter();
  Hive.registerAdapter(CharacterModelAdapter());
  Hive.registerAdapter(CharacterAppearanceModelAdapter());
  await Hive.openBox<CharacterModel>('characters');

  // Datasources
  sl.registerLazySingleton<CharacterLocalDatasource>(
    () => CharacterLocalDatasourceImpl(Hive.box('characters')),
  );

  // Repositories
  sl.registerLazySingleton<CharacterRepository>(
    () => CharacterRepositoryImpl(sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => SaveCharacter(sl()));
  sl.registerLazySingleton(() => GetAllCharacters(sl()));
  sl.registerLazySingleton(() => DeleteCharacter(sl()));

  // BLoC
  sl.registerFactory(
    () => CharacterEditorBloc(
      saveCharacter: sl(),
      getAllCharacters: sl(),
      deleteCharacter: sl(),
    ),
  );
}
