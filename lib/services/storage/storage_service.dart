import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/host_settings.dart';
import '../../models/player_preferences.dart';

class StorageService {
  static const _hostSettingsKey = 'host_settings_v1';
  static const _playerPreferencesKey = 'player_preferences_v1';

  Future<HostSettings> loadHostSettings() async {
    final preferences = await SharedPreferences.getInstance();
    return _decode(
          preferences.getString(_hostSettingsKey),
          HostSettings.fromJson,
        ) ??
        HostSettings.defaults;
  }

  Future<void> saveHostSettings(HostSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _hostSettingsKey,
      jsonEncode(settings.toJson()),
    );
  }

  Future<PlayerPreferences> loadPlayerPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    return _decode(
          preferences.getString(_playerPreferencesKey),
          PlayerPreferences.fromJson,
        ) ??
        const PlayerPreferences();
  }

  Future<void> savePlayerPreferences(PlayerPreferences value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _playerPreferencesKey,
      jsonEncode(value.toJson()),
    );
  }

  T? _decode<T>(
    String? encoded,
    T Function(Map<String, Object?> value) decoder,
  ) {
    if (encoded == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map) {
        return decoder(Map<String, Object?>.from(decoded));
      }
    } on Object {
      return null;
    }
    return null;
  }
}
