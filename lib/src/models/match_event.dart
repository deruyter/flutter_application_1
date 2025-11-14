import 'dart:convert';

enum EventType {
  ace,
  doubleFault,
  winner,
  unforcedError,
  forcedError,
  firstServeIn,
  firstServeOut,
  secondServeIn,
  secondServeOut,
  point,
  breakPointWon,
  breakPointFaced,
  breakPointSaved,
}

class MatchEvent {
  final String id;
  final DateTime timestamp;
  final EventType type;
  final int playerIndex; // 0 or 1
  final Map<String, dynamic>? meta;

  MatchEvent({
    String? id,
    DateTime? timestamp,
    required this.type,
    required this.playerIndex,
    this.meta,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'type': type.toString().split('.').last,
    'playerIndex': playerIndex,
    'meta': meta == null ? null : jsonEncode(meta),
  };

  static EventType _typeFromString(String s) {
    return EventType.values.firstWhere(
      (e) => e.toString().split('.').last == s,
      orElse: () => EventType.point,
    );
  }

  factory MatchEvent.fromJson(Map<String, dynamic> j) => MatchEvent(
    id: j['id'] as String?,
    timestamp:
        j['timestamp'] == null
            ? null
            : DateTime.parse(j['timestamp'] as String),
    type: _typeFromString(j['type'] as String),
    playerIndex: j['playerIndex'] as int,
    meta:
        j['meta'] == null
            ? null
            : Map<String, dynamic>.from(jsonDecode(j['meta'] as String) as Map),
  );
}
