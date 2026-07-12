import 'package:equatable/equatable.dart';

import '../../domain/entities/character.dart';
import '../../domain/entities/preset_characters.dart';

sealed class CharacterEditorEvent extends Equatable {
  const CharacterEditorEvent();
  @override
  List<Object?> get props => [];
}

class LoadCharacters extends CharacterEditorEvent {
  const LoadCharacters();
}

class StartNewCharacter extends CharacterEditorEvent {
  const StartNewCharacter();
}

/// Load a preconfigured (preset) character into the editor as a new, editable
/// character. The user keeps the preset's name + full appearance but can then
/// change anything (mouth, hair, accessories, …) before saving.
class StartFromPreset extends CharacterEditorEvent {
  final PresetCharacter preset;
  const StartFromPreset(this.preset);
  @override
  List<Object?> get props => [preset.id];
}

class LoadCharacterForEdit extends CharacterEditorEvent {
  final String characterId;
  const LoadCharacterForEdit(this.characterId);
  @override
  List<Object?> get props => [characterId];
}

class UpdateName extends CharacterEditorEvent {
  final String name;
  const UpdateName(this.name);
  @override
  List<Object?> get props => [name];
}

class UpdateCharacterType extends CharacterEditorEvent {
  final CharacterType type;
  const UpdateCharacterType(this.type);
  @override
  List<Object?> get props => [type];
}

class UpdateAppearance extends CharacterEditorEvent {
  final CharacterAppearance appearance;
  const UpdateAppearance(this.appearance);
  @override
  List<Object?> get props => [appearance];
}

class SaveCurrentCharacter extends CharacterEditorEvent {
  const SaveCurrentCharacter();
}

class DeleteCharacterById extends CharacterEditorEvent {
  final String id;
  const DeleteCharacterById(this.id);
  @override
  List<Object?> get props => [id];
}

class DuplicateCharacter extends CharacterEditorEvent {
  final String id;
  const DuplicateCharacter(this.id);
  @override
  List<Object?> get props => [id];
}
