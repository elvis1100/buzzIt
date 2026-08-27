import 'package:buzz_it/models/team.dart';
import 'package:buzz_it/views/player/widgets/buzzer_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('locks the opposing buzzer after a winner is shown', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 600,
          height: 320,
          child: BuzzerPanel(
            team: Team.b,
            name: 'Amber Owls',
            color: const Color(0xFFF1A606),
            displayedWinner: Team.a,
            enabled: false,
            onPressed: () => taps++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(BuzzerPanel));
    await tester.pump();

    expect(taps, 0);
    expect(find.text('ROUND LOCKED'), findsOneWidget);
    expect(find.text('Waiting for reset'), findsOneWidget);
  });
}
