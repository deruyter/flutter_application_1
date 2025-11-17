import 'dart:convert';
import 'package:excel/excel.dart';
import 'dart:io';
import '../models/player.dart';
import '../models/match_model.dart';
import '../models/tournament.dart';
import 'package:uuid/uuid.dart';

class ExcelImportService {
  final String path;

  ExcelImportService(this.path);

  /// Parse the XLSX and return a Tournament-like Map representation.
  /// This is a best-effort parser tailored to the provided example files.
  Future<Tournament> parse() async {
    final bytes = File(path).readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);

    // simple heuristics: find sheet named 'Joueurs' for player list
    List<Player> players = [];
    if (excel.sheets.containsKey('Joueurs')) {
      final sheet = excel['Joueurs'];
      for (var i = 0; i < sheet.maxRows; i++) {
        final row = sheet.row(i);
        if (row.isEmpty) continue;
        final first = row[0]?.value?.toString();
        if (first == null) continue;
        final name = first.trim();
        if (name.isEmpty) continue;
        // skip header words
        if (name.toLowerCase().contains('simple') ||
            name.toLowerCase().contains('bye')) {
          // still add 'Bye' as a special player
          if (name.toLowerCase() == 'bye') {
            players.add(Player(name: 'Bye', note: 'Bye'));
          }
          continue;
        }
        players.add(Player(name: name));
      }
    }

    // For the tournament structure, try to read sheets prefixed with GC_Tableau or GC_Simple
    List<MatchModel> matches = [];
    int generated = 0;
    for (final entry in excel.sheets.entries) {
      final name = entry.key;
      if (name.startsWith('GC_') || name.toLowerCase().contains('tableau')) {
        final sheet = entry.value;
        // Heuristic: scan cells for player names and create ordered slots.
        for (var r = 0; r < sheet.maxRows; r++) {
          final row = sheet.row(r);
          for (var c = 0; c < row.length; c++) {
            final cell = row[c];
            if (cell == null) continue;
            final s = (cell.value ?? '').toString().trim();
            if (s.isEmpty) continue;
            // treat lines that look like a player (contain letters and at least one space)
            if (RegExp(r"[A-Za-z].+\s.+").hasMatch(s) ||
                s.toLowerCase() == 'bye' ||
                s.toLowerCase().startsWith('jannik')) {
              // create a match slot for this cell
              final matchId = Uuid().v4();
              matches.add(
                MatchModel(
                  id: matchId,
                  roundIndex: c, // crude: use column as round index
                  position: generated,
                  player1Id: null,
                  player2Id: null,
                  score: null,
                  note: s,
                ),
              );
              generated++;
            }
          }
        }
      }
    }

    final tournament = Tournament(
      id: Uuid().v4(),
      name: 'Imported Tournament',
      year: null,
      players: players,
      matches: matches,
    );
    return tournament;
  }

  Future<String> parseToJson() async {
    final t = await parse();
    final m = t.toJson();
    return const JsonEncoder.withIndent('  ').convert(m);
  }
}
