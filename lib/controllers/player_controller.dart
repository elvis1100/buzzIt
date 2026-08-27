import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/connection_status.dart';
import '../models/game_state.dart';
import '../models/match_configuration.dart';
import '../models/player_preferences.dart';
import '../models/protocol_message.dart';
import '../models/team.dart';
import '../services/network/player_client_service.dart';
import '../services/pairing/pairing_service.dart';
import '../services/storage/storage_service.dart';

class PlayerController extends ChangeNotifier {
  PlayerController({StorageService? storage, PlayerClientService? client})
    : _storage = storage ?? StorageService(),
      _client = client ?? PlayerClientService();

  final StorageService _storage;
  final PlayerClientService _client;

  PlayerPreferences _preferences = const PlayerPreferences();
  MatchConfiguration _match = MatchConfiguration.defaults;
  GameState _gameState = const GameState.initial();
  PlayerConnectionStatus _status = PlayerConnectionStatus.disconnected;
  Team? _optimisticWinner;
  String? _errorMessage;
  bool _initialized = false;
  bool _manualDisconnect = false;
  bool _disposed = false;
  int _retryAttempt = 0;
  Timer? _reconnectTimer;
  StreamSubscription<PlayerNetworkEvent>? _networkSubscription;

  PlayerPreferences get preferences => _preferences;
  MatchConfiguration get match => _match;
  GameState get gameState => _gameState;
  PlayerConnectionStatus get status => _status;
  Team? get optimisticWinner => _optimisticWinner;
  String? get errorMessage => _errorMessage;
  bool get initialized => _initialized;
  bool get isConnected => status == PlayerConnectionStatus.connected;
  bool get canBuzz =>
      isConnected && gameState.isReady && optimisticWinner == null;

  Team? get displayedWinner => gameState.winner ?? optimisticWinner;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _networkSubscription = _client.events.listen(_handleNetworkEvent);
    _preferences = await _storage.loadPlayerPreferences();
    _initialized = true;
    _notify();
    if (preferences.hasConnectionDetails) {
      unawaited(connectWith(preferences));
    }
  }

  Future<void> connect({
    required String host,
    required int port,
    required String pairingCode,
  }) {
    return connectWith(
      preferences.copyWith(host: host, port: port, pairingCode: pairingCode),
    );
  }

  Future<void> connectWith(PlayerPreferences value) async {
    _reconnectTimer?.cancel();
    _manualDisconnect = false;
    _preferences = value;
    await _storage.savePlayerPreferences(preferences);
    _status = _retryAttempt == 0
        ? PlayerConnectionStatus.connecting
        : PlayerConnectionStatus.reconnecting;
    _errorMessage = null;
    _notify();
    try {
      await _client.connect(
        host: preferences.host,
        port: preferences.port,
        pairingCode: preferences.pairingCode,
      );
    } on Object {
      _scheduleReconnect();
    }
  }

  Future<void> connectFromQr(String rawValue) async {
    final payload = PairingPayload.tryParse(rawValue);
    if (payload == null) {
      _errorMessage = 'That QR code is not a valid BuzzIt pairing code.';
      _notify();
      return;
    }
    await connect(
      host: payload.host,
      port: payload.port,
      pairingCode: payload.code,
    );
  }

  void _handleNetworkEvent(PlayerNetworkEvent event) {
    switch (event.type) {
      case PlayerNetworkEventType.socketOpened:
        _status = PlayerConnectionStatus.pairing;
      case PlayerNetworkEventType.disconnected:
        _status = PlayerConnectionStatus.disconnected;
        _optimisticWinner = null;
        if (!_manualDisconnect) {
          _errorMessage = event.detail ?? 'The host connection was lost.';
          _scheduleReconnect();
        }
      case PlayerNetworkEventType.message:
        final message = event.message;
        if (message != null) {
          _handleMessage(message);
        }
      case PlayerNetworkEventType.error:
        _errorMessage = event.detail;
    }
    _notify();
  }

  void _handleMessage(ProtocolMessage message) {
    switch (message.type) {
      case MessageType.welcome:
        _retryAttempt = 0;
        _status = PlayerConnectionStatus.connected;
        _applyStatePayload(message.payload);
      case MessageType.stateSync:
        _applyStatePayload(message.payload);
      case MessageType.error:
        _errorMessage =
            message.payload['message'] as String? ??
            'The host rejected the request.';
        final code = message.payload['code'];
        if (code == 'pairing_failed' || code == 'client_limit') {
          _manualDisconnect = true;
          _status = PlayerConnectionStatus.disconnected;
          unawaited(_client.disconnect());
        }
      case MessageType.ping:
        _client.send(ProtocolMessage(type: MessageType.pong));
      case MessageType.hello:
      case MessageType.buzzAttempt:
      case MessageType.settingsUpdate:
      case MessageType.pong:
        break;
    }
  }

  void _applyStatePayload(Map<String, Object?> payload) {
    final rawState = payload['state'];
    final rawMatch = payload['match'];
    if (rawState is Map) {
      _gameState = GameState.fromJson(Map<String, Object?>.from(rawState));
      _optimisticWinner = null;
    }
    if (rawMatch is Map) {
      _match = MatchConfiguration.fromJson(Map<String, Object?>.from(rawMatch));
    }
  }

  Future<void> buzz(Team team) async {
    if (!canBuzz) {
      return;
    }
    _optimisticWinner = team;
    _notify();
    if (preferences.hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
    _client.send(
      ProtocolMessage(
        type: MessageType.buzzAttempt,
        roundId: gameState.roundId,
        payload: <String, Object?>{'team': team.wireValue},
      ),
    );
  }

  Future<void> updateTeams({
    required String teamAName,
    required String teamBName,
    required int teamAColor,
    required int teamBColor,
  }) async {
    if (!isConnected) {
      return;
    }
    _match = match.copyWith(
      teamAName: teamAName,
      teamBName: teamBName,
      teamAColor: teamAColor,
      teamBColor: teamBColor,
    );
    _client.send(
      ProtocolMessage(
        type: MessageType.settingsUpdate,
        payload: <String, Object?>{'match': match.toJson()},
      ),
    );
    _notify();
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    _preferences = preferences.copyWith(hapticsEnabled: enabled);
    await _storage.savePlayerPreferences(preferences);
    _notify();
  }

  Future<void> disconnect() async {
    _manualDisconnect = true;
    _retryAttempt = 0;
    _reconnectTimer?.cancel();
    _status = PlayerConnectionStatus.disconnected;
    _optimisticWinner = null;
    await _client.disconnect();
    _notify();
  }

  void _scheduleReconnect() {
    if (_manualDisconnect || !preferences.hasConnectionDetails || _disposed) {
      return;
    }
    _reconnectTimer?.cancel();
    _retryAttempt++;
    final seconds = switch (_retryAttempt) {
      1 => 1,
      2 => 2,
      3 => 4,
      _ => 8,
    };
    _status = PlayerConnectionStatus.reconnecting;
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      unawaited(connectWith(preferences));
    });
    _notify();
  }

  void clearError() {
    _errorMessage = null;
    _notify();
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    unawaited(_networkSubscription?.cancel());
    unawaited(_client.dispose());
    super.dispose();
  }
}
