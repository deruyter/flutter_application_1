import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/match_models.dart';
import '../state/match_controller.dart';
import 'live_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _p1Controller = TextEditingController(text: "Joueur 1");
  final _p2Controller = TextEditingController(text: "Joueur 2");
  final _p1RankController = TextEditingController(text: "NC");
  final _p2RankController = TextEditingController(text: "NC");
  final _p1ClubController = TextEditingController(text: "Club");
  final _p2ClubController = TextEditingController(text: "Club");
  MatchFormat _matchFormat = MatchFormat.format1;
  int _firstServer = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nouvelle partie")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Tennis Stats',
                style: (Theme.of(context).textTheme.titleLarge ??
                        const TextStyle())
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Configure le match et les joueurs',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 18),

            // Player cards
            Row(
              children: [
                Expanded(child: _playerSetupCard(0)),
                const SizedBox(width: 12),
                Expanded(child: _playerSetupCard(1)),
              ],
            ),

            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<MatchFormat>(
                    value: _matchFormat,
                    items:
                        MatchFormat.values
                            .map(
                              (f) => DropdownMenuItem(
                                value: f,
                                child: Text(f.label),
                              ),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => _matchFormat = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<int>(
                    value: _firstServer,
                    items: [
                      DropdownMenuItem(
                        value: 0,
                        child: Text("Premier serveur: Joueur 1"),
                      ),
                      DropdownMenuItem(
                        value: 1,
                        child: Text("Premier serveur: Joueur 2"),
                      ),
                    ],
                    onChanged: (v) => setState(() => _firstServer = v!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () {
                // choose a BestOf fallback consistent with selected format
                final bestOfFallback =
                    _matchFormat.totalSets >= 5 ? BestOf.five : BestOf.three;

                final config = MatchConfig(
                  player1Name: _p1Controller.text,
                  player2Name: _p2Controller.text,
                  bestOf: bestOfFallback,
                  firstServerIndex: _firstServer,
                  matchFormat: _matchFormat,
                  player1Rank: _p1RankController.text,
                  player2Rank: _p2RankController.text,
                  player1Club: _p1ClubController.text,
                  player2Club: _p2ClubController.text,
                );
                final controller = MatchController(config);
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => LivePage(controller: controller),
                  ),
                );
              },
              child: const Text("Démarrer le match"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerSetupCard(int index) {
    final isP1 = index == 0;
    final nameController = isP1 ? _p1Controller : _p2Controller;
    final rankController = isP1 ? _p1RankController : _p2RankController;
    final clubController = isP1 ? _p1ClubController : _p2ClubController;
    final color = isP1 ? Colors.blue.shade600 : Colors.orange.shade700;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color,
                  child: Text('${index + 1}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nom'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: rankController,
              decoration: const InputDecoration(
                labelText: 'Classement (ex: NC, 30/5, 15)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: clubController,
              decoration: const InputDecoration(labelText: 'Club'),
            ),
          ],
        ),
      ),
    );
  }
}
