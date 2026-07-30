import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/core/l10n/app_localizations.dart';
import 'package:run_for_win/core/l10n/app_strings.dart';
import 'package:run_for_win/core/orientation/portrait_lock.dart';

void main() {
  group('shouldAskToRotate', () {
    // Teléfono típico girado: 844x390 dp.
    const phoneLandscape = Size(844, 390);
    const phonePortrait = Size(390, 844);
    // Tablet girada: el lado corto (768) supera el corte de teléfono.
    const tabletLandscape = Size(1024, 768);
    const desktop = Size(1440, 900);

    test('teléfono en horizontal: pide girar', () {
      expect(
        shouldAskToRotate(
            size: phoneLandscape, platform: TargetPlatform.android),
        isTrue,
      );
      expect(
        shouldAskToRotate(size: phoneLandscape, platform: TargetPlatform.iOS),
        isTrue,
      );
    });

    test('teléfono en vertical: no pide nada', () {
      expect(
        shouldAskToRotate(size: phonePortrait, platform: TargetPlatform.android),
        isFalse,
      );
    });

    test('tablet en horizontal: no pide girar', () {
      expect(
        shouldAskToRotate(
            size: tabletLandscape, platform: TargetPlatform.android),
        isFalse,
      );
    });

    test('escritorio (ventana ancha): nunca pide girar', () {
      for (final platform in [
        TargetPlatform.macOS,
        TargetPlatform.windows,
        TargetPlatform.linux,
      ]) {
        expect(
          shouldAskToRotate(size: desktop, platform: platform),
          isFalse,
          reason: 'No debería pedir girar en $platform',
        );
      }
    });

    test('pantalla cuadrada: se considera vertical', () {
      expect(
        shouldAskToRotate(
            size: const Size(500, 500), platform: TargetPlatform.android),
        isFalse,
      );
    });
  });

  group('PortraitGate', () {
    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      landscapeBlocked.value = false;
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
      landscapeBlocked.value = false;
    });

    Widget harness(Size size) => MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: const [AppLocalizations.delegate],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: const PortraitGate(
              child: Scaffold(body: Text('contenido del juego')),
            ),
          ),
        );

    testWidgets('en horizontal tapa el juego con el aviso de girar',
        (tester) async {
      await tester.pumpWidget(harness(const Size(844, 390)));
      await tester.pump();

      expect(find.text(kStrings['rotate_device_title']!['es']!), findsOneWidget);
      expect(find.text(kStrings['rotate_device_hint']!['es']!), findsOneWidget);
      // El juego sigue montado debajo: al girar no se pierde la partida.
      expect(find.text('contenido del juego'), findsOneWidget);
      expect(landscapeBlocked.value, isTrue);

      // Desmonta el aviso para cerrar su animación en bucle.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('en vertical muestra el juego sin aviso', (tester) async {
      await tester.pumpWidget(harness(const Size(390, 844)));
      await tester.pump();

      expect(find.text(kStrings['rotate_device_title']!['es']!), findsNothing);
      expect(find.text('contenido del juego'), findsOneWidget);
      expect(landscapeBlocked.value, isFalse);
    });

    testWidgets('al volver a vertical el aviso desaparece', (tester) async {
      await tester.pumpWidget(harness(const Size(844, 390)));
      await tester.pump();
      expect(landscapeBlocked.value, isTrue);

      await tester.pumpWidget(harness(const Size(390, 844)));
      await tester.pump();

      expect(find.text(kStrings['rotate_device_title']!['es']!), findsNothing);
      expect(landscapeBlocked.value, isFalse);
    });
  });
}
