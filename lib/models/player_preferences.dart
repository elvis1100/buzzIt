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
        RegExp(r'^\d{6}$').hasMatch(pairingCode);
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
    final host = json['host'];
    final port = json['port'];
    final pairingCode = json['pairingCode'];
    final hapticsEnabled = json['hapticsEnabled'];
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
    );
  }
}
