import 'package:flutter/material.dart';
import '../state/match_controller.dart';
import '../models/player_stats.dart';
import 'timeline_page.dart';

class StatsPage extends StatelessWidget {
  final MatchController controller;

  const StatsPage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final p1 = c.config.player1Name;
    final p2 = c.config.player2Name;
    final p1Color = Colors.blue;
    final p2Color = Colors.orange;

    // per-set stats computation is not implemented yet; tabs will show set scores

    return DefaultTabController(
      length: 1 + c.score.sets.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Statistiques du match'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export non implémenté')),
                );
              },
              tooltip: 'Exporter JSON/CSV',
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              const Tab(text: 'Match'),
              for (var i = 0; i < c.score.sets.length; i++)
                Tab(text: 'Set ${i + 1}'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Match-wide stats
            _statsView(context, c, p1, p2, p1Color, p2Color, overall: true),
            // Per-set tabs (reuse overall stats for now; show set score)
            for (var i = 0; i < c.score.sets.length; i++)
              _statsView(context, c, p1, p2, p1Color, p2Color, setIndex: i),
          ],
        ),
      ),
    );
  }

  Widget _statsView(
    BuildContext context,
    MatchController c,
    String p1,
    String p2,
    Color p1Color,
    Color p2Color, {
    bool overall = false,
    int? setIndex,
  }) {
    final p1Stats = overall ? c.stats[0] : _statsForSet(c, 0, setIndex);
    final p2Stats = overall ? c.stats[1] : _statsForSet(c, 1, setIndex);

    final setScore = setIndex != null ? c.score.sets[setIndex] : null;

    final totalPointsAll = p1Stats.totalPointsWon + p2Stats.totalPointsWon;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$p1 vs $p2',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Score: ${c.score.sets.map((s) => s.toString()).join(' ')}',
                    ),
                    if (setScore != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Set ${setIndex! + 1}: ${setScore.gamesP1}-${setScore.gamesP2}',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Two-column header
          Row(
            children: [
              Expanded(
                child: Text(
                  p1,
                  style: TextStyle(color: p1Color, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(child: Center(child: const Text('Stat'))),
              Expanded(
                child: Text(
                  p2,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: p2Color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Service
          const Text(
            'Service',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _statRow(
            'Aces',
            p1Stats.aces.toString(),
            p2Stats.aces.toString(),
            p1Color,
            p2Color,
          ),
          _statRow(
            'Doubles fautes',
            p1Stats.doubleFaults.toString(),
            p2Stats.doubleFaults.toString(),
            p1Color,
            p2Color,
          ),
          _statRow(
            '1er service %',
            '${p1Stats.firstServePct.round()}%',
            '${p2Stats.firstServePct.round()}%',
            p1Color,
            p2Color,
          ),
          _statRow(
            'Pts au 1er service',
            p1Stats.pctWithDetail(
              p1Stats.firstServePointsWon,
              p1Stats.firstServePointsTotal,
            ),
            p2Stats.pctWithDetail(
              p2Stats.firstServePointsWon,
              p2Stats.firstServePointsTotal,
            ),
            p1Color,
            p2Color,
          ),
          _statRow(
            'Pts au 2ème service',
            p1Stats.pctWithDetail(
              p1Stats.secondServePointsWon,
              p1Stats.secondServePointsTotal,
            ),
            p2Stats.pctWithDetail(
              p2Stats.secondServePointsWon,
              p2Stats.secondServePointsTotal,
            ),
            p1Color,
            p2Color,
          ),
          _statRow(
            'Breaks sauvés',
            p1Stats.pctWithDetail(
              p1Stats.breakPointsSaved,
              p1Stats.breakPointsFaced,
            ),
            p2Stats.pctWithDetail(
              p2Stats.breakPointsSaved,
              p2Stats.breakPointsFaced,
            ),
            p1Color,
            p2Color,
          ),
          const SizedBox(height: 12),

          // Retour
          const Text(
            'Retour',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _statRow(
            'Pts Retour 1er Service',
            p1Stats.pctWithDetail(
              p1Stats.firstServeReturnPointsWon,
              p2Stats.firstServePointsTotal,
            ),
            p2Stats.pctWithDetail(
              p2Stats.firstServeReturnPointsWon,
              p1Stats.firstServePointsTotal,
            ),
            p1Color,
            p2Color,
          ),
          _statRow(
            'Pts Retour 2ème Service',
            p1Stats.pctWithDetail(
              p1Stats.secondServeReturnPointsWon,
              p2Stats.secondServePointsTotal,
            ),
            p2Stats.pctWithDetail(
              p2Stats.secondServeReturnPointsWon,
              p1Stats.secondServePointsTotal,
            ),
            p1Color,
            p2Color,
          ),
          _statRow(
            'Breaks convertis',
            // break conversion: number of breaks converted divided by opponent's
            // break points faced (i.e., your opportunities = opponent.breakPointsFaced)
            p1Stats.pctWithDetail(
              p1Stats.breakPointsWon,
              p2Stats.breakPointsFaced,
            ),
            p2Stats.pctWithDetail(
              p2Stats.breakPointsWon,
              p1Stats.breakPointsFaced,
            ),
            p1Color,
            p2Color,
          ),
          const SizedBox(height: 12),

          // Points
          const Text(
            'Points',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _statRow(
            'Points Gagnants',
            p1Stats.winners.toString(),
            p2Stats.winners.toString(),
            p1Color,
            p2Color,
          ),
          _statRow(
            'Fautes Directes',
            p1Stats.unforcedErrors.toString(),
            p2Stats.unforcedErrors.toString(),
            p1Color,
            p2Color,
          ),
          _statRow(
            'Points gagnés au filet',
            p1Stats.pctWithDetail(0, 0),
            p2Stats.pctWithDetail(0, 0),
            p1Color,
            p2Color,
          ),
          _statRow(
            'Points gagnés au service',
            p1Stats.pctWithDetail(
              p1Stats.pointsWonOnServe,
              p1Stats.totalPointsWon,
            ),
            p2Stats.pctWithDetail(
              p2Stats.pointsWonOnServe,
              p2Stats.totalPointsWon,
            ),
            p1Color,
            p2Color,
          ),
          _statRow(
            'Points gagnés au retour',
            p1Stats.pctWithDetail(
              p1Stats.pointsWonOnReturn,
              p1Stats.totalPointsWon,
            ),
            p2Stats.pctWithDetail(
              p2Stats.pointsWonOnReturn,
              p2Stats.totalPointsWon,
            ),
            p1Color,
            p2Color,
          ),
          _statRow(
            'Total de points gagnés',
            p1Stats.pctWithDetail(p1Stats.totalPointsWon, totalPointsAll),
            p2Stats.pctWithDetail(p2Stats.totalPointsWon, totalPointsAll),
            p1Color,
            p2Color,
          ),
          _statRow('Balles de match sauvées', '0', '0', p1Color, p2Color),
          const SizedBox(height: 12),

          // Jeux
          const Text(
            'Jeux',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _statRow(
            'Jeux de service gagnés',
            p1Stats.pctWithDetail(
              p1Stats.serviceGamesWon,
              p1Stats.serviceGamesPlayed,
            ),
            p2Stats.pctWithDetail(
              p2Stats.serviceGamesWon,
              p2Stats.serviceGamesPlayed,
            ),
            p1Color,
            p2Color,
          ),
          _statRow(
            'Jeux de retour gagnés',
            p1Stats.pctWithDetail(
              p1Stats.returnGamesWon,
              p1Stats.returnGamesPlayed,
            ),
            p2Stats.pctWithDetail(
              p2Stats.returnGamesWon,
              p2Stats.returnGamesPlayed,
            ),
            p1Color,
            p2Color,
          ),
          // total games won from score
          _statRow(
            'Total Jeux Gagnés',
            _gamesWonString(c, 0, setIndex),
            _gamesWonString(c, 1, setIndex),
            p1Color,
            p2Color,
          ),

          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.timeline),
              label: const Text('Ouvrir la timeline'),
              onPressed: () async {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TimelinePage(controller: c),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // For now, return a copy of overall stats for a set placeholder. Later compute true per-set stats by replaying events.
  PlayerStats _statsForSet(MatchController c, int playerIndex, int? setIndex) {
    // TODO: compute per-set stats by replaying events and splitting by set boundaries.
    return c.stats[playerIndex];
  }

  String _gamesWonString(MatchController c, int playerIndex, int? setIndex) {
    if (setIndex != null) {
      final s = c.score.sets[setIndex];
      return playerIndex == 0 ? '${s.gamesP1}' : '${s.gamesP2}';
    }
    // total games won across sets
    var total = 0;
    for (final s in c.score.sets) {
      total += playerIndex == 0 ? s.gamesP1 : s.gamesP2;
    }
    return '$total';
  }

  Widget _statRow(String label, String p1, String p2, Color c1, Color c2) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(p1, style: TextStyle(color: c1, fontSize: 16)),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(p2, style: TextStyle(color: c2, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _statRowDouble(
    String label,
    String p1,
    String p2,
    Color c1,
    Color c2,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(p1, style: TextStyle(color: c1, fontSize: 16)),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(p2, style: TextStyle(color: c2, fontSize: 16)),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }
}
