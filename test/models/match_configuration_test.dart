import 'package:buzz_it/core/constants.dart';
import 'package:buzz_it/models/match_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sanitizes team names and reset duration', () {
    final configuration = MatchConfiguration.defaults.copyWith(
      teamAName: '   ',
      teamBName: 'A name that is intentionally much too long for the UI',
      autoResetSeconds: 99,
    );

    expect(configuration.teamAName, 'Team A');
    expect(configuration.teamBName.length, AppConstants.maximumTeamNameLength);
    expect(configuration.autoResetSeconds, AppConstants.maximumResetSeconds);
  });

  test('uses safe defaults for malformed persisted values', () {
    final configuration = MatchConfiguration.fromJson(<String, Object?>{
      'teamAName': 12,
      'teamBColor': -1,
      'autoResetEnabled': 'yes',
      'autoResetSeconds': 'five',
    });

    expect(configuration.teamAName, MatchConfiguration.defaults.teamAName);
    expect(configuration.teamBColor, MatchConfiguration.defaults.teamBColor);
    expect(
      configuration.autoResetEnabled,
      MatchConfiguration.defaults.autoResetEnabled,
    );
    expect(
      configuration.autoResetSeconds,
      MatchConfiguration.defaults.autoResetSeconds,
    );
  });
}
