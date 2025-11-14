import 'package:flutter/material.dart';
import '../state/match_controller.dart';
import '../models/match_event.dart';

class InputPage extends StatefulWidget {
  final MatchController controller;

  const InputPage({super.key, required this.controller});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saisie rapide'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: () => setState(() => c.undoLastEvent()),
            tooltip: 'Annuler dernier',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(child: _playerColumn(0)),
            const SizedBox(width: 8),
            Expanded(child: _playerColumn(1)),
          ],
        ),
      ),
    );
  }

  Widget _playerColumn(int playerIndex) {
    final name =
        playerIndex == 0
            ? widget.controller.config.player1Name
            : widget.controller.config.player2Name;
    final isServer = playerIndex == widget.controller.currentServerIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _groupTitle('Service'),
        _actionButton(
          'Ace',
          isServer ? () => _addEvent(EventType.ace, playerIndex) : null,
          Colors.green,
        ),
        _actionButton(
          'Double faute',
          isServer ? () => _addEvent(EventType.doubleFault, playerIndex) : null,
          Colors.red,
        ),
        _actionButton(
          '1ère entrée',
          isServer
              ? () => _addEvent(EventType.firstServeIn, playerIndex)
              : null,
          Colors.blue,
        ),
        _actionButton(
          '1ère sortie',
          isServer
              ? () => _addEvent(EventType.firstServeOut, playerIndex)
              : null,
          Colors.orange,
        ),
        const SizedBox(height: 8),
        _groupTitle('Jeu'),
        _actionButton(
          'Coup gagnant',
          () => _addEvent(EventType.winner, playerIndex),
          Colors.greenAccent,
        ),
        _actionButton(
          'Faute directe',
          () => _addEvent(EventType.unforcedError, playerIndex),
          Colors.redAccent,
        ),
        _actionButton(
          'Point (manuel)',
          () => _addEvent(EventType.point, playerIndex),
          Colors.purple,
        ),
        const SizedBox(height: 8),
        // Break events are detected automatically; explicit break buttons removed.
      ],
    );
  }

  Widget _groupTitle(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );

  Widget _actionButton(String label, VoidCallback? onTap, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            minimumSize: const Size.fromHeight(48),
          ),
          onPressed:
              onTap == null
                  ? null
                  : () {
                    onTap();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$label enregistré')),
                    );
                    setState(() {});
                  },
          child: Text(label),
        ),
      );

  void _addEvent(EventType type, int playerIndex) {
    widget.controller.addEvent(
      MatchEvent(type: type, playerIndex: playerIndex),
    );
  }
}
