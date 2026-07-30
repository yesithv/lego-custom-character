import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/character_editor/domain/entities/preset_characters.dart';
import 'package:run_for_win/features/character_editor/presentation/widgets/character_preview.dart';

Future<void> dump(WidgetTester t, String id, String out) async {
  final p = presetCharacters.firstWhere((e) => e.id == id);
  final k = GlobalKey();
  await t.pumpWidget(MaterialApp(home: Scaffold(
    backgroundColor: const Color(0xFF101418),
    body: Center(child: RepaintBoundary(key: k,
      child: CharacterPreview(appearance: p.appearance, size: 300))))));
  await t.pump(const Duration(milliseconds: 100));
  final b = k.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final img = await b.toImage(pixelRatio: 2.0);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  File(out).writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('snaps', (t) async {
    await dump(t, 'preset_leila_princess', 'build/s_leila.png');
    await dump(t, 'preset_capitan_america', 'build/s_capitan.png');
    await dump(t, 'preset_black_panther', 'build/s_panther.png');
  });
}
