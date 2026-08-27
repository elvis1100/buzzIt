import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:buzz_it/controllers/player_controller.dart';
import 'package:buzz_it/views/player/widgets/player_connection_view.dart';

void main() {
  testWidgets('shows the mobile host connection controls', (tester) async {
    final controller = PlayerController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(home: PlayerConnectionView(controller: controller)),
    );

    expect(find.text('Connect to host'), findsOneWidget);
    expect(find.text('Scan host QR code'), findsOneWidget);
    expect(find.text('Host IP address'), findsOneWidget);
    expect(find.text('Six-digit pairing code'), findsOneWidget);
  });
}
