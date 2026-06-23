import 'package:equatable/equatable.dart';

import '../../domain/entities/character.dart';

enum EditorStatus { initial, loading, editing, saving, saved, error }

class CharacterEditorState extends Equatable {
  final EditorStatus status;
  final List<Character> characters;
  final Character? currentCharacter;
  final String? errorMessage;
  final bool showSaveSuccess;

  const CharacterEditorState({
    this.status = EditorStatus.initial,
    this.characters = const [],
    this.currentCharacter,
    this.errorMessage,
    this.showSaveSuccess = false,
  });

  CharacterEditorState copyWith({
    EditorStatus? status,
    List<Character>? characters,
    Character? currentCharacter,
    String? errorMessage,
    bool? showSaveSuccess,
  }) =>
      CharacterEditorState(
        status: status ?? this.status,
        characters: characters ?? this.characters,
        currentCharacter: currentCharacter ?? this.currentCharacter,
        errorMessage: errorMessage ?? this.errorMessage,
        showSaveSuccess: showSaveSuccess ?? this.showSaveSuccess,
      );

  @override
  List<Object?> get props =>
      [status, characters, currentCharacter, errorMessage, showSaveSuccess];
}
