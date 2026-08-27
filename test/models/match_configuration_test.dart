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
}
