import 'package:flutter/material.dart';
import '../state/match_controller.dart';
import '../widgets/scoreboard.dart';
import '../models/match_event.dart';
import 'stats_page.dart';
import 'timeline_page.dart';
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
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Big scoreboard
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Scoreboard(controller: c),
          ),
          const SizedBox(height: 12),

          // Player action panels
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                children: [
                  Expanded(child: _playerPanel(0, c)),
                  const SizedBox(width: 12),
                  Expanded(child: _playerPanel(1, c)),
                ],
              ),
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 12.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.timeline),
                    label: const Text('Timeline'),
                    onPressed: () {
                      // switch to timeline tab
                      DefaultTabController.of(context).animateTo(2);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                if (c.matchFinished)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Voir le résumé'),
                      onPressed: () {
                        Navigator.pushReplacement<void, void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => SummaryPage(controller: c),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
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
                      backgroundColor: color.withOpacity(0.12),
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
