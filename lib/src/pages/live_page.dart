import 'package:flutter/material.dart';
import '../state/match_controller.dart';
import '../widgets/scoreboard.dart';
import 'summary_page.dart';

class LivePage extends StatefulWidget {
  final MatchController controller;

  const LivePage({super.key, required this.controller});

  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    return Scaffold(
      appBar: AppBar(title: const Text("Match en direct")),
      body: Column(
        children: [
          Scoreboard(controller: c),
          const Divider(thickness: 1),
          _liveStats(), // <-- AJOUT du bloc stats
          const Divider(thickness: 1),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _playerControls(0)),
                Expanded(child: _playerControls(1)),
              ],
            ),
          ),
          if (c.matchFinished)
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SummaryPage(controller: c),
                  ),
                );
              },
              child: const Text("Voir le résumé"),
            ),
        ],
      ),
    );
  }

  /// Bloc affichant les stats en direct
  Widget _liveStats() {
    final c = widget.controller;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          const Text("Statistiques en direct",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _statRow("Aces", c.stats[0].aces, c.stats[1].aces),
          _statRow("Doubles fautes", c.stats[0].doubleFaults, c.stats[1].doubleFaults),
          _statRow("Winners", c.stats[0].winners, c.stats[1].winners),
          _statRow("Fautes directes", c.stats[0].unforcedErrors, c.stats[1].unforcedErrors),
          _statRow("Points gagnés", c.stats[0].totalPointsWon, c.stats[1].totalPointsWon),
        ],
      ),
    );
  }

  Widget _statRow(String label, int p1, int p2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$p1", style: const TextStyle(fontSize: 16)),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text("$p2", style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  /// Boutons d’actions pour chaque joueur
  Widget _playerControls(int playerIndex) {
    final c = widget.controller;
    final name =
        playerIndex == 0 ? c.config.player1Name : c.config.player2Name;
    final isServer = playerIndex == c.currentServerIndex;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (!isServer) ...[
            ElevatedButton(
              onPressed: () => setState(() => c.addAce(playerIndex)),
              child: const Text("Ace"),
            ),
            ElevatedButton(
              onPressed: () => setState(() => c.addDoubleFault(playerIndex)),
              child: const Text("Double faute"),
            ),
          ],
          ElevatedButton(
            onPressed: () => setState(() => c.addWinner(playerIndex)),
            child: const Text("Coup gagnant"),
          ),
          ElevatedButton(
            onPressed: () => setState(() => c.addUnforcedError(playerIndex)),
            child: const Text("Faute directe"),
          ),
        ],
      ),
    );
  }
}
