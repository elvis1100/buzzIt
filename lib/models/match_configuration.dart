import '../core/constants.dart';

class MatchConfiguration {
  const MatchConfiguration({
    required this.teamAName,
    required this.teamBName,
    required this.teamAColor,
    required this.teamBColor,
    required this.autoResetEnabled,
    required this.autoResetSeconds,
  });

  static const defaults = MatchConfiguration(
    teamAName: 'Team A',
    teamBName: 'Team B',
    teamAColor: 0xFF075A91,
    teamBColor: 0xFFF1A606,
    autoResetEnabled: true,
    autoResetSeconds: AppConstants.defaultResetSeconds,
  );

  final String teamAName;
  final String teamBName;
  final int teamAColor;
  final int teamBColor;
  final bool autoResetEnabled;
  final int autoResetSeconds;

  Duration? get autoResetDuration =>
      autoResetEnabled ? Duration(seconds: autoResetSeconds) : null;

  MatchConfiguration copyWith({
    String? teamAName,
    String? teamBName,
    int? teamAColor,
    int? teamBColor,
    bool? autoResetEnabled,
    int? autoResetSeconds,
  }) {
    return MatchConfiguration(
      teamAName: _cleanName(teamAName ?? this.teamAName, 'Team A'),
      teamBName: _cleanName(teamBName ?? this.teamBName, 'Team B'),
      teamAColor: teamAColor ?? this.teamAColor,
      teamBColor: teamBColor ?? this.teamBColor,
      autoResetEnabled: autoResetEnabled ?? this.autoResetEnabled,
      autoResetSeconds: (autoResetSeconds ?? this.autoResetSeconds).clamp(
        AppConstants.minimumResetSeconds,
        AppConstants.maximumResetSeconds,
      ),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'teamAName': teamAName,
      'teamBName': teamBName,
      'teamAColor': teamAColor,
      'teamBColor': teamBColor,
      'autoResetEnabled': autoResetEnabled,
      'autoResetSeconds': autoResetSeconds,
    };
  }

  factory MatchConfiguration.fromJson(Map<String, Object?> json) {
    final resetSeconds = json['autoResetSeconds'];
    return defaults.copyWith(
      teamAName: json['teamAName'] as String?,
      teamBName: json['teamBName'] as String?,
      teamAColor: json['teamAColor'] as int?,
      teamBColor: json['teamBColor'] as int?,
      autoResetEnabled: json['autoResetEnabled'] as bool?,
      autoResetSeconds: resetSeconds is int ? resetSeconds : null,
    );
  }

  static String _cleanName(String value, String fallback) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return fallback;
    }
    if (trimmed.length <= AppConstants.maximumTeamNameLength) {
      return trimmed;
    }
    return trimmed.substring(0, AppConstants.maximumTeamNameLength);
  }
}
