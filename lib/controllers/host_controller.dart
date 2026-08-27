import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/connection_status.dart';
import '../models/game_state.dart';
import '../models/host_settings.dart';
import '../models/match_configuration.dart';
import '../models/protocol_message.dart';
import '../models/team.dart';
import '../services/audio/audio_service.dart';
import '../services/network/host_server_service.dart';
import '../services/network/network_address_service.dart';
import '../services/pairing/pairing_service.dart';
import '../services/storage/storage_service.dart';

class HostController extends ChangeNotifier {
  HostController({
    StorageService? storage,
    AudioService? audio,
    HostServerService? server,
    NetworkAddressService? networkAddresses,
    PairingService? pairing,
  }) : _storage = storage ?? StorageService(),
       _audio = audio ?? AudioService(),
       _server = server ?? HostServerService(),
       _networkAddresses = networkAddresses ?? NetworkAddressService(),
       _pairing = pairing ?? PairingService();

  final StorageService _storage;
  final AudioService _audio;
  final HostServerService _server;
  final NetworkAddressService _networkAddresses;
  final PairingService _pairing;

  HostSettings _settings = HostSettings.defaults;
  GameState _gameState = const GameState.initial();
  HostServerStatus _serverStatus = HostServerStatus.starting;
  List<String> _localAddresses = const <String>[];
  String _selectedAddress = '';
  String _pairingCode = '';
  bool _clientConnected = false;
  bool _initialized = false;
  bool _disposed = false;
  String? _errorMessage;
  Timer? _resetTimer;
  Timer? _countdownTicker;
  StreamSubscription<HostNetworkEvent>? _networkSubscription;

  HostSettings get settings => _settings;
  MatchConfiguration get match => _settings.match;
  GameState get gameState => _gameState;
  HostServerStatus get serverStatus => _serverStatus;
  List<String> get localAddresses => _localAddresses;
  String get selectedAddress => _selectedAddress;
  String get pairingCode => _pairingCode;
  bool get clientConnected => _clientConnected;
  bool get initialized => _initialized;
  String? get errorMessage => _errorMessage;

  String get pairingPayload {
    return PairingPayload(
      host: selectedAddress.isEmpty ? '127.0.0.1' : selectedAddress,
      port: settings.port,
      code: pairingCode,
    ).encode();
  }

  int? get remainingResetSeconds {
    final resetAt = gameState.resetAt;
    if (resetAt == null) {
      return null;
    }
    final milliseconds = resetAt
        .difference(DateTime.now().toUtc())
        .inMilliseconds;
    if (milliseconds <= 0) {
      return 0;
    }
    return (milliseconds / 1000).ceil();
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _networkSubscription = _server.events.listen(_handleNetworkEvent);
    _pairingCode = _pairing.generateCode();
    try {
      final results = await Future.wait<Object>(<Future<Object>>[
        _storage.loadHostSettings(),
        _networkAddresses.findLocalIpv4Addresses(),
      ]);
      _settings = results[0] as HostSettings;
      _localAddresses = results[1] as List<String>;
      _selectedAddress = _localAddresses.firstOrNull ?? '';
      await _startServer();
    } on Object catch (error) {
      _serverStatus = HostServerStatus.failed;
      _errorMessage = 'Host startup failed: $error';
    }
    _initialized = true;
    _notify();
  }

  Future<void> _startServer() async {
    _serverStatus = HostServerStatus.starting;
    _notify();
    try {
      await _server.start(port: settings.port, pairingCode: pairingCode);
      _serverStatus = HostServerStatus.listening;
      _errorMessage = null;
    } on Object catch (error) {
      _serverStatus = HostServerStatus.failed;
      _errorMessage = 'Could not listen on port ${settings.port}: $error';
    }
    _notify();
  }

  void _handleNetworkEvent(HostNetworkEvent event) {
    switch (event.type) {
      case HostNetworkEventType.clientConnected:
        _clientConnected = true;
        _sendWelcome();
      case HostNetworkEventType.clientDisconnected:
        _clientConnected = false;
      case HostNetworkEventType.message:
        final message = event.message;
        if (message != null) {
          _handleMessage(message);
        }
      case HostNetworkEventType.error:
        _errorMessage = event.detail;
    }
    _notify();
  }

