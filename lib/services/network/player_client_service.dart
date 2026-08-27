import 'dart:async';
import 'dart:io';

import '../../core/constants.dart';
import '../../models/protocol_message.dart';

enum PlayerNetworkEventType { socketOpened, disconnected, message, error }

class PlayerNetworkEvent {
  const PlayerNetworkEvent(this.type, {this.message, this.detail});

  final PlayerNetworkEventType type;
  final ProtocolMessage? message;
  final String? detail;
}

class PlayerClientService {
  final StreamController<PlayerNetworkEvent> _events =
      StreamController<PlayerNetworkEvent>.broadcast();

  WebSocket? _socket;
  bool _manualDisconnect = false;

  Stream<PlayerNetworkEvent> get events => _events.stream;

  bool get isOpen => _socket?.readyState == WebSocket.open;

  Future<void> connect({
    required String host,
    required int port,
    required String pairingCode,
  }) async {
    await disconnect(manual: false);
    _manualDisconnect = false;
    final uri = Uri(
      scheme: 'ws',
      host: host.trim(),
      port: port,
      path: AppConstants.websocketPath,
    );
    try {
      final socket = await WebSocket.connect(
        uri.toString(),
      ).timeout(const Duration(seconds: 8));
      _socket = socket;
      socket.pingInterval = const Duration(seconds: 12);
      _events.add(
        const PlayerNetworkEvent(PlayerNetworkEventType.socketOpened),
      );
      send(
        ProtocolMessage(
          type: MessageType.hello,
          payload: <String, Object?>{
            'code': pairingCode,
            'device': 'Android buzzer',
          },
        ),
      );
      socket.listen(
        (Object? raw) {
          if (raw is! String) {
            return;
          }
          try {
            _events.add(
              PlayerNetworkEvent(
                PlayerNetworkEventType.message,
                message: ProtocolMessage.decode(raw),
              ),
            );
          } on FormatException catch (error) {
            _events.add(
              PlayerNetworkEvent(
                PlayerNetworkEventType.error,
                detail: error.message,
              ),
            );
          }
        },
        onDone: () {
          if (identical(_socket, socket)) {
            _socket = null;
            _events.add(
              PlayerNetworkEvent(
                PlayerNetworkEventType.disconnected,
                detail: _manualDisconnect
                    ? null
                    : 'The host connection was lost.',
              ),
            );
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (identical(_socket, socket)) {
            _socket = null;
          }
          _events.add(
            PlayerNetworkEvent(
              PlayerNetworkEventType.error,
              detail: 'Connection error: $error',
            ),
          );
        },
        cancelOnError: true,
      );
    } on Object catch (error) {
      _socket = null;
      _events.add(
        PlayerNetworkEvent(
          PlayerNetworkEventType.error,
          detail: 'Could not reach the host: $error',
        ),
      );
      rethrow;
    }
  }

  void send(ProtocolMessage message) {
    final socket = _socket;
    if (socket != null && socket.readyState == WebSocket.open) {
      socket.add(message.encode());
    }
  }

  Future<void> disconnect({bool manual = true}) async {
    _manualDisconnect = manual;
    final socket = _socket;
    _socket = null;
    await socket?.close(1000, 'Player disconnected.');
  }

  Future<void> dispose() async {
    await disconnect();
    await _events.close();
  }
}
