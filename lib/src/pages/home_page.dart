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
  BestOf _bestOf = BestOf.three;
  int _firstServer = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nouvelle partie")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _p1Controller,
              decoration: const InputDecoration(labelText: "Nom Joueur 1"),
            ),
            TextField(
              controller: _p2Controller,
              decoration: const InputDecoration(labelText: "Nom Joueur 2"),
            ),
            const SizedBox(height: 20),
            DropdownButton<BestOf>(
              value: _bestOf,
              items: const [
                DropdownMenuItem(value: BestOf.three, child: Text("Best of 3")),
                DropdownMenuItem(value: BestOf.five, child: Text("Best of 5")),
              ],
              onChanged: (v) => setState(() => _bestOf = v!),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text("Premier serveur : "),
                Expanded(
                  child: DropdownButton<int>(
                    value: _firstServer,
                    items: [
                      DropdownMenuItem(value: 0, child: Text("Joueur 1")),
                      DropdownMenuItem(value: 1, child: Text("Joueur 2")),
                    ],
                    onChanged: (v) => setState(() => _firstServer = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                final config = MatchConfig(
                  player1Name: _p1Controller.text,
                  player2Name: _p2Controller.text,
                  bestOf: _bestOf,
                  firstServerIndex: _firstServer,
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
}
