import '../core/constants.dart';
import 'match_configuration.dart';

class HostSettings {
  const HostSettings({
    required this.match,
    required this.port,
    this.teamASoundPath,
    this.teamBSoundPath,
  });

  static const defaults = HostSettings(
    match: MatchConfiguration.defaults,
    port: AppConstants.defaultPort,
  );

  final MatchConfiguration match;
  final int port;
  final String? teamASoundPath;
  final String? teamBSoundPath;

  HostSettings copyWith({
    MatchConfiguration? match,
    int? port,
    String? teamASoundPath,
    String? teamBSoundPath,
  }) {
    return HostSettings(
      match: match ?? this.match,
      port: (port ?? this.port).clamp(
        AppConstants.minimumPort,
        AppConstants.maximumPort,
      ),
      teamASoundPath: teamASoundPath ?? this.teamASoundPath,
      teamBSoundPath: teamBSoundPath ?? this.teamBSoundPath,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'match': match.toJson(),
      'port': port,
      'teamASoundPath': teamASoundPath,
      'teamBSoundPath': teamBSoundPath,
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
    );
  }
}
