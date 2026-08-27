import 'dart:async';
import 'dart:io';

import 'package:buzz_it/services/network/player_client_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('disconnect cancels an in-flight connection attempt', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final serverSockets = <WebSocket>[];
    final upgraded = Completer<void>();
    server.listen((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final socket = await WebSocketTransformer.upgrade(request);
      serverSockets.add(socket);
      if (!upgraded.isCompleted) {
        upgraded.complete();
      }
    });
    addTearDown(() async {
      for (final socket in serverSockets) {
        await socket.close();
      }
      await server.close(force: true);
    });

    final client = PlayerClientService();
    addTearDown(client.dispose);
    final events = <PlayerNetworkEvent>[];
    final subscription = client.events.listen(events.add);
    addTearDown(subscription.cancel);

    final connection = client.connect(
      host: InternetAddress.loopbackIPv4.address,
      port: server.port,
      pairingCode: '123456',
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await client.disconnect();
    await connection.timeout(const Duration(seconds: 2));
    await upgraded.future.timeout(const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(client.isOpen, isFalse);
    expect(
      events.where(
        (event) => event.type == PlayerNetworkEventType.socketOpened,
      ),
      isEmpty,
    );
  });
}
