class MatchModel {
  final String id;
  final int roundIndex;
  final int position;
  final String? player1Id;
  final String? player2Id;
  final String? score;
  final String? note;

  MatchModel({
    required this.id,
    required this.roundIndex,
    required this.position,
    this.player1Id,
    this.player2Id,
    this.score,
    this.note,
  });

  factory MatchModel.fromJson(Map<String, dynamic> j) => MatchModel(
    id: j['id'] as String,
    roundIndex: j['roundIndex'] as int,
    position: j['position'] as int,
    player1Id: j['player1Id'] as String?,
    player2Id: j['player2Id'] as String?,
    score: j['score'] as String?,
    note: j['note'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'roundIndex': roundIndex,
    'position': position,
    'player1Id': player1Id,
    'player2Id': player2Id,
    'score': score,
    'note': note,
  };
}
