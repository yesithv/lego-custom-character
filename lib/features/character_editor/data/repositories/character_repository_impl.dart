import '../../domain/entities/character.dart';
import '../../domain/repositories/character_repository.dart';
import '../datasources/character_local_datasource.dart';
import '../models/character_model.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  final CharacterLocalDatasource _datasource;

  CharacterRepositoryImpl(this._datasource);

  @override
  Future<List<Character>> getAllCharacters() async =>
      _datasource.getAll().map((m) => m.toEntity()).toList();

  @override
  Future<void> saveCharacter(Character character) =>
      _datasource.save(CharacterModel.fromEntity(character));

  @override
  Future<void> deleteCharacter(String id) => _datasource.delete(id);

  @override
  Future<Character?> getCharacterById(String id) async =>
      _datasource.getById(id)?.toEntity();

  @override
  Future<int> getCharacterCount() async => _datasource.count();
}
