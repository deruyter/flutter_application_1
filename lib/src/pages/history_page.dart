import 'package:flutter/material.dart';
import '../models/match_event.dart';
import '../state/match_controller.dart';

class HistorySnapshot {
  final DateTime timestamp;
  final EventType eventType;
  final int playerIndex;
  final String scoreLabel; // textual representation of current score

  HistorySnapshot({
    required this.timestamp,
    required this.eventType,
    required this.playerIndex,
    required this.scoreLabel,
  });
}

class HistoryPage extends StatelessWidget {
  final MatchController controller;

  const HistoryPage({super.key, required this.controller});

  List<HistorySnapshot> _buildSnapshots() {
    final snapshots = <HistorySnapshot>[];

    // Replay events on a temporary controller so we can reuse scoring logic
    final temp = MatchController(controller.config);

    for (final e in controller.events) {
      temp.addEvent(e);

      // consider point-resolving events only
      const resolving = {
        EventType.ace,
        EventType.doubleFault,
        EventType.winner,
        EventType.unforcedError,
        EventType.forcedError,
        EventType.point,
        EventType.breakPointWon,
        EventType.breakPointSaved,
      };

      if (resolving.contains(e.type)) {
        final scorePieces =
            temp.score.sets.map((s) => '${s.gamesP1}-${s.gamesP2}').toList();
        final currentGame =
            temp.inTieBreak
                ? 'TB ${temp.tieBreakPoints[0]}-${temp.tieBreakPoints[1]}'
                : _pointsToLabel(temp.currentPoints);

        final label = '${scorePieces.join(' ')} · $currentGame';

        snapshots.add(
          HistorySnapshot(
            timestamp: e.timestamp,
            eventType: e.type,
            playerIndex: e.playerIndex,
            scoreLabel: label,
          ),
        );
      }
    }

    return snapshots.reversed.toList(); // newest first
  }

  String _pointsToLabel(List<int> pts) {
    String pLabel(int p) {
      switch (p) {
        case 0:
          return '0';
        case 1:
          return '15';
        case 2:
          return '30';
        case 3:
          return '40';
        case 4:
          return 'A';
        default:
          return p.toString();
      }
    }

    return '${pLabel(pts[0])}-${pLabel(pts[1])}';
  }

  @override
  Widget build(BuildContext context) {
    final snapshots = _buildSnapshots();
    final p1 = controller.config.player1Name;
    final p2 = controller.config.player2Name;

    return Scaffold(
      appBar: AppBar(title: const Text('Historique point par point')),
      body:
          snapshots.isEmpty
              ? const Center(child: Text('Aucun point enregistré'))
              : ListView.separated(
                itemCount: snapshots.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final s = snapshots[idx];
                  final isP1 = s.playerIndex == 0;
                  final name = isP1 ? p1 : p2;
                  return ListTile(
                    leading: Text(
                      '${s.timestamp.hour.toString().padLeft(2, '0')}:${s.timestamp.minute.toString().padLeft(2, '0')}:${s.timestamp.second.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    title: Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: isP1 ? Colors.blue : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isP1 ? Colors.blue : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(s.eventType.toString().split('.').last),
                      ],
                    ),
                    subtitle: Text(s.scoreLabel),
                  );
                },
              ),
    );
  }
}
