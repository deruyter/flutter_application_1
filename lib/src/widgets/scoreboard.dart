import 'package:flutter/material.dart';
import '../state/match_controller.dart';

class Scoreboard extends StatelessWidget {
  final MatchController controller;

  const Scoreboard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.green.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Two rows: one per player. Columns: rank | name | club | set scores | current point
            _playerRow(0),
            const SizedBox(height: 8),
            _playerRow(1),
          ],
        ),
      ),
    );
  }

  Widget _playerRow(int playerIndex) {
    final rank =
        playerIndex == 0
            ? (controller.config.player1Rank ?? '')
            : (controller.config.player2Rank ?? '');
    final club =
        playerIndex == 0
            ? (controller.config.player1Club ?? '')
            : (controller.config.player2Club ?? '');

    final name =
        playerIndex == 0
            ? controller.config.player1Name
            : controller.config.player2Name;

    final color =
        playerIndex == 0 ? Colors.blue.shade700 : Colors.orange.shade800;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Rank column (fixed width)
        SizedBox(
          width: 40,
          child: Text(
            rank,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.left,
          ),
        ),
        const SizedBox(width: 8),

        // Name (limit width so following columns stay adjacent)
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Club (compact)
        SizedBox(
          width: 100,
          child: Text(
            club,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),

        // Per-set scores: compact, left-aligned and adjacent to club
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(controller.score.sets.length, (i) {
            final s = controller.score.sets[i];
            final val = playerIndex == 0 ? s.gamesP1 : s.gamesP2;
            return Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: Text(
                val.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }),
        ),

        const SizedBox(width: 12),
        // Current point badge
        _pointBadge(playerIndex),
      ],
    );
  }

  Widget _pointBadge(int playerIndex) {
    final display =
        controller.inTieBreak
            ? controller.tieBreakPoints[playerIndex].toString()
            : _pointToString(controller.currentPoints[playerIndex]);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade500,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        display,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  String _pointToString(int pts) {
    switch (pts) {
      case 0:
        return '0';
      case 1:
        return '15';
      case 2:
        return '30';
      case 3:
        return '40';
      case 4:
        return 'Av.';
      default:
        return '';
    }
  }
}
