import '../../../../core/error/failures.dart';
import '../entities/character.dart';

abstract class CharacterRepository {
  Future<List<Character>> getAllCharacters();
  Future<void> saveCharacter(Character character);
  Future<void> deleteCharacter(String id);
  Future<Character?> getCharacterById(String id);
  Future<int> getCharacterCount();
}

sealed class SaveResult {
  const SaveResult();
}

class SaveSuccess extends SaveResult {
  const SaveSuccess();
}

class SaveFailureResult extends SaveResult {
  final Failure failure;
  const SaveFailureResult(this.failure);
}
