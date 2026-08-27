import '../core/constants.dart';

class PlayerPreferences {
  const PlayerPreferences({
    this.host = '',
    this.port = AppConstants.defaultPort,
    this.pairingCode = '',
    this.hapticsEnabled = true,
  });

  final String host;
  final int port;
  final String pairingCode;
  final bool hapticsEnabled;

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
  }) {
    return PlayerPreferences(
      host: host?.trim() ?? this.host,
      port: port ?? this.port,
      pairingCode: pairingCode ?? this.pairingCode,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'host': host,
      'port': port,
      'pairingCode': pairingCode,
      'hapticsEnabled': hapticsEnabled,
    };
  }

  factory PlayerPreferences.fromJson(Map<String, Object?> json) {
    return PlayerPreferences(
      host: json['host'] as String? ?? '',
      port: json['port'] as int? ?? AppConstants.defaultPort,
      pairingCode: json['pairingCode'] as String? ?? '',
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
    );
  }
}
