import 'dart:io';
import 'dart:typed_data';

import 'package:buzz_it/controllers/host_controller.dart';
import 'package:buzz_it/models/connection_status.dart';
import 'package:buzz_it/models/host_settings.dart';
import 'package:buzz_it/models/sound_selection.dart';
import 'package:buzz_it/models/team.dart';
import 'package:buzz_it/services/audio/audio_service.dart';
import 'package:buzz_it/services/network/host_server_service.dart';
import 'package:buzz_it/services/network/network_address_service.dart';
import 'package:buzz_it/services/storage/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryStorage extends StorageService {
  HostSettings saved = HostSettings.defaults;
  bool failNextSave = false;

  @override
  Future<HostSettings> loadHostSettings() async => saved;

  @override
  Future<void> saveHostSettings(HostSettings settings) async {
    if (failNextSave) {
      failNextSave = false;
      throw const FileSystemException('private storage details');
    }
    saved = settings;
  }
}

class _FixedAddressService extends NetworkAddressService {
  @override
  Future<List<String>> findLocalIpv4Addresses() async => ['192.168.1.10'];
}

class _TestServer extends HostServerService {
  bool failNextStart = false;
  int? currentPort;

  @override
  int? get boundPort => currentPort;

  @override
  Future<void> start({required int port, required String pairingCode}) async {
    if (failNextStart) {
      failNextStart = false;
      throw const SocketException('private internal bind details');
    }
    currentPort = port;
  }
}

class _RecordingAudio extends AudioService {
  int persistedSounds = 0;
  int discardedSounds = 0;
  int prunedSounds = 0;

  @override
  Future<String> persistSound(Team team, SoundSelection selection) async {
    persistedSounds++;
    return '/tmp/unused-test-sound.wav';
  }

  @override
  Future<void> discardSound(String filePath) async {
    discardedSounds++;
  }

  @override
  Future<void> pruneSounds(Team team, String keepPath) async {
    prunedSounds++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'failed port change keeps saved settings and active pairing details',
    () async {
      final storage = _MemoryStorage();
      final server = _TestServer();
      final audio = _RecordingAudio();
      final controller = HostController(
        storage: storage,
        audio: audio,
        server: server,
        networkAddresses: _FixedAddressService(),
      );
      addTearDown(controller.dispose);
      await controller.initialize();
      final originalPayload = controller.pairingPayload;
      final originalPort = controller.settings.port;
      server.failNextStart = true;

      await expectLater(
        controller.saveSettings(
          match: controller.match,
          soundEnabled: controller.settings.soundEnabled,
          port: originalPort + 1,
          teamASound: SoundSelection(
            fileName: 'replacement.wav',
            extension: '.wav',
            bytes: Uint8List(0),
          ),
        ),
        throwsA(isA<HostSettingsSaveException>()),
      );

      expect(controller.serverStatus, HostServerStatus.listening);
      expect(controller.settings.port, originalPort);
      expect(storage.saved.port, originalPort);
      expect(server.currentPort, originalPort);
      expect(audio.persistedSounds, 0);
      expect(controller.pairingPayload, originalPayload);
      expect(controller.errorMessage, contains('Choose an available port'));
      expect(controller.errorMessage, isNot(contains('private internal')));
    },
  );

  test('storage failure restores the original port and settings', () async {
    final storage = _MemoryStorage();
    final server = _TestServer();
    final controller = HostController(
      storage: storage,
      server: server,
      networkAddresses: _FixedAddressService(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    final originalPort = controller.settings.port;
    storage.failNextSave = true;

    await expectLater(
      controller.saveSettings(
        match: controller.match,
        soundEnabled: controller.settings.soundEnabled,
        port: originalPort + 1,
      ),
      throwsA(isA<HostSettingsSaveException>()),
    );

    expect(server.currentPort, originalPort);
    expect(controller.serverStatus, HostServerStatus.listening);
    expect(controller.settings.port, originalPort);
    expect(storage.saved.port, originalPort);
    expect(controller.errorMessage, contains('Could not save host settings'));
    expect(controller.errorMessage, isNot(contains('private storage')));
  });

  test('failed storage save discards a newly selected sound', () async {
    final storage = _MemoryStorage();
    final audio = _RecordingAudio();
    final controller = HostController(
      storage: storage,
      audio: audio,
      server: _TestServer(),
      networkAddresses: _FixedAddressService(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    storage.failNextSave = true;

    await expectLater(
      controller.saveSettings(
        match: controller.match,
        soundEnabled: controller.settings.soundEnabled,
        port: controller.settings.port,
        teamASound: SoundSelection(
          fileName: 'replacement.wav',
          extension: '.wav',
          bytes: Uint8List(0),
        ),
      ),
      throwsA(isA<HostSettingsSaveException>()),
    );

    expect(audio.persistedSounds, 1);
    expect(audio.discardedSounds, 1);
    expect(audio.prunedSounds, 0);
    expect(controller.settings.teamASoundPath, isNull);
    expect(storage.saved.teamASoundPath, isNull);
  });

  test('does not offer QR pairing when the host failed to start', () async {
    final server = _TestServer()..failNextStart = true;
    final controller = HostController(
      storage: _MemoryStorage(),
      server: server,
      networkAddresses: _FixedAddressService(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    expect(controller.selectedAddress, isNotEmpty);
    expect(controller.serverStatus, HostServerStatus.failed);
    expect(controller.pairingPayload, isNull);
  });
}
