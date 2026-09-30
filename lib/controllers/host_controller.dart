import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/connection_status.dart';
import '../models/game_state.dart';
import '../models/host_settings.dart';
import '../models/match_configuration.dart';
import '../models/protocol_message.dart';
import '../models/sound_selection.dart';
import '../models/team.dart';
import '../services/audio/audio_service.dart';
import '../services/network/host_server_service.dart';
import '../services/network/network_address_service.dart';
import '../services/pairing/pairing_service.dart';
import '../services/storage/storage_service.dart';

/// A recoverable settings failure with a message suitable for the dialog.
class HostSettingsSaveException implements Exception {
  const HostSettingsSaveException(this.message);

  final String message;
}

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

  String? get pairingPayload {
    if (selectedAddress.isEmpty || serverStatus != HostServerStatus.listening) {
      return null;
    }
    return PairingPayload(
      host: selectedAddress,
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
    final startupWarnings = <String>[];
    try {
      _settings = await _storage.loadHostSettings();
    } on Object {
      startupWarnings.add(
        'Could not load saved host settings. Defaults are in use.',
      );
    }
    try {
      _localAddresses = await _networkAddresses.findLocalIpv4Addresses();
      _selectedAddress = _localAddresses.firstOrNull ?? '';
    } on Object {
      startupWarnings.add(
        'Could not detect local network addresses. Check the network connection.',
      );
    }
    await _startServer();
    if (_serverStatus == HostServerStatus.listening &&
        startupWarnings.isNotEmpty) {
      _errorMessage = startupWarnings.join('\n');
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
    } on Object {
      _serverStatus = HostServerStatus.failed;
      _errorMessage =
          'Could not listen on port ${settings.port}. Choose an available port.';
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
        _errorMessage =
            'A network error occurred. Check the connection and try again.';
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
        final requestedMatch = rawMatch is Map
            ? MatchConfiguration.fromJson(Map<String, Object?>.from(rawMatch))
            : null;
        final mobileSoundEnabled = message.payload['mobileSoundEnabled'];
        if (requestedMatch != null || mobileSoundEnabled is bool) {
          unawaited(
            _applyPlayerSettings(
              match: requestedMatch,
              mobileSoundEnabled: mobileSoundEnabled is bool
                  ? mobileSoundEnabled
                  : null,
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
      unawaited(_playWinnerSound(team));
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
          'mobileSoundEnabled': settings.mobileSoundEnabled,
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
          'mobileSoundEnabled': settings.mobileSoundEnabled,
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
    final nextSettings = settings.copyWith(match: value);
    try {
      await _storage.saveHostSettings(nextSettings);
    } on Object {
      _errorMessage = 'Could not save match settings. Try again.';
      _notify();
      return;
    }
    _settings = nextSettings;
    _sendState();
    _notify();
  }

  /// Enables or mutes buzzer audio played on the paired phone.
  Future<void> setMobileSoundEnabled(bool enabled) async {
    final nextSettings = settings.copyWith(mobileSoundEnabled: enabled);
    try {
      await _storage.saveHostSettings(nextSettings);
    } on Object {
      _errorMessage = 'Could not save phone sound setting. Try again.';
      _notify();
      return;
    }
    _settings = nextSettings;
    _sendState();
    _notify();
  }

  Future<void> _applyPlayerSettings({
    MatchConfiguration? match,
    bool? mobileSoundEnabled,
  }) async {
    final nextMatch = match == null
        ? settings.match
        : settings.match.copyWith(
            teamAName: match.teamAName,
            teamBName: match.teamBName,
            teamAColor: match.teamAColor,
            teamBColor: match.teamBColor,
          );
    final nextSettings = settings.copyWith(
      match: nextMatch,
      mobileSoundEnabled: mobileSoundEnabled,
    );
    try {
      await _storage.saveHostSettings(nextSettings);
    } on Object {
      _errorMessage = 'Could not save buzzer settings. Try again.';
      _sendError('settings_save_failed', 'Could not save buzzer settings.');
      _sendState();
      _notify();
      return;
    }
    _settings = nextSettings;
    _sendState();
    _notify();
  }

  Future<SoundSelection?> chooseSound() {
    return _audio.chooseSound();
  }

  Future<void> previewSound(Team team, SoundSelection selection) {
    return _audio.previewSelection(team, selection);
  }

  /// Saves a host settings draft. A changed port is bound before the old
  /// listener closes; failures keep the previous settings and surface a
  /// [HostSettingsSaveException] for the dialog to show.
  Future<void> saveSettings({
    required MatchConfiguration match,
    required bool soundEnabled,
    required int port,
    SoundSelection? teamASound,
    SoundSelection? teamBSound,
  }) async {
    final previousSettings = settings;
    final nextPort = port.clamp(
      AppConstants.minimumPort,
      AppConstants.maximumPort,
    );
    final portChanged = nextPort != previousSettings.port;
    if (portChanged) {
      final wasListening = _serverStatus == HostServerStatus.listening;
      _serverStatus = HostServerStatus.starting;
      _notify();
      try {
        await _server.start(port: nextPort, pairingCode: pairingCode);
      } on Object {
        _serverStatus = wasListening
            ? HostServerStatus.listening
            : HostServerStatus.failed;
        _errorMessage =
            'Could not listen on port $nextPort. Choose an available port.';
        _notify();
        throw HostSettingsSaveException(_errorMessage!);
      }
      _clientConnected = false;
      _serverStatus = HostServerStatus.listening;
    }

    String? persistedASound;
    String? persistedBSound;
    late final HostSettings nextSettings;
    try {
      if (teamASound != null) {
        persistedASound = await _audio.persistSound(Team.a, teamASound);
      }
      if (teamBSound != null) {
        persistedBSound = await _audio.persistSound(Team.b, teamBSound);
      }
      nextSettings = HostSettings(
        match: match,
        port: nextPort,
        teamASoundPath: persistedASound ?? previousSettings.teamASoundPath,
        teamBSoundPath: persistedBSound ?? previousSettings.teamBSoundPath,
        soundEnabled: soundEnabled,
        mobileSoundEnabled: previousSettings.mobileSoundEnabled,
      );
      await _storage.saveHostSettings(nextSettings);
    } on Object {
      // New sounds are separate files, so failed saves leave the selected
      // sounds untouched. Cleanup is best effort; the next save prunes leftovers.
      for (final filePath in <String?>[persistedASound, persistedBSound]) {
        if (filePath != null) {
          try {
            await _audio.discardSound(filePath);
          } on Object {
            // Preserve the original save failure and restore the host port.
          }
        }
      }
      if (portChanged) {
        try {
          await _server.start(
            port: previousSettings.port,
            pairingCode: pairingCode,
          );
          _serverStatus = HostServerStatus.listening;
        } on Object {
          try {
            await _server.stop();
          } on Object {
            // The listener is already unusable; report the failed recovery.
          }
          _serverStatus = HostServerStatus.failed;
          _errorMessage =
              'Could not restore the previous host port. Restart the host and check the port.';
          _notify();
          throw HostSettingsSaveException(_errorMessage!);
        }
      }
      _errorMessage = 'Could not save host settings. Try again.';
      _notify();
      throw HostSettingsSaveException(_errorMessage!);
    }

    _settings = nextSettings;
    _errorMessage = null;
    _sendState();
    _notify();
    try {
      if (persistedASound != null) {
        await _audio.pruneSounds(Team.a, persistedASound);
      }
      if (persistedBSound != null) {
        await _audio.pruneSounds(Team.b, persistedBSound);
      }
    } on Object {
      _errorMessage =
          'Settings saved, but older sound files could not be removed.';
      _notify();
    }
  }

  Future<void> _playWinnerSound(Team team) async {
    try {
      await testSound(team);
    } on Object {
      _errorMessage =
          'Could not play the buzzer sound. Choose another sound or try again.';
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
