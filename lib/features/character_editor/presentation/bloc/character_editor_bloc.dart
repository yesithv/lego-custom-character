import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/character.dart';
import '../../domain/usecases/delete_character.dart';
import '../../domain/usecases/get_all_characters.dart';
import '../../domain/usecases/save_character.dart';
import 'character_editor_event.dart';
import 'character_editor_state.dart';

class CharacterEditorBloc
    extends Bloc<CharacterEditorEvent, CharacterEditorState> {
  final SaveCharacter saveCharacter;
  final GetAllCharacters getAllCharacters;
  final DeleteCharacter deleteCharacter;

  static const _uuid = Uuid();

  CharacterEditorBloc({
    required this.saveCharacter,
    required this.getAllCharacters,
    required this.deleteCharacter,
  }) : super(const CharacterEditorState()) {
    on<LoadCharacters>(_onLoadCharacters);
    on<StartNewCharacter>(_onStartNewCharacter);
    on<StartFromPreset>(_onStartFromPreset);
    on<LoadCharacterForEdit>(_onLoadCharacterForEdit);
    on<UpdateName>(_onUpdateName);
    on<UpdateCharacterType>(_onUpdateCharacterType);
    on<UpdateAppearance>(_onUpdateAppearance);
    on<SaveCurrentCharacter>(_onSaveCurrentCharacter);
    on<DeleteCharacterById>(_onDeleteCharacter);
    on<DuplicateCharacter>(_onDuplicateCharacter);
  }

  Future<void> _onLoadCharacters(
      LoadCharacters event, Emitter<CharacterEditorState> emit) async {
    emit(state.copyWith(status: EditorStatus.loading));
    final characters = await getAllCharacters();
    emit(state.copyWith(status: EditorStatus.initial, characters: characters));
  }

  void _onStartNewCharacter(
      StartNewCharacter event, Emitter<CharacterEditorState> emit) {
    final now = DateTime.now();
    emit(state.copyWith(
      status: EditorStatus.editing,
      currentCharacter: Character(
        id: _uuid.v4(),
        name: '',
        type: CharacterType.hero,
        appearance: const CharacterAppearance(),
        createdAt: now,
        updatedAt: now,
      ),
    ));
  }

  void _onStartFromPreset(
      StartFromPreset event, Emitter<CharacterEditorState> emit) {
    final now = DateTime.now();
    emit(state.copyWith(
      status: EditorStatus.editing,
      currentCharacter: Character(
        id: _uuid.v4(),
        name: event.preset.name,
        type: event.preset.type,
        appearance: event.preset.appearance,
        createdAt: now,
        updatedAt: now,
      ),
    ));
  }

  Future<void> _onLoadCharacterForEdit(
      LoadCharacterForEdit event, Emitter<CharacterEditorState> emit) async {
    final character = state.characters.where((c) => c.id == event.characterId).firstOrNull;
    if (character != null) {
      emit(state.copyWith(
        status: EditorStatus.editing,
        currentCharacter: character,
      ));
    }
  }

  void _onUpdateName(UpdateName event, Emitter<CharacterEditorState> emit) {
    final current = state.currentCharacter;
    if (current == null) return;
    emit(state.copyWith(
      currentCharacter: current.copyWith(
        name: event.name,
        updatedAt: DateTime.now(),
      ),
    ));
  }

  void _onUpdateCharacterType(
      UpdateCharacterType event, Emitter<CharacterEditorState> emit) {
    final current = state.currentCharacter;
    if (current == null) return;
    emit(state.copyWith(
      currentCharacter: current.copyWith(type: event.type),
    ));
  }

  void _onUpdateAppearance(
      UpdateAppearance event, Emitter<CharacterEditorState> emit) {
    final current = state.currentCharacter;
    if (current == null) return;
    emit(state.copyWith(
      currentCharacter: current.copyWith(
        appearance: event.appearance,
        updatedAt: DateTime.now(),
      ),
    ));
  }

  Future<void> _onSaveCurrentCharacter(
      SaveCurrentCharacter event, Emitter<CharacterEditorState> emit) async {
    final current = state.currentCharacter;
    if (current == null || current.name.trim().isEmpty) {
      emit(state.copyWith(
        status: EditorStatus.error,
        errorMessage: L10n.t('editor_needs_name'),
      ));
      return;
    }
    emit(state.copyWith(status: EditorStatus.saving));
    final result = await saveCharacter(current);
    if (result.success) {
      final updated = await getAllCharacters();
      emit(state.copyWith(
        status: EditorStatus.saved,
        characters: updated,
        showSaveSuccess: true,
      ));
    } else {
      emit(state.copyWith(
        status: EditorStatus.error,
        errorMessage: result.failure?.message,
      ));
    }
  }

  Future<void> _onDeleteCharacter(
      DeleteCharacterById event, Emitter<CharacterEditorState> emit) async {
    await deleteCharacter(event.id);
    final updated = await getAllCharacters();
    emit(state.copyWith(characters: updated));
  }

  Future<void> _onDuplicateCharacter(
      DuplicateCharacter event, Emitter<CharacterEditorState> emit) async {
    final original =
        state.characters.where((c) => c.id == event.id).firstOrNull;
    if (original == null) return;
    final now = DateTime.now();
    final duplicate = Character(
      id: _uuid.v4(),
      name: '${original.name} ${L10n.t('copy_suffix')}',
      type: original.type,
      specialPower: original.specialPower,
      appearance: original.appearance,
      createdAt: now,
      updatedAt: now,
      musicTrack: original.musicTrack,
    );
    await saveCharacter(duplicate);
    final updated = await getAllCharacters();
    emit(state.copyWith(characters: updated));
  }
}
