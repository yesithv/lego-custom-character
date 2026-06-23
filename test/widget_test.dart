import 'package:flutter_test/flutter_test.dart';
import 'package:lego_custom_character/features/character_editor/domain/entities/character.dart';
import 'package:lego_custom_character/features/character_editor/presentation/widgets/character_preview.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('CharacterPreview renders without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CharacterPreview(
            appearance: CharacterAppearance(),
            size: 100,
          ),
        ),
      ),
    );
    expect(find.byType(CharacterPreview), findsOneWidget);
  });

  group('CharacterAppearance', () {
    test('copyWith returns new instance with updated fields', () {
      const original = CharacterAppearance();
      final updated = original.copyWith(skinTone: SkinTone.blue);
      expect(updated.skinTone, SkinTone.blue);
      expect(updated.eyes, original.eyes);
    });

    test('two appearances with same values are equal', () {
      const a = CharacterAppearance();
      const b = CharacterAppearance();
      expect(a, equals(b));
    });
  });

  group('Character', () {
    final now = DateTime.now();
    final character = Character(
      id: '1',
      name: 'Brix',
      type: CharacterType.hero,
      appearance: const CharacterAppearance(),
      createdAt: now,
      updatedAt: now,
    );

    test('copyWith preserves id', () {
      final updated = character.copyWith(name: 'Brix2');
      expect(updated.id, '1');
      expect(updated.name, 'Brix2');
    });
  });
}
