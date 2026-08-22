import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/character_editor/domain/entities/character.dart';
import 'package:run_for_win/features/character_editor/domain/repositories/character_repository.dart';
import 'package:run_for_win/features/character_editor/domain/usecases/delete_character.dart';
import 'package:run_for_win/features/character_editor/domain/usecases/get_all_characters.dart';
import 'package:run_for_win/features/character_editor/domain/usecases/save_character.dart';
import 'package:run_for_win/features/character_editor/presentation/bloc/character_editor_bloc.dart';
import 'package:run_for_win/features/character_editor/presentation/bloc/character_editor_event.dart';
import 'package:run_for_win/features/character_editor/presentation/bloc/character_editor_state.dart';

/// Repositorio de personajes en memoria (sin Hive).
class _FakeCharacterRepo implements CharacterRepository {
  final List<Character> _store;
  _FakeCharacterRepo([List<Character>? seed]) : _store = [...?seed];

  @override
  Future<List<Character>> getAllCharacters() async => List.of(_store);

  @override
  Future<void> saveCharacter(Character c) async {
    final i = _store.indexWhere((e) => e.id == c.id);
    if (i >= 0) {
      _store[i] = c;
    } else {
      _store.add(c);
    }
  }

  @override
  Future<void> deleteCharacter(String id) async =>
      _store.removeWhere((c) => c.id == id);

  @override
  Future<Character?> getCharacterById(String id) async =>
      _store.where((c) => c.id == id).firstOrNull;

  @override
  Future<int> getCharacterCount() async => _store.length;
}

Character _char(String id, String name) => Character(
      id: id,
      name: name,
      type: CharacterType.hero,
      appearance: const CharacterAppearance(),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

CharacterEditorBloc _bloc(_FakeCharacterRepo repo) => CharacterEditorBloc(
      saveCharacter: SaveCharacter(repo),
      getAllCharacters: GetAllCharacters(repo),
      deleteCharacter: DeleteCharacter(repo),
    );

void main() {
  blocTest<CharacterEditorBloc, CharacterEditorState>(
    'LoadCharacters emite loading y luego initial con la lista',
    build: () => _bloc(_FakeCharacterRepo([_char('1', 'Brix')])),
    act: (b) => b.add(const LoadCharacters()),
    expect: () => [
      isA<CharacterEditorState>()
          .having((s) => s.status, 'status', EditorStatus.loading),
      isA<CharacterEditorState>()
          .having((s) => s.status, 'status', EditorStatus.initial)
          .having((s) => s.characters.length, 'characters', 1),
    ],
  );

  blocTest<CharacterEditorBloc, CharacterEditorState>(
    'StartNewCharacter entra en edición con un personaje en blanco',
    build: () => _bloc(_FakeCharacterRepo()),
    act: (b) => b.add(const StartNewCharacter()),
    expect: () => [
      isA<CharacterEditorState>()
          .having((s) => s.status, 'status', EditorStatus.editing)
          .having((s) => s.currentCharacter?.name, 'name', ''),
    ],
  );

  blocTest<CharacterEditorBloc, CharacterEditorState>(
    'Guardar sin nombre produce error',
    build: () => _bloc(_FakeCharacterRepo()),
    seed: () => CharacterEditorState(
      status: EditorStatus.editing,
      currentCharacter: _char('1', '   '),
    ),
    act: (b) => b.add(const SaveCurrentCharacter()),
    expect: () => [
      isA<CharacterEditorState>()
          .having((s) => s.status, 'status', EditorStatus.error)
          .having((s) => s.errorMessage, 'errorMessage', isNotNull),
    ],
  );

  blocTest<CharacterEditorBloc, CharacterEditorState>(
    'Guardar un personaje válido lo persiste y marca éxito',
    build: () => _bloc(_FakeCharacterRepo()),
    seed: () => CharacterEditorState(
      status: EditorStatus.editing,
      currentCharacter: _char('1', 'Brix'),
    ),
    act: (b) => b.add(const SaveCurrentCharacter()),
    expect: () => [
      isA<CharacterEditorState>()
          .having((s) => s.status, 'status', EditorStatus.saving),
      isA<CharacterEditorState>()
          .having((s) => s.status, 'status', EditorStatus.saved)
          .having((s) => s.showSaveSuccess, 'showSaveSuccess', true)
          .having((s) => s.characters.length, 'characters', 1),
    ],
  );

  blocTest<CharacterEditorBloc, CharacterEditorState>(
    'Con el límite gratis lleno, guardar uno nuevo falla',
    build: () => _bloc(_FakeCharacterRepo([
      for (var i = 0; i < freeCharacterLimit; i++) _char('$i', 'P$i'),
    ])),
    seed: () => CharacterEditorState(
      status: EditorStatus.editing,
      currentCharacter: _char('nuevo', 'Extra'),
    ),
    act: (b) => b.add(const SaveCurrentCharacter()),
    expect: () => [
      isA<CharacterEditorState>()
          .having((s) => s.status, 'status', EditorStatus.saving),
      isA<CharacterEditorState>()
          .having((s) => s.status, 'status', EditorStatus.error),
    ],
  );

  blocTest<CharacterEditorBloc, CharacterEditorState>(
    'DeleteCharacterById elimina y refresca la lista',
    build: () =>
        _bloc(_FakeCharacterRepo([_char('1', 'A'), _char('2', 'B')])),
    seed: () => CharacterEditorState(
      characters: [_char('1', 'A'), _char('2', 'B')],
    ),
    act: (b) => b.add(const DeleteCharacterById('1')),
    expect: () => [
      isA<CharacterEditorState>()
          .having((s) => s.characters.map((c) => c.id).toList(), 'ids', ['2']),
    ],
  );
}
