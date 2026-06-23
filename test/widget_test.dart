import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lego_custom_character/main.dart';

void main() {
  testWidgets('Hola Mundo widget test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('¡Hola, Mundo!'), findsOneWidget);
  });
}
