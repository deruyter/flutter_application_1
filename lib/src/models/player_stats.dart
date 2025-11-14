class PlayerStats {
  int aces = 0;
  int doubleFaults = 0;
  int forcedErrors = 0; // "faute provoquée"

  int firstServeIn = 0;
  int firstServeOut = 0;

  int secondServeIn = 0;
  int secondServeOut = 0;
  int firstServePointsWon = 0;
  int secondServePointsWon = 0;
  int firstServePointsTotal = 0;
  int secondServePointsTotal = 0;

  int serviceGamesWon = 0;
  int serviceGamesPlayed = 0;
  int returnGamesWon = 0;
  int returnGamesPlayed = 0;

  int winners = 0;
  // Totals to compute percentages like 57/74
  int unforcedErrors = 0;

  int pointsWonOnServe = 0;
  int pointsWonOnReturn = 0;
  // Return-side counters (points won when opponent served first/second)
  int firstServeReturnPointsWon = 0;
  int secondServeReturnPointsWon = 0;

  int breakPointsWon = 0;
  int breakPointsFaced = 0;
  int breakPointsSaved = 0;
  int matchSavedBalls = 0;

  double get firstServePct {
    final totalServicePoints = firstServePointsTotal + secondServePointsTotal;
    if (totalServicePoints == 0) return 0;
    // per requested formula: 1 - (firstServeFaults / totalServicePoints)
    return (1.0 - (firstServeOut / totalServicePoints)) * 100.0;
  }

  int get totalPointsWon => pointsWonOnServe + pointsWonOnReturn;

  String pctWithDetail(int numerator, int denominator) {
    if (denominator == 0) return '0% (0/0)';
    final pct = ((numerator / denominator) * 100).round();
    return '$pct% ($numerator/$denominator)';
  }

  // Clone helper
  PlayerStats clone() {
    final p = PlayerStats();
    p.aces = aces;
    p.doubleFaults = doubleFaults;
    p.forcedErrors = forcedErrors;
    p.firstServeIn = firstServeIn;
    p.firstServeOut = firstServeOut;
    p.secondServeIn = secondServeIn;
    p.secondServeOut = secondServeOut;
    p.firstServePointsWon = firstServePointsWon;
    p.secondServePointsWon = secondServePointsWon;
    p.firstServePointsTotal = firstServePointsTotal;
    p.secondServePointsTotal = secondServePointsTotal;
    p.serviceGamesWon = serviceGamesWon;
    p.serviceGamesPlayed = serviceGamesPlayed;
    p.returnGamesWon = returnGamesWon;
    p.returnGamesPlayed = returnGamesPlayed;
    p.winners = winners;
    p.unforcedErrors = unforcedErrors;
    p.pointsWonOnServe = pointsWonOnServe;
    p.pointsWonOnReturn = pointsWonOnReturn;
    p.firstServeReturnPointsWon = firstServeReturnPointsWon;
    p.secondServeReturnPointsWon = secondServeReturnPointsWon;
    p.breakPointsWon = breakPointsWon;
    p.breakPointsFaced = breakPointsFaced;
    p.breakPointsSaved = breakPointsSaved;
    p.matchSavedBalls = matchSavedBalls;
    return p;
  }

  // Subtract b from a (a - b) and return result
  static PlayerStats diff(PlayerStats a, PlayerStats b) {
    final r = PlayerStats();
    r.aces = a.aces - b.aces;
    r.doubleFaults = a.doubleFaults - b.doubleFaults;
    r.forcedErrors = a.forcedErrors - b.forcedErrors;
    r.firstServeIn = a.firstServeIn - b.firstServeIn;
    r.firstServeOut = a.firstServeOut - b.firstServeOut;
    r.secondServeIn = a.secondServeIn - b.secondServeIn;
    r.secondServeOut = a.secondServeOut - b.secondServeOut;
    r.firstServePointsWon = a.firstServePointsWon - b.firstServePointsWon;
    r.secondServePointsWon = a.secondServePointsWon - b.secondServePointsWon;
    r.firstServePointsTotal = a.firstServePointsTotal - b.firstServePointsTotal;
    r.secondServePointsTotal =
        a.secondServePointsTotal - b.secondServePointsTotal;
    r.serviceGamesWon = a.serviceGamesWon - b.serviceGamesWon;
    r.serviceGamesPlayed = a.serviceGamesPlayed - b.serviceGamesPlayed;
    r.returnGamesWon = a.returnGamesWon - b.returnGamesWon;
    r.returnGamesPlayed = a.returnGamesPlayed - b.returnGamesPlayed;
    r.winners = a.winners - b.winners;
    r.unforcedErrors = a.unforcedErrors - b.unforcedErrors;
    r.pointsWonOnServe = a.pointsWonOnServe - b.pointsWonOnServe;
    r.pointsWonOnReturn = a.pointsWonOnReturn - b.pointsWonOnReturn;
    r.firstServeReturnPointsWon =
        a.firstServeReturnPointsWon - b.firstServeReturnPointsWon;
    r.secondServeReturnPointsWon =
        a.secondServeReturnPointsWon - b.secondServeReturnPointsWon;
    r.breakPointsWon = a.breakPointsWon - b.breakPointsWon;
    r.breakPointsFaced = a.breakPointsFaced - b.breakPointsFaced;
    r.breakPointsSaved = a.breakPointsSaved - b.breakPointsSaved;
    r.matchSavedBalls = a.matchSavedBalls - b.matchSavedBalls;
    return r;
  }
}
