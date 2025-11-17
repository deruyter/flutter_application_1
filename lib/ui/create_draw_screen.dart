import 'package:flutter/material.dart';
import '../models/tournament_category.dart';
import '../services/draw_generator.dart';
import 'bracket_view.dart';

import '../models/draw.dart';

class CreateDrawScreen extends StatefulWidget {
  const CreateDrawScreen({super.key});

  @override
  State<CreateDrawScreen> createState() => _CreateDrawScreenState();
}

class _CreateDrawScreenState extends State<CreateDrawScreen> {
  TournamentCategory _selectedCategory = TournamentCategory.atp250;
  int? _selectedFormat;
  Draw? _lastDraw;

  @override
  void initState() {
    super.initState();
    final defaults = CategoryInfo.byCategory(_selectedCategory).typicalFormats;
    _selectedFormat = defaults.isNotEmpty ? defaults.first : null;
  }

  void _onCategoryChanged(TournamentCategory? c) {
    if (c == null) return;
    setState(() {
      _selectedCategory = c;
      final defaults = CategoryInfo.byCategory(c).typicalFormats;
      _selectedFormat = defaults.isNotEmpty ? defaults.first : null;
      _lastDraw = null;
    });
  }

  void _generate() {
    if (_selectedFormat == null) return;
    final draw = DrawGenerator.emptyDraw(
      '${CategoryInfo.byCategory(_selectedCategory).displayName} ($_selectedFormat)',
      _selectedFormat!,
    );
    setState(() => _lastDraw = draw);
  }

  @override
  Widget build(BuildContext context) {
    final formats = CategoryInfo.byCategory(_selectedCategory).typicalFormats;
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un tirage vide')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Catégorie: '),
                const SizedBox(width: 8),
                DropdownButton<TournamentCategory>(
                  value: _selectedCategory,
                  items:
                      CategoryInfo.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.category,
                              child: Text(c.displayName),
                            ),
                          )
                          .toList(),
                  onChanged: _onCategoryChanged,
                ),
                const SizedBox(width: 24),
                const Text('Format: '),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedFormat,
                  items:
                      formats
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text(f.toString()),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _selectedFormat = v),
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  onPressed: _generate,
                  child: const Text('Générer'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_lastDraw == null)
              const Text(
                'Aucun tirage généré. Choisissez une catégorie et un format, puis cliquez sur Générer.',
              )
            else
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tirage: ${_lastDraw!.name} — ${_lastDraw!.size} joueurs',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: BracketView(
                            draw: _lastDraw!,
                            onSlotUpdate: (slotId, playerName) {
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
