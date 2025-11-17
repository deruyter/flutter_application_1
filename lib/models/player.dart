import 'package:uuid/uuid.dart';

class Player {
  final String id;
  final String name;
  final int? seed;
  final String? note;

  Player({String? id, required this.name, this.seed, this.note})
    : id = id ?? Uuid().v4();

  factory Player.fromJson(Map<String, dynamic> j) => Player(
    id: j['id'] as String?,
    name: j['name'] as String? ?? '',
    seed: j['seed'] != null ? int.tryParse(j['seed'].toString()) : null,
    note: j['note'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'seed': seed,
    'note': note,
  };

  @override
  String toString() => 'Player($name${seed != null ? ' #$seed' : ''})';
}
