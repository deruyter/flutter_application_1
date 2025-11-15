import 'package:flutter/material.dart';
import '../models/match_event.dart';
import '../state/match_controller.dart';
import '../widgets/scoreboard.dart';
import 'stats_page.dart';
import 'summary_page.dart';
import 'timeline_page.dart';

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

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Match en direct'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.sports_tennis), text: 'Live'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
              Tab(icon: Icon(Icons.timeline), text: 'Timeline'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _liveBody(c),
            StatsPage(controller: c),
            TimelinePage(controller: c),
          ],
        ),
      ),
    );
  }

  Widget _liveBody(MatchController c) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Scoreboard
          Scoreboard(controller: c),
          const SizedBox(height: 12),

          // Player action panels: two columns on wide screens, stacked on narrow
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // breakpoint can be adjusted as needed
                if (constraints.maxWidth > 600) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: _playerPanel(0, c),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6.0),
                            child: _playerPanel(1, c),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Narrow layout: stacked panels
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _playerPanel(0, c),
                      const SizedBox(height: 10),
                      _playerPanel(1, c),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Footer actions: undo + summary when match finished
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  c.undoLastEvent();
                  setState(() {});
                },
                icon: const Icon(Icons.undo),
                label: const Text('Annuler'),
              ),
              const SizedBox(width: 8),
              if (c.matchFinished) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SummaryPage(controller: c),
                      ),
                    );
                  },
                  icon: const Icon(Icons.article),
                  label: const Text('Voir le résumé'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Nice action panel for a player with grouped buttons and icons
  Widget _playerPanel(int playerIndex, MatchController c) {
    final name = playerIndex == 0 ? c.config.player1Name : c.config.player2Name;
    final isServer = playerIndex == c.currentServerIndex;
    final color = playerIndex == 0 ? Colors.blue : Colors.orange;

    Widget actionButton(
      String label,
      IconData icon,
      Color bg,
      VoidCallback onTap,
    ) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          minimumSize: const Size.fromHeight(44),
        ),
        icon: Icon(icon),
        label: Text(label),
        onPressed: () {
          onTap();
          setState(() {});
        },
      );
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  child: Text('${playerIndex + 1}'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isServer)
                  Padding(
                    padding: const EdgeInsets.only(left: 6.0),
                    child: Chip(
                      label: const Text('Server'),
                      backgroundColor: color.withAlpha((0.12 * 255).round()),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Service block (only for server)
            if (isServer) ...[
              actionButton(
                'Ace',
                Icons.flash_on,
                Colors.green,
                () => c.addAce(playerIndex),
              ),
              const SizedBox(height: 8),
              actionButton(
                c.awaitingSecondServe[playerIndex] ? 'Double faute' : 'Faute',
                Icons.error,
                Colors.red,
                () => c.toggleServiceFault(playerIndex),
              ),
              const SizedBox(height: 12),
            ],

            actionButton(
              'Coup gagnant',
              Icons.emoji_events,
              Colors.teal,
              () => c.addWinner(playerIndex),
            ),
            const SizedBox(height: 8),
            actionButton(
              'Faute directe',
              Icons.clear,
              Colors.deepOrange,
              () => c.addUnforcedError(playerIndex),
            ),
            const SizedBox(height: 8),
            actionButton(
              'Faute provoquée',
              Icons.call_split,
              Colors.purple,
              () => c.addEvent(
                MatchEvent(
                  type: EventType.forcedError,
                  playerIndex: playerIndex,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
