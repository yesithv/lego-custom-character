import '../../../../core/error/failures.dart';
import '../entities/character.dart';
import '../repositories/character_repository.dart';

const int freeCharacterLimit = 5;

class SaveCharacter {
  final CharacterRepository repository;

  SaveCharacter(this.repository);

  Future<({bool success, Failure? failure})> call(
    Character character, {
    bool isPro = false,
  }) async {
    if (!isPro) {
      final count = await repository.getCharacterCount();
      final isExisting = (await repository.getCharacterById(character.id)) != null;
      if (!isExisting && count >= freeCharacterLimit) {
        return (success: false, failure: const CharacterLimitFailure());
      }
    }
    await repository.saveCharacter(character);
    return (success: true, failure: null);
  }
}
