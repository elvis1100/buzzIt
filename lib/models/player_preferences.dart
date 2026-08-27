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
        RegExp(r'^\d{6}$').hasMatch(pairingCode);
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
    final host = json['host'];
    final port = json['port'];
    final pairingCode = json['pairingCode'];
    final hapticsEnabled = json['hapticsEnabled'];
    final soundEnabled = json['soundEnabled'];
    return PlayerPreferences(
      host: host is String ? host.trim() : '',
      port:
          port is int &&
              port >= AppConstants.minimumPort &&
              port <= AppConstants.maximumPort
          ? port
          : AppConstants.defaultPort,
      pairingCode: pairingCode is String ? pairingCode : '',
      hapticsEnabled: hapticsEnabled is bool ? hapticsEnabled : true,
      soundEnabled: soundEnabled is bool ? soundEnabled : true,
    );
  }
}
