import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:run_for_win/features/missions/domain/entities/mission.dart';
import 'package:run_for_win/features/missions/presentation/widgets/mission_card.dart';

Mission _m({required int progress, int target = 100}) => Mission(
      id: 'm1',
      type: MissionType.collectCoins,
      title: 'Recoge monedas',
      description: 'Recoge $target monedas',
      target: target,
      progress: progress,
      rewardCoins: 50,
    );

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('MissionCard en progreso se dibuja sin error', (tester) async {
    await tester.pumpWidget(_wrap(MissionCard(mission: _m(progress: 40))));
    expect(find.byType(MissionCard), findsOneWidget);
    // La recompensa se muestra en la tarjeta.
    expect(find.textContaining('50'), findsWidgets);
  });

  testWidgets('MissionCard completada se dibuja (variante compacta)',
      (tester) async {
    await tester.pumpWidget(
      _wrap(MissionCard(mission: _m(progress: 100), compact: true)),
    );
    expect(find.byType(MissionCard), findsOneWidget);
  });

  testWidgets('una misión completada se marca como tal', (tester) async {
    final done = _m(progress: 100);
    final pending = _m(progress: 10);
    expect(done.isCompleted, isTrue);
    expect(pending.isCompleted, isFalse);
    await tester.pumpWidget(_wrap(MissionCard(mission: done)));
    expect(tester.takeException(), isNull);
  });
}
