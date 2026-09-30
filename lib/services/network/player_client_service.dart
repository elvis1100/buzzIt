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
  bool _disposed = false;
  int _connectionGeneration = 0;

  Stream<PlayerNetworkEvent> get events => _events.stream;

  bool get isOpen => _socket?.readyState == WebSocket.open;

  Future<void> connect({
    required String host,
    required int port,
    required String pairingCode,
  }) async {
    final generation = ++_connectionGeneration;
    _manualDisconnect = false;
    final previousSocket = _socket;
    _socket = null;
    await previousSocket?.close(1000, 'Player reconnecting.');
    if (!_isCurrent(generation)) {
      return;
    }
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
      if (!_isCurrent(generation)) {
        await socket.close(1000, 'Connection attempt canceled.');
        return;
      }
      _socket = socket;
      socket.pingInterval = const Duration(seconds: 12);
      _emit(const PlayerNetworkEvent(PlayerNetworkEventType.socketOpened));
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
            _emit(
              PlayerNetworkEvent(
                PlayerNetworkEventType.message,
                message: ProtocolMessage.decode(raw),
              ),
            );
          } on FormatException {
            _emit(
              const PlayerNetworkEvent(
                PlayerNetworkEventType.error,
                detail:
                    'The host sent an invalid message. Reconnect and try again.',
              ),
            );
          }
        },
        onDone: () {
          if (identical(_socket, socket)) {
            _socket = null;
            _emit(
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
          if (!identical(_socket, socket)) {
            return;
          }
          _socket = null;
          const detail =
              'The host connection failed. Check the network and try again.';
          _emit(
            PlayerNetworkEvent(PlayerNetworkEventType.error, detail: detail),
          );
          _emit(
            PlayerNetworkEvent(
              PlayerNetworkEventType.disconnected,
              detail: detail,
            ),
          );
          unawaited(socket.close(1011, 'Connection error.'));
        },
        cancelOnError: true,
      );
    } on Object {
      if (!_isCurrent(generation)) {
        return;
      }
      _socket = null;
      _emit(
        PlayerNetworkEvent(
          PlayerNetworkEventType.error,
          detail:
              'Could not reach $host:$port. Check that both devices are on '
              'the same Wi-Fi and that the host firewall allows this port.',
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
    _connectionGeneration++;
    _manualDisconnect = manual;
    final socket = _socket;
    _socket = null;
    await socket?.close(1000, 'Player disconnected.');
  }

  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
    await _events.close();
  }

  bool _isCurrent(int generation) {
    return !_disposed &&
        !_manualDisconnect &&
        generation == _connectionGeneration;
  }

  void _emit(PlayerNetworkEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }
}
