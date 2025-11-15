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
        padding: const EdgeInsets.all(16),
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
            // Noms et points
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: _playerColumn(0)),
                _centerScoreCard(),
                Expanded(child: _playerColumn(1)),
              ],
            ),
            const SizedBox(height: 12),
            // Sets joués
            _setScores(),
          ],
        ),
      ),
    );
  }

  /// Column affichant le joueur, son nom et un indicateur de serveur
  Widget _playerColumn(int playerIndex) {
    final name =
        playerIndex == 0
            ? controller.config.player1Name
            : controller.config.player2Name;
    final isServer = controller.currentServerIndex == playerIndex;
    final pointsDisplay =
        controller.inTieBreak
            ? controller.tieBreakPoints[playerIndex].toString()
            : _pointToString(controller.currentPoints[playerIndex]);

    final color =
        playerIndex == 0 ? Colors.blue.shade700 : Colors.orange.shade800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isServer)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withAlpha((0.12 * 255).round()),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sports_tennis, size: 18, color: color),
              ),
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // show rank and club if provided
        if ((playerIndex == 0 && controller.config.player1Rank != null) ||
            (playerIndex == 1 && controller.config.player2Rank != null))
          Text(
            playerIndex == 0
                ? (controller.config.player1Rank ?? '')
                : (controller.config.player2Rank ?? ''),
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        if ((playerIndex == 0 && controller.config.player1Club != null) ||
            (playerIndex == 1 && controller.config.player2Club != null))
          Text(
            playerIndex == 0
                ? (controller.config.player1Club ?? '')
                : (controller.config.player2Club ?? ''),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        const SizedBox(height: 6),
        Text(
          pointsDisplay,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _centerScoreCard() {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.9 * 255).round()),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.06 * 255).round()),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Sets', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                controller.score.sets.last.gamesP1.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.0),
                child: Text(
                  '-',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                controller.score.sets.last.gamesP2.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
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
