enum Team { a, b }

extension TeamValue on Team {
  String get wireValue => name;

  String get fallbackName => this == Team.a ? 'Team A' : 'Team B';

  static Team? fromWireValue(Object? value) {
    return switch (value) {
      'a' => Team.a,
      'b' => Team.b,
      _ => null,
    };
  }
}
