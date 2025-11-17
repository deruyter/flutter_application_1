import 'package:uuid/uuid.dart';

class Slot {
  final String id;
  String? playerId;
  String? seedOrNote;

  Slot({String? id, this.playerId, this.seedOrNote}) : id = id ?? Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'playerId': playerId,
    'seedOrNote': seedOrNote,
  };
}

class Round {
  final String id;
  final String name;
  final List<Slot> slots; // each slot represents a player slot in that round

  Round({String? id, required this.name, List<Slot>? slots})
    : id = id ?? Uuid().v4(),
      slots = slots ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slots': slots.map((s) => s.toJson()).toList(),
  };
}

class Draw {
  final String id;
  final String name;
  final int size; // number of players (e.g., 32, 56, 128)
  final List<Round> rounds;

  Draw({
    String? id,
    required this.name,
    required this.size,
    List<Round>? rounds,
  }) : id = id ?? Uuid().v4(),
       rounds = rounds ?? [];

  /// Convenience: get first round (player slots)
  Round get firstRound =>
      rounds.isNotEmpty ? rounds.first : (throw StateError('No rounds'));

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'size': size,
    'rounds': rounds.map((r) => r.toJson()).toList(),
  };
}
