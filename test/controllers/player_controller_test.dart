import 'dart:async';

import 'package:buzz_it/controllers/player_controller.dart';
import 'package:buzz_it/models/connection_status.dart';
import 'package:buzz_it/models/player_preferences.dart';
import 'package:buzz_it/services/network/player_client_service.dart';
import 'package:buzz_it/services/storage/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _DelayedStorage extends StorageService {
  final Completer<void> saved = Completer<void>();

  @override
  Future<void> savePlayerPreferences(PlayerPreferences value) => saved.future;
}

class _RecordingClient extends PlayerClientService {
  int connectCalls = 0;

  @override
  Future<void> connect({
    required String host,
    required int port,
    required String pairingCode,
  }) async {
    connectCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'disconnect during preference save cancels pending connection',
    () async {
      final storage = _DelayedStorage();
      final client = _RecordingClient();
      final controller = PlayerController(storage: storage, client: client);
      addTearDown(controller.dispose);

      final pendingConnection = controller.connectWith(
        const PlayerPreferences(host: '192.168.1.10', pairingCode: '123456'),
      );
      await controller.disconnect();
      storage.saved.complete();
      await pendingConnection;

      expect(client.connectCalls, 0);
      expect(controller.status, PlayerConnectionStatus.disconnected);
    },
  );
}
