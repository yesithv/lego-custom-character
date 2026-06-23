import '../entities/character.dart';
import '../repositories/character_repository.dart';

class GetAllCharacters {
  final CharacterRepository repository;
  GetAllCharacters(this.repository);

  Future<List<Character>> call() => repository.getAllCharacters();
}
