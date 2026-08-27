import 'dart:io';

import 'package:buzz_it/core/constants.dart';
import 'package:buzz_it/models/protocol_message.dart';
import 'package:buzz_it/services/network/host_server_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pairs one client and exchanges protocol messages', () async {
    final server = HostServerService();
    addTearDown(server.dispose);
    await server.start(port: 0, pairingCode: '123456');
    final port = server.boundPort!;
    final connected = server.events.firstWhere(
      (event) => event.type == HostNetworkEventType.clientConnected,
    );
    final received = server.events.firstWhere(
      (event) => event.type == HostNetworkEventType.message,
    );

    final socket = await WebSocket.connect(
      'ws://127.0.0.1:$port${AppConstants.websocketPath}',
    );
    addTearDown(socket.close);
    socket.add(
      ProtocolMessage(
        type: MessageType.hello,
        payload: const <String, Object?>{'code': '123456'},
      ).encode(),
    );
    await connected.timeout(const Duration(seconds: 2));

    socket.add(
      ProtocolMessage(
        type: MessageType.buzzAttempt,
        roundId: 1,
        payload: const <String, Object?>{'team': 'a'},
      ).encode(),
    );
    final event = await received.timeout(const Duration(seconds: 2));

    expect(event.message?.type, MessageType.buzzAttempt);
    expect(event.message?.payload['team'], 'a');
  });

  test('rejects an incorrect pairing code', () async {
    final server = HostServerService();
    addTearDown(server.dispose);
    await server.start(port: 0, pairingCode: '123456');
    final socket = await WebSocket.connect(
      'ws://127.0.0.1:${server.boundPort}${AppConstants.websocketPath}',
    );
    addTearDown(socket.close);
    final firstMessage = socket.first;

    socket.add(
      ProtocolMessage(
        type: MessageType.hello,
        payload: const <String, Object?>{'code': '000000'},
      ).encode(),
    );

    final decoded = ProtocolMessage.decode(
      await firstMessage.timeout(const Duration(seconds: 2)) as String,
    );
    expect(decoded.type, MessageType.error);
    expect(decoded.payload['code'], 'pairing_failed');
  });

  test('reports malformed messages to the connected client', () async {
    final server = HostServerService();
    addTearDown(server.dispose);
    await server.start(port: 0, pairingCode: '123456');
    final connected = server.events.firstWhere(
      (event) => event.type == HostNetworkEventType.clientConnected,
    );
    final socket = await WebSocket.connect(
      'ws://127.0.0.1:${server.boundPort}${AppConstants.websocketPath}',
    );
    addTearDown(socket.close);
    socket.add(
      ProtocolMessage(
        type: MessageType.hello,
        payload: const <String, Object?>{'code': '123456'},
      ).encode(),
    );
    await connected.timeout(const Duration(seconds: 2));

    final response = socket.first;
    socket.add(
      '{"version":1,"id":"bad","type":"buzz_attempt","roundId":"1","payload":{"team":"a"}}',
    );
    final decoded = ProtocolMessage.decode(
      await response.timeout(const Duration(seconds: 2)) as String,
    );

    expect(decoded.type, MessageType.error);
    expect(decoded.payload['code'], 'invalid_message');
  });
}
