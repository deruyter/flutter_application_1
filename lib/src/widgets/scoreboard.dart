import 'package:flutter/material.dart';
import '../state/match_controller.dart';

class Scoreboard extends StatelessWidget {
  final MatchController controller;

  const Scoreboard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.green[100],
      child: Column(
        children: [
          // Noms et points
          Row(
            children: [
              Expanded(child: _playerRow(0)),
              Expanded(child: _playerRow(1)),
            ],
          ),
          const SizedBox(height: 10),
          // Sets joués
          _setScores(),
        ],
      ),
    );
  }

  /// Ligne affichant le joueur et ses points
  Widget _playerRow(int playerIndex) {
    final name =
        playerIndex == 0
            ? controller.config.player1Name
            : controller.config.player2Name;

    // Si tie-break, afficher tie-break points
    final pointsDisplay =
        controller.inTieBreak
            ? controller.tieBreakPoints[playerIndex].toString()
            : _pointToString(controller.currentPoints[playerIndex]);

    return Column(
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          pointsDisplay,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Affichage des sets
  Widget _setScores() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var set in controller.score.sets)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              "${set.gamesP1}-${set.gamesP2}",
              style: const TextStyle(fontSize: 18),
            ),
          ),
      ],
    );
  }

  /// Conversion des points en tennis normal
  String _pointToString(int pts) {
    switch (pts) {
      case 0:
        return "0";
      case 1:
        return "15";
      case 2:
        return "30";
      case 3:
        return "40";
      case 4:
        return "Av.";
      default:
        return "";
    }
  }
}