  void _handleMessage(ProtocolMessage message) {
    switch (message.type) {
      case MessageType.buzzAttempt:
        final team = TeamValue.fromWireValue(message.payload['team']);
        final attemptedRound = message.roundId;
        if (team == null || attemptedRound == null) {
          _sendError('invalid_buzz', 'The buzz attempt was incomplete.');
          return;
        }
        _acceptBuzz(team, attemptedRound);
      case MessageType.settingsUpdate:
        final rawMatch = message.payload['match'];
        if (rawMatch is Map) {
          final requested = MatchConfiguration.fromJson(
            Map<String, Object?>.from(rawMatch),
          );
          unawaited(
            updateMatch(
              match.copyWith(
                teamAName: requested.teamAName,
                teamBName: requested.teamBName,
                teamAColor: requested.teamAColor,
                teamBColor: requested.teamBColor,
              ),
            ),
          );
        }
      case MessageType.ping:
        _server.send(ProtocolMessage(type: MessageType.pong));
      case MessageType.hello:
      case MessageType.welcome:
      case MessageType.stateSync:
      case MessageType.pong:
      case MessageType.error:
        break;
    }
  }

  void _acceptBuzz(Team team, int attemptedRound) {
    final next = gameState.acceptBuzz(
      team: team,
      attemptedRoundId: attemptedRound,
      now: DateTime.now(),
      autoResetAfter: match.autoResetDuration,
    );
    if (identical(next, gameState)) {
      _sendState();
      return;
    }
    _gameState = next;
    if (settings.soundEnabled) {
      unawaited(
        _audio.play(
          team,
          customPath: team == Team.a
              ? settings.teamASoundPath
              : settings.teamBSoundPath,
        ),
      );
    }
    _scheduleReset();
    _sendState();
    _notify();
  }

  void _scheduleReset() {
    _resetTimer?.cancel();
    _countdownTicker?.cancel();
    final resetAt = gameState.resetAt;
    if (resetAt == null) {
      return;
    }
    final delay = resetAt.difference(DateTime.now().toUtc());
    if (delay <= Duration.zero) {
      resetRound();
      return;
    }
    _resetTimer = Timer(delay, resetRound);
    _countdownTicker = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _notify(),
    );
  }

  void resetRound() {
    _resetTimer?.cancel();
    _countdownTicker?.cancel();
    _resetTimer = null;
    _countdownTicker = null;
    _gameState = gameState.reset();
    _sendState();
    _notify();
  }

  void _sendWelcome() {
    _server.send(
      ProtocolMessage(
        type: MessageType.welcome,
        roundId: gameState.roundId,
        payload: <String, Object?>{
          'state': gameState.toJson(),
          'match': match.toJson(),
        },
      ),
    );
  }

  void _sendState() {
    _server.send(
      ProtocolMessage(
        type: MessageType.stateSync,
        roundId: gameState.roundId,
        payload: <String, Object?>{
          'state': gameState.toJson(),
          'match': match.toJson(),
        },
      ),
    );
  }

  void _sendError(String code, String message) {
    _server.send(
      ProtocolMessage(
        type: MessageType.error,
        payload: <String, Object?>{'code': code, 'message': message},
      ),
    );
  }

  Future<void> updateMatch(MatchConfiguration value) async {
    _settings = settings.copyWith(match: value);
    await _storage.saveHostSettings(settings);
    _sendState();
    _notify();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _settings = settings.copyWith(soundEnabled: enabled);
    await _storage.saveHostSettings(settings);
    _notify();
  }

  Future<void> updatePort(int port) async {
    if (port == settings.port) {
      return;
    }
    _settings = settings.copyWith(port: port);
    await _storage.saveHostSettings(settings);
    _clientConnected = false;
    await _startServer();
  }

  Future<void> selectSound(Team team) async {
    try {
      final imported = await _audio.importSound(team);
      if (imported == null) {
        return;
      }
      _settings = team == Team.a
          ? settings.copyWith(teamASoundPath: imported)
          : settings.copyWith(teamBSoundPath: imported);
      await _storage.saveHostSettings(settings);
      await testSound(team);
      _notify();
    } on Object catch (error) {
      _errorMessage = 'Could not import the sound: $error';
      _notify();
    }
  }

  Future<void> testSound(Team team) {
    return _audio.play(
      team,
      customPath: team == Team.a
          ? settings.teamASoundPath
          : settings.teamBSoundPath,
    );
  }

  Future<void> refreshPairingCode() async {
    _pairingCode = _pairing.generateCode();
    _clientConnected = false;
    await _startServer();
  }

  void selectAddress(String value) {
    if (!_localAddresses.contains(value)) {
      return;
    }
    _selectedAddress = value;
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
    _resetTimer?.cancel();
    _countdownTicker?.cancel();
    unawaited(_networkSubscription?.cancel());
    unawaited(_server.dispose());
    unawaited(_audio.dispose());
    super.dispose();
  }
}
