import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/character_editor/domain/entities/preset_characters.dart';
import 'package:run_for_win/features/character_editor/presentation/widgets/character_preview.dart';
import 'package:run_for_win/features/economy/domain/entities/part_catalog.dart';

void main() {
  group('presetCharacters', () {
    test('the preset list is not empty and ids are unique', () {
      expect(presetCharacters, isNotEmpty);
      final ids = presetCharacters.map((p) => p.id).toSet();
      expect(ids.length, presetCharacters.length);
    });

    test('every accessory referenced by a preset exists in the catalog', () {
      for (final preset in presetCharacters) {
        final acc = preset.appearance.accessories;
        for (final id in [
          acc.rightHand,
          acc.leftHand,
          acc.back,
          acc.shoulders,
          acc.waist,
          acc.neck,
          acc.face,
          acc.feet,
        ]) {
          if (id != null) {
            expect(catalogEntry(id), isNotNull,
                reason: 'Preset "${preset.name}" uses unknown accessory "$id"');
          }
        }
      }
    });

    test('accessories are placed in their catalog slot', () {
      for (final preset in presetCharacters) {
        final acc = preset.appearance.accessories;
        void check(String? id, String slot) {
          if (id != null) {
            expect(catalogEntry(id)!.slot, slot,
                reason: '"$id" should belong to slot "$slot"');
          }
        }

        check(acc.rightHand, 'rightHand');
        check(acc.leftHand, 'leftHand');
        check(acc.back, 'back');
        check(acc.shoulders, 'shoulders');
        check(acc.waist, 'waist');
        check(acc.neck, 'neck');
        check(acc.face, 'face');
        check(acc.feet, 'feet');
      }
    });

    test('collections group all presets', () {
      final grouped = presetCollections
          .expand((c) => presetsForCollection(c))
          .length;
      expect(grouped, presetCharacters.length);
    });
  });

  testWidgets('every preset renders without error', (tester) async {
    for (final preset in presetCharacters) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CharacterPreview(appearance: preset.appearance, size: 80),
          ),
        ),
      );
      expect(find.byType(CharacterPreview), findsOneWidget);
    }
  });
}
