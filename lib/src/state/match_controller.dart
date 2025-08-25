import '../models/match_models.dart'; // pour MatchConfig, MatchScore, SetScore
import '../models/player_stats.dart'; // pour PlayerStats
import '../models/enums.dart'; // pour BestOf

class MatchController {
  final MatchConfig config;
  final MatchScore score = MatchScore();
  final List<PlayerStats> stats = [PlayerStats(), PlayerStats()];
  int currentServerIndex;

  bool matchFinished = false;

  /// Points du jeu normal (0,15,30,40,Avantage)
  List<int> currentPoints = [0, 0];

  /// Points du tie-break
  List<int> tieBreakPoints = [0, 0];

  bool inTieBreak = false;

  MatchController(this.config)
    : currentServerIndex = config.firstServerIndex; // 0 ou 1 selon qui commence

  /// Ajoute un point à un joueur
  void addPoint(int playerIndex) {
    if (inTieBreak) {
      _addTieBreakPoint(playerIndex);
    } else {
      _addNormalPoint(playerIndex);
    }
    _addPointToServeStats(playerIndex, currentServerIndex);
    if (matchFinished) return;
  }

  /// Points en jeu normal
  void _addNormalPoint(int playerIndex) {
    final opponent = 1 - playerIndex;

    if (currentPoints[playerIndex] < 3) {
      currentPoints[playerIndex]++;
    } else if (currentPoints[playerIndex] == 3) {
      if (currentPoints[opponent] < 3) {
        _winGame(playerIndex);
      } else if (currentPoints[opponent] == 3) {
        // Passe à Avantage
        currentPoints[playerIndex] = 4;
      } else if (currentPoints[opponent] == 4) {
        // retour à 40-40
        currentPoints[opponent] = 3;
      }
    } else if (currentPoints[playerIndex] == 4) {
      _winGame(playerIndex);
    }
  }

  void _winGame(int playerIndex) {
    currentPoints = [0, 0];
    if (playerIndex == 0) {
      score.currentSet.gamesP1++;
    } else {
      score.currentSet.gamesP2++;
    }
    // Vérifie tie-break
    final p1 = score.currentSet.gamesP1;
    final p2 = score.currentSet.gamesP2;

    if (p1 == 6 && p2 == 6) {
      inTieBreak = true;
      tieBreakPoints = [0, 0];
    } else {
      _checkSetWin();
    }
    currentServerIndex = 1 - currentServerIndex;
  }

  /// Points en tie-break
  void _addTieBreakPoint(int playerIndex) {
    final opponent = 1 - playerIndex;
    tieBreakPoints[playerIndex]++;

    // Vérifie si le tie-break est gagné
    if (tieBreakPoints[playerIndex] >= 7 &&
        (tieBreakPoints[playerIndex] - tieBreakPoints[opponent]) >= 2) {
      // gagnant du tie-break = gagnant du set
      if (playerIndex == 0) {
        score.setsWonP1++;
        score.currentSet.gamesP1 = 7;
        score.currentSet.gamesP2 = 6;
      } else {
        score.setsWonP2++;
        score.currentSet.gamesP1 = 6;
        score.currentSet.gamesP2 = 7;
      }
      inTieBreak = false;
      tieBreakPoints = [0, 0];
      score.sets.add(SetScore());

      if (score.setsWonP1 == config.bestOf.setsToWin ||
          score.setsWonP2 == config.bestOf.setsToWin) {
        matchFinished = true;
      }
    }
  }

  void _checkSetWin() {
    final p1 = score.currentSet.gamesP1;
    final p2 = score.currentSet.gamesP2;

    if ((p1 >= 6 || p2 >= 6) && (p1 - p2).abs() >= 2) {
      if (p1 > p2) {
        score.setsWonP1++;
      } else {
        score.setsWonP2++;
      }
      score.sets.add(SetScore());
    }

    if (score.setsWonP1 == config.bestOf.setsToWin ||
        score.setsWonP2 == config.bestOf.setsToWin) {
      matchFinished = true;
    }
  }

  // === Fonctions pour stats ===
  void addAce(int playerIndex) {
    stats[playerIndex].aces++;
    addPoint(playerIndex);
  }

  void addDoubleFault(int playerIndex) {
    stats[playerIndex].doubleFaults++;
    addPoint(1 - playerIndex);
  }

  void addWinner(int playerIndex) {
    stats[playerIndex].winners++;
    addPoint(playerIndex);
  }

  void addUnforcedError(int playerIndex) {
    stats[playerIndex].unforcedErrors++;
    addPoint(1 - playerIndex);
  }

  void _addPointToServeStats(int winnerIndex, int serverIndex) {
    if (winnerIndex == serverIndex) {
      // Le serveur a gagné le point
      stats[serverIndex].pointsWonOnServe++;
    } else {
      // Le joueur en retour a gagné le point
      stats[1 - serverIndex].pointsWonOnReturn++;
    }
  }
}
