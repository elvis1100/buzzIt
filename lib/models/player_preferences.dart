import '../core/constants.dart';

class PlayerPreferences {
  const PlayerPreferences({
    this.host = '',
    this.port = AppConstants.defaultPort,
    this.pairingCode = '',
    this.hapticsEnabled = true,
    this.soundEnabled = true,
  });

  final String host;
  final int port;
  final String pairingCode;
  final bool hapticsEnabled;
  final bool soundEnabled;

  bool get hasConnectionDetails {
    return host.trim().isNotEmpty &&
        port >= AppConstants.minimumPort &&
        port <= AppConstants.maximumPort &&
        pairingCode.length == AppConstants.pairingCodeLength;
  }

  PlayerPreferences copyWith({
    String? host,
    int? port,
    String? pairingCode,
    bool? hapticsEnabled,
    bool? soundEnabled,
  }) {
    return PlayerPreferences(
      host: host?.trim() ?? this.host,
      port: port ?? this.port,
      pairingCode: pairingCode ?? this.pairingCode,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'host': host,
      'port': port,
      'pairingCode': pairingCode,
      'hapticsEnabled': hapticsEnabled,
      'soundEnabled': soundEnabled,
    };
  }

  factory PlayerPreferences.fromJson(Map<String, Object?> json) {
    return PlayerPreferences(
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? AppConstants.defaultPort,
      pairingCode: json['pairingCode'] as String? ?? '',
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
    );
  }
}
