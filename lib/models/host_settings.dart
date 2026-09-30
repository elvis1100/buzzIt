import '../core/constants.dart';
import 'match_configuration.dart';

class HostSettings {
  const HostSettings({
    required this.match,
    required this.port,
    this.teamASoundPath,
    this.teamBSoundPath,
    this.soundEnabled = true,
    this.mobileSoundEnabled = true,
  });

  static const defaults = HostSettings(
    match: MatchConfiguration.defaults,
    port: AppConstants.defaultPort,
  );

  final MatchConfiguration match;
  final int port;
  final String? teamASoundPath;
  final String? teamBSoundPath;
  final bool soundEnabled;
  final bool mobileSoundEnabled;

  HostSettings copyWith({
    MatchConfiguration? match,
    int? port,
    String? teamASoundPath,
    String? teamBSoundPath,
    bool? soundEnabled,
    bool? mobileSoundEnabled,
  }) {
    return HostSettings(
      match: match ?? this.match,
      port: (port ?? this.port).clamp(
        AppConstants.minimumPort,
        AppConstants.maximumPort,
      ),
      teamASoundPath: teamASoundPath ?? this.teamASoundPath,
      teamBSoundPath: teamBSoundPath ?? this.teamBSoundPath,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      mobileSoundEnabled: mobileSoundEnabled ?? this.mobileSoundEnabled,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'match': match.toJson(),
      'port': port,
      'teamASoundPath': teamASoundPath,
      'teamBSoundPath': teamBSoundPath,
      'soundEnabled': soundEnabled,
      'mobileSoundEnabled': mobileSoundEnabled,
    };
  }

  factory HostSettings.fromJson(Map<String, Object?> json) {
    final rawMatch = json['match'];
    final matchMap = rawMatch is Map
        ? Map<String, Object?>.from(rawMatch)
        : <String, Object?>{};
    final teamASoundPath = json['teamASoundPath'];
    final teamBSoundPath = json['teamBSoundPath'];
    final soundEnabled = json['soundEnabled'];
    final mobileSoundEnabled = json['mobileSoundEnabled'];
    return HostSettings(
      match: MatchConfiguration.fromJson(matchMap),
      port: json['port'] is int
          ? (json['port']! as int).clamp(
              AppConstants.minimumPort,
              AppConstants.maximumPort,
            )
          : AppConstants.defaultPort,
      teamASoundPath: teamASoundPath is String ? teamASoundPath : null,
      teamBSoundPath: teamBSoundPath is String ? teamBSoundPath : null,
      soundEnabled: soundEnabled is bool ? soundEnabled : true,
      mobileSoundEnabled: mobileSoundEnabled is bool
          ? mobileSoundEnabled
          : true,
    );
  }
}
