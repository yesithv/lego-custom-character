import 'package:hive/hive.dart';

import '../models/character_model.dart';

abstract class CharacterLocalDatasource {
  List<CharacterModel> getAll();
  Future<void> save(CharacterModel model);
  Future<void> delete(String id);
  CharacterModel? getById(String id);
  int count();
}

class CharacterLocalDatasourceImpl implements CharacterLocalDatasource {
  final Box<CharacterModel> _box;

  CharacterLocalDatasourceImpl(this._box);

  @override
  List<CharacterModel> getAll() => _box.values.toList();

  @override
  Future<void> save(CharacterModel model) => _box.put(model.id, model);

  @override
  Future<void> delete(String id) => _box.delete(id);

  @override
  CharacterModel? getById(String id) => _box.get(id);

  @override
  int count() => _box.length;
}
