import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../core/constants.dart';
import '../../models/protocol_message.dart';

enum HostNetworkEventType {
  clientConnected,
  clientDisconnected,
  message,
  error,
}

class HostNetworkEvent {
  const HostNetworkEvent(this.type, {this.message, this.detail});

  final HostNetworkEventType type;
  final ProtocolMessage? message;
  final String? detail;
}

class HostServerService {
  final StreamController<HostNetworkEvent> _events =
      StreamController<HostNetworkEvent>.broadcast();

  HttpServer? _server;
  WebSocket? _client;
  WebSocket? _pendingClient;
  String _pairingCode = '';

  Stream<HostNetworkEvent> get events => _events.stream;

  bool get hasClient => _client != null;

  int? get boundPort => _server?.port;

  Future<void> start({required int port, required String pairingCode}) async {
    await stop();
    _pairingCode = pairingCode;
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
    _server!.listen(
      _handleRequest,
      onError: (Object error, StackTrace stackTrace) {
        _emitError('Server error: $error');
      },
    );
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.uri.path == '/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode(<String, Object?>{
            'app': AppConstants.appName,
            'status': 'ok',
            'clientConnected': hasClient,
            'protocolVersion': AppConstants.protocolVersion,
          }),
        );
      await request.response.close();
      return;
    }
    if (request.uri.path != AppConstants.websocketPath ||
        !WebSocketTransformer.isUpgradeRequest(request)) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    try {
      final socket = await WebSocketTransformer.upgrade(request);
      if (_client != null || _pendingClient != null) {
        socket.add(
          ProtocolMessage(
            type: MessageType.error,
            payload: const <String, Object?>{
              'code': 'client_limit',
              'message': 'A buzzer is already connected.',
            },
          ).encode(),
        );
        await socket.close(4009, 'A buzzer is already connected.');
        return;
      }
      _pendingClient = socket;
      _listenToClient(socket);
    } on Object catch (error) {
      _emitError('Could not upgrade the connection: $error');
    }
  }

  void _listenToClient(WebSocket socket) {
    var authenticated = false;
    var terminated = false;
    socket.pingInterval = const Duration(seconds: 12);
    final handshakeTimer = Timer(const Duration(seconds: 8), () async {
      if (!authenticated) {
        await socket.close(4008, 'Pairing timed out.');
      }
    });

    socket.listen(
      (Object? raw) {
        if (raw is! String) {
          return;
        }
        try {
          final message = ProtocolMessage.decode(raw);
          if (!authenticated) {
            final code = message.payload['code'];
            if (message.type != MessageType.hello || code != _pairingCode) {
              _sendToSocket(
                socket,
                ProtocolMessage(
                  type: MessageType.error,
                  payload: const <String, Object?>{
                    'code': 'pairing_failed',
                    'message': 'The pairing code is incorrect.',
                  },
                ),
              );
              unawaited(socket.close(4003, 'Pairing failed.'));
              return;
            }
            authenticated = true;
            handshakeTimer.cancel();
            _pendingClient = null;
            _client = socket;
            _emit(const HostNetworkEvent(HostNetworkEventType.clientConnected));
            return;
          }
          _emit(
            HostNetworkEvent(HostNetworkEventType.message, message: message),
          );
        } on FormatException catch (error) {
          _sendToSocket(
            socket,
            ProtocolMessage(
              type: MessageType.error,
              payload: <String, Object?>{
                'code': 'invalid_message',
                'message': error.message,
              },
            ),
          );
        }
      },
      onDone: () {
        _finishClient(
          socket,
          handshakeTimer: handshakeTimer,
          alreadyTerminated: terminated,
          markTerminated: () => terminated = true,
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        _finishClient(
          socket,
          handshakeTimer: handshakeTimer,
          alreadyTerminated: terminated,
          markTerminated: () => terminated = true,
          error: error,
        );
        unawaited(socket.close(1011, 'Connection error.'));
      },
      cancelOnError: true,
    );
  }

  void send(ProtocolMessage message) {
    final client = _client;
    if (client != null) {
      _sendToSocket(client, message);
    }
  }

  Future<void> disconnectClient() async {
    final client = _client;
    _client = null;
    if (client != null) {
      await client.close(1000, 'Disconnected by host.');
      _emit(const HostNetworkEvent(HostNetworkEventType.clientDisconnected));
    }
  }

  Future<void> stop() async {
    final client = _client;
    final pending = _pendingClient;
    final server = _server;
    _client = null;
    _pendingClient = null;
    _server = null;
    await client?.close(1001, 'Host server stopped.');
    await pending?.close(1001, 'Host server stopped.');
    await server?.close(force: true);
  }

  void _emitError(String detail) {
    _emit(HostNetworkEvent(HostNetworkEventType.error, detail: detail));
  }

  void _finishClient(
    WebSocket socket, {
    required Timer handshakeTimer,
    required bool alreadyTerminated,
    required void Function() markTerminated,
    Object? error,
  }) {
    if (alreadyTerminated) {
      return;
    }
    markTerminated();
    handshakeTimer.cancel();
    final wasAuthenticated = identical(_client, socket);
    if (identical(_pendingClient, socket)) {
      _pendingClient = null;
    }
    if (wasAuthenticated) {
      _client = null;
      _emit(const HostNetworkEvent(HostNetworkEventType.clientDisconnected));
    }
    if (error != null) {
      _emitError('Client connection error: $error');
    }
  }

  void _sendToSocket(WebSocket socket, ProtocolMessage message) {
    if (socket.readyState == WebSocket.open) {
      socket.add(message.encode());
    }
  }

  void _emit(HostNetworkEvent event) {
    if (!_events.isClosed) {
      _events.add(event);
    }
  }

  Future<void> dispose() async {
    await stop();
    await _events.close();
  }
}
