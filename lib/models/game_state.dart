import 'team.dart';

enum RoundPhase { ready, locked }

class GameState {
  const GameState({
    required this.roundId,
    required this.phase,
    this.winner,
    this.acceptedAt,
    this.resetAt,
  });

  const GameState.initial()
    : roundId = 1,
      phase = RoundPhase.ready,
      winner = null,
      acceptedAt = null,
      resetAt = null;

  final int roundId;
  final RoundPhase phase;
  final Team? winner;
  final DateTime? acceptedAt;
  final DateTime? resetAt;

  bool get isReady => phase == RoundPhase.ready;

  GameState acceptBuzz({
    required Team team,
    required int attemptedRoundId,
    required DateTime now,
    required Duration? autoResetAfter,
  }) {
    if (!isReady || attemptedRoundId != roundId) {
      return this;
    }
    final accepted = now.toUtc();
    return GameState(
      roundId: roundId,
      phase: RoundPhase.locked,
      winner: team,
      acceptedAt: accepted,
      resetAt: autoResetAfter == null ? null : accepted.add(autoResetAfter),
    );
  }

  GameState reset() {
    return GameState(roundId: roundId + 1, phase: RoundPhase.ready);
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'roundId': roundId,
      'phase': phase.name,
      'winner': winner?.wireValue,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'resetAt': resetAt?.toIso8601String(),
    };
  }

  factory GameState.fromJson(Map<String, Object?> json) {
    final winner = TeamValue.fromWireValue(json['winner']);
    final phase = json['phase'] == RoundPhase.locked.name && winner != null
        ? RoundPhase.locked
        : RoundPhase.ready;
    return GameState(
      roundId: json['roundId'] as int? ?? 1,
      phase: phase,
      winner: phase == RoundPhase.locked ? winner : null,
      acceptedAt: _parseDate(json['acceptedAt']),
      resetAt: _parseDate(json['resetAt']),
    );
  }

  static DateTime? _parseDate(Object? value) {
    return value is String ? DateTime.tryParse(value)?.toUtc() : null;
  }
}
