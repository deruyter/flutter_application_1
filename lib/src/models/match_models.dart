import 'enums.dart';

class MatchConfig {
  final String player1Name;
  final String player2Name;
  final BestOf bestOf;
  final int firstServerIndex;
  final MatchFormat matchFormat;
  // Optional player metadata
  final String? player1Rank; // classement amateur / niveau
  final String? player2Rank;
  final String? player1Club;
  final String? player2Club;

  const MatchConfig({
    required this.player1Name,
    required this.player2Name,
    required this.bestOf,
    required this.firstServerIndex,
    required this.matchFormat,
    this.player1Rank,
    this.player2Rank,
    this.player1Club,
    this.player2Club,
  });
}

class SetScore {
  int gamesP1 = 0;
  int gamesP2 = 0;

  @override
  String toString() => "$gamesP1-$gamesP2";
}

class MatchScore {
  final List<SetScore> sets = [SetScore()];
  int setsWonP1 = 0;
  int setsWonP2 = 0;

  SetScore get currentSet => sets.last;
}
