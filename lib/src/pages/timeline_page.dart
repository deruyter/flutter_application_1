import 'package:flutter/material.dart';
import '../state/match_controller.dart';

class TimelinePage extends StatelessWidget {
  final MatchController controller;

  const TimelinePage({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final p1 = c.config.player1Name;
    final p2 = c.config.player2Name;

    return Scaffold(
      appBar: AppBar(title: const Text('Timeline des événements')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child:
            c.events.isEmpty
                ? const Center(child: Text('Aucun événement enregistré'))
                : ListView.separated(
                  itemCount: c.events.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final e = c.events[idx];
                    final isP1 = e.playerIndex == 0;
                    final name = isP1 ? p1 : p2;
                    final color = isP1 ? Colors.blue : Colors.orange;
                    return ListTile(
                      leading: Text(
                        _formatTime(e.timestamp),
                        style: const TextStyle(fontSize: 12),
                      ),
                      title: Row(
                        children: [
                          CircleAvatar(radius: 10, backgroundColor: color),
                          const SizedBox(width: 8),
                          Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(e.type.toString().split('.').last),
                        ],
                      ),
                      subtitle:
                          e.meta != null && e.meta!.isNotEmpty
                              ? Text(e.meta.toString())
                              : null,
                    );
                  },
                ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
  }
}
