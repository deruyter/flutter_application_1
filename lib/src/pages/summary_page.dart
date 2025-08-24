import 'package:flutter/material.dart';
import '../state/match_controller.dart';

class SummaryPage extends StatelessWidget {
  final MatchController controller;

  const SummaryPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;

    return Scaffold(
      appBar: AppBar(title: const Text("Résumé du match")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text("${c.config.player1Name} vs ${c.config.player2Name}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text("Score final : ${c.score.sets.map((s) => s.toString()).join(" ")}"),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                children: [
                  _statRow("Aces", c.stats[0].aces, c.stats[1].aces),
                  _statRow("Doubles fautes", c.stats[0].doubleFaults, c.stats[1].doubleFaults),
                  _statRow("Coups gagnants", c.stats[0].winners, c.stats[1].winners),
                  _statRow("Fautes directes", c.stats[0].unforcedErrors, c.stats[1].unforcedErrors),
                  _statRow("Points gagnés", c.stats[0].totalPointsWon, c.stats[1].totalPointsWon),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, int p1, int p2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$p1", style: const TextStyle(fontSize: 18)),
          Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text("$p2", style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
