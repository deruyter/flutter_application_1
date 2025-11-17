import 'player.dart';
import 'match_model.dart';

class Tournament {
  final String id;
  final String name;
  final int? year;
  final List<Player> players;
  final List<MatchModel> matches;

  Tournament({
    required this.id,
    required this.name,
    this.year,
    List<Player>? players,
    List<MatchModel>? matches,
  }) : players = players ?? [],
       matches = matches ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'year': year,
    'players': players.map((p) => p.toJson()).toList(),
    'matches': matches.map((m) => m.toJson()).toList(),
  };

  @override
  String toString() => 'Tournament($name ${year ?? ''})';
}
