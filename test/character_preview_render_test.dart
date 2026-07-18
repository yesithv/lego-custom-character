import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lego_custom_character/features/character_editor/domain/entities/character.dart';
import 'package:lego_custom_character/features/character_editor/presentation/widgets/character_preview.dart';
import 'package:lego_custom_character/features/economy/domain/entities/part_catalog.dart';

/// Verifica que cada opción de personalización produzca un render distinto:
/// dentro de cada dimensión (piel, ojos, torso, accesorios…) no puede haber
/// dos valores que pinten exactamente los mismos píxeles.
void main() {
  const boundaryKey = ValueKey('preview-boundary');

  Future<Uint8List> render(WidgetTester tester, CharacterAppearance a) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: boundaryKey,
          child: Center(child: CharacterPreview(appearance: a, size: 100)),
        ),
      ),
    );
    await tester.pump();
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
    late Uint8List bytes;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData();
      bytes = data!.buffer.asUint8List();
      image.dispose();
    });
    return bytes;
  }

  Future<void> expectAllDistinct(
    WidgetTester tester,
    String dimension,
    Map<String, CharacterAppearance> variants,
  ) async {
    final renders = <String, Uint8List>{};
    for (final entry in variants.entries) {
      renders[entry.key] = await render(tester, entry.value);
    }
    final names = renders.keys.toList();
    for (var i = 0; i < names.length; i++) {
      for (var j = i + 1; j < names.length; j++) {
        expect(
          listEquals(renders[names[i]], renders[names[j]]),
          isFalse,
          reason:
              '[$dimension] "${names[i]}" y "${names[j]}" se ven idénticos',
        );
      }
    }
  }

  testWidgets('cada tono de piel se ve distinto', (tester) async {
    await expectAllDistinct(tester, 'skinTone', {
      for (final v in SkinTone.values)
        v.name: CharacterAppearance(skinTone: v),
    });
  });

  testWidgets('cada estilo de ojos se ve distinto', (tester) async {
    await expectAllDistinct(tester, 'eyes', {
      for (final v in EyeStyle.values) v.name: CharacterAppearance(eyes: v),
    });
  });

  testWidgets('cada estilo de cejas se ve distinto', (tester) async {
    await expectAllDistinct(tester, 'eyebrows', {
      for (final v in EyebrowStyle.values)
        v.name: CharacterAppearance(eyebrows: v),
    });
  });

  testWidgets('las cejas son independientes de la expresión de los ojos',
      (tester) async {
    // Regresión: antes las cejas de enfado estaban embebidas en _drawEyes, así
    // que cambiar el estilo de cejas sobre unos ojos enfadados no hacía nada.
    await expectAllDistinct(tester, 'eyes+eyebrows', {
      for (final v in EyebrowStyle.values)
        v.name: CharacterAppearance(eyes: EyeStyle.angry, eyebrows: v),
    });
  });

  testWidgets('cada extra facial se ve distinto', (tester) async {
    await expectAllDistinct(tester, 'facialExtra', {
      for (final v in FacialExtra.values)
        v.name: CharacterAppearance(facialExtra: v),
    });
  });

  testWidgets('cada estilo de boca se ve distinto', (tester) async {
    await expectAllDistinct(tester, 'mouth', {
      for (final v in MouthStyle.values) v.name: CharacterAppearance(mouth: v),
    });
  });

  testWidgets('cada tipo de headwear se ve distinto', (tester) async {
    await expectAllDistinct(tester, 'headwearType', {
      for (final v in HeadwearType.values)
        v.name: CharacterAppearance(headwearType: v),
    });
  });

  testWidgets('cada estilo de cabello se ve distinto', (tester) async {
    await expectAllDistinct(tester, 'hairStyle', {
      for (final v in HairStyle.values)
        v.name: CharacterAppearance(
            headwearType: HeadwearType.hair, hairStyle: v),
    });
  });

  testWidgets('cada casco se ve distinto', (tester) async {
    await expectAllDistinct(tester, 'helmetStyle', {
      for (final v in HelmetStyle.values)
        v.name: CharacterAppearance(
            headwearType: HeadwearType.helmet, helmetStyle: v),
    });
  });

  testWidgets('cada sombrero se ve distinto', (tester) async {
    await expectAllDistinct(tester, 'hatStyle', {
      for (final v in HatStyle.values)
        v.name:
            CharacterAppearance(headwearType: HeadwearType.hat, hatStyle: v),
    });
  });

  testWidgets('cada diseño de torso se ve distinto', (tester) async {
    await expectAllDistinct(tester, 'torso', {
      for (final v in TorsoDesign.values) v.name: CharacterAppearance(torso: v),
    });
  });

  testWidgets('la capa se ve', (tester) async {
    await expectAllDistinct(tester, 'hasCape', {
      'sin capa': const CharacterAppearance(hasCape: false),
      'con capa': const CharacterAppearance(hasCape: true),
    });
  });

  testWidgets('cada tipo de guante se ve distinto', (tester) async {
    await expectAllDistinct(tester, 'gloves', {
      for (final v in GloveType.values) v.name: CharacterAppearance(gloves: v),
    });
  });

  testWidgets('cada diseño de piernas se ve distinto', (tester) async {
    await expectAllDistinct(tester, 'legDesign', {
      for (final v in LegDesign.values)
        v.name: CharacterAppearance(legDesign: v),
    });
  });

  testWidgets('cada tipo de piernas se ve distinto', (tester) async {
    await expectAllDistinct(tester, 'legType', {
      for (final v in LegType.values) v.name: CharacterAppearance(legType: v),
    });
  });

  testWidgets('cada tipo de zapato se ve distinto', (tester) async {
    await expectAllDistinct(tester, 'shoes', {
      for (final v in ShoeType.values) v.name: CharacterAppearance(shoes: v),
    });
  });

  testWidgets('cada accesorio del catálogo se ve al equiparlo',
      (tester) async {
    for (final slot in const [
      'rightHand',
      'leftHand',
      'back',
      'shoulders',
      'waist',
      'neck',
      'face',
      'feet',
    ]) {
      CharacterAppearance withAccessory(String? id) {
        final acc = switch (slot) {
          'rightHand' => CharacterAccessories(rightHand: id),
          'leftHand' => CharacterAccessories(leftHand: id),
          'back' => CharacterAccessories(back: id),
          'shoulders' => CharacterAccessories(shoulders: id),
          'waist' => CharacterAccessories(waist: id),
          'neck' => CharacterAccessories(neck: id),
          'face' => CharacterAccessories(face: id),
          _ => CharacterAccessories(feet: id),
        };
        return CharacterAppearance(accessories: acc);
      }

      await expectAllDistinct(tester, 'accessories.$slot', {
        'ninguno': withAccessory(null),
        for (final entry in catalogForSlot(slot))
          entry.id: withAccessory(entry.id),
      });
    }
  });
}
