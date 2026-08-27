import 'package:buzz_it/core/constants.dart';
import 'package:buzz_it/models/host_settings.dart';
import 'package:buzz_it/models/match_configuration.dart';
import 'package:buzz_it/services/storage/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('falls back safely when saved values have invalid types', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'host_settings_v1':
          '{"port":"bad","match":{"teamAName":12,"teamBColor":-1}}',
      'player_preferences_v1': '{"host":12,"port":"bad","pairingCode":123456}',
    });
    final storage = StorageService();

    final host = await storage.loadHostSettings();
    final player = await storage.loadPlayerPreferences();

    expect(host.port, AppConstants.defaultPort);
    expect(host.match.teamAName, MatchConfiguration.defaults.teamAName);
    expect(host.match.teamBColor, MatchConfiguration.defaults.teamBColor);
    expect(player.host, isEmpty);
    expect(player.port, AppConstants.defaultPort);
    expect(player.hasConnectionDetails, isFalse);
  });

  test('falls back safely when saved JSON is corrupted', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'host_settings_v1': '{not-json',
      'player_preferences_v1': '[]',
    });
    final storage = StorageService();

    expect(await storage.loadHostSettings(), same(HostSettings.defaults));
    expect(
      (await storage.loadPlayerPreferences()).hasConnectionDetails,
      isFalse,
    );
  });
}
