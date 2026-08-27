import '../core/constants.dart';
import 'match_configuration.dart';

class HostSettings {
  const HostSettings({
    required this.match,
    required this.port,
    this.teamASoundPath,
    this.teamBSoundPath,
    this.soundEnabled = true,
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

  HostSettings copyWith({
    MatchConfiguration? match,
    int? port,
    String? teamASoundPath,
    String? teamBSoundPath,
    bool? soundEnabled,
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
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'match': match.toJson(),
      'port': port,
      'teamASoundPath': teamASoundPath,
      'teamBSoundPath': teamBSoundPath,
      'soundEnabled': soundEnabled,
    };
  }

  factory HostSettings.fromJson(Map<String, Object?> json) {
    final rawMatch = json['match'];
    final matchMap = rawMatch is Map
        ? Map<String, Object?>.from(rawMatch)
        : <String, Object?>{};
    return HostSettings(
      match: MatchConfiguration.fromJson(matchMap),
      port: json['port'] is int
          ? (json['port']! as int).clamp(
              AppConstants.minimumPort,
              AppConstants.maximumPort,
            )
          : AppConstants.defaultPort,
      teamASoundPath: json['teamASoundPath'] as String?,
      teamBSoundPath: json['teamBSoundPath'] as String?,
      soundEnabled: json['soundEnabled'] as bool? ?? true,
    );
  }
}
