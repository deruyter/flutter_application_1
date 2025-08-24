class PlayerStats {
  int aces = 0;
  int doubleFaults = 0;

  int firstServeIn = 0;
  int firstServeTotal = 0;

  int winners = 0;
  int unforcedErrors = 0;

  int pointsWonOnServe = 0;
  int pointsWonOnReturn = 0;

  int breakPointsWon = 0;
  int breakPointsFaced = 0;
  int breakPointsSaved = 0;

  double get firstServePct =>
      firstServeTotal == 0 ? 0 : (firstServeIn / firstServeTotal) * 100.0;

  int get totalPointsWon => pointsWonOnServe + pointsWonOnReturn;
}
