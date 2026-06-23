import '../repositories/character_repository.dart';

class DeleteCharacter {
  final CharacterRepository repository;
  DeleteCharacter(this.repository);

  Future<void> call(String id) => repository.deleteCharacter(id);
}
