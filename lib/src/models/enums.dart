enum BestOf { three, five }

extension BestOfX on BestOf {
  int get setsToWin => this == BestOf.three ? 2 : 3;
}

/// Predefined match formats the user can choose from.
enum MatchFormat { format1, format2, format3, format4, format5 }

extension MatchFormatX on MatchFormat {
  /// Human label for UI
  String get label {
    switch (this) {
      case MatchFormat.format1:
        return 'Format 1 — 3x6, TB @6-6, no-ad, pas de super TB';
      case MatchFormat.format2:
        return 'Format 2 — 2x6, TB @6-6, pas de no-ad, super TB décider';
      case MatchFormat.format3:
        return 'Format 3 — 3x4, TB @4-4, no-ad, super TB';
      case MatchFormat.format4:
        return 'Format 4 — 2x6, TB @6-6, no-ad, super TB';
      case MatchFormat.format5:
        return 'Format 5 — 2x3, TB @2-2, no-ad, super TB';
    }
  }

  /// Number of sets in the match (for display/selection)
  int get totalSets {
    switch (this) {
      case MatchFormat.format1:
        return 3;
      case MatchFormat.format2:
        return 2;
      case MatchFormat.format3:
        return 3;
      case MatchFormat.format4:
        return 2;
      case MatchFormat.format5:
        return 2;
    }
  }

  /// Number of games per set (typical target before TB)
  int get gamesPerSet {
    switch (this) {
      case MatchFormat.format1:
      case MatchFormat.format2:
      case MatchFormat.format4:
        return 6;
      case MatchFormat.format3:
        return 4;
      case MatchFormat.format5:
        return 3;
    }
  }

  /// When to trigger a standard tie-break (e.g. 6 means at 6-6)
  int get tiebreakAt {
    switch (this) {
      case MatchFormat.format1:
      case MatchFormat.format2:
      case MatchFormat.format4:
        return 6;
      case MatchFormat.format3:
        return 4;
      case MatchFormat.format5:
        return 2;
    }
  }

  /// Use no-ad (deciding point at deuce)
  bool get noAd {
    switch (this) {
      case MatchFormat.format1:
      case MatchFormat.format2:
        return false;
      case MatchFormat.format3:
      case MatchFormat.format4:
      case MatchFormat.format5:
        return true;
    }
  }

  /// Whether a super tie-break (10-point TB) is used as a decider for the final set
  bool get finalSetSuperTieBreak {
    switch (this) {
      case MatchFormat.format1:
        return false;
      case MatchFormat.format2:
      case MatchFormat.format3:
      case MatchFormat.format4:
      case MatchFormat.format5:
        return true;
    }
  }

  /// Sets needed to win the match
  int get setsToWin {
    // For 2-set matches, winning both sets wins the match (2). For 3-set matches, 2.
    if (totalSets == 2) return 2;
    if (totalSets == 3) return 2;
    // fallback
    return (totalSets / 2).ceil();
  }
}
