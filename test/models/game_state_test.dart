import 'package:buzz_it/models/game_state.dart';
import 'package:buzz_it/models/team.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameState', () {
    test('accepts only the first buzz in the active round', () {
      const initial = GameState.initial();
      final acceptedAt = DateTime.utc(2026, 8, 27, 12);

      final accepted = initial.acceptBuzz(
        team: Team.a,
        attemptedRoundId: 1,
        now: acceptedAt,
        autoResetAfter: const Duration(seconds: 5),
      );
      final duplicate = accepted.acceptBuzz(
        team: Team.b,
        attemptedRoundId: 1,
        now: acceptedAt.add(const Duration(milliseconds: 1)),
        autoResetAfter: const Duration(seconds: 5),
      );

      expect(accepted.phase, RoundPhase.locked);
      expect(accepted.winner, Team.a);
      expect(accepted.resetAt, acceptedAt.add(const Duration(seconds: 5)));
      expect(identical(duplicate, accepted), isTrue);
    });

    test('rejects stale round attempts and increments on reset', () {
      const initial = GameState.initial();
      final stale = initial.acceptBuzz(
        team: Team.a,
        attemptedRoundId: 0,
        now: DateTime.now(),
        autoResetAfter: null,
      );
      final reset = initial.reset();

      expect(identical(stale, initial), isTrue);
      expect(reset.roundId, 2);
      expect(reset.phase, RoundPhase.ready);
      expect(reset.winner, isNull);
    });

    test('round-trips through JSON', () {
      final state = const GameState.initial().acceptBuzz(
        team: Team.b,
        attemptedRoundId: 1,
        now: DateTime.utc(2026, 8, 27),
        autoResetAfter: null,
      );

      final decoded = GameState.fromJson(state.toJson());

      expect(decoded.roundId, state.roundId);
      expect(decoded.phase, state.phase);
      expect(decoded.winner, Team.b);
      expect(decoded.acceptedAt, state.acceptedAt);
      expect(decoded.resetAt, isNull);
    });
  });
}
