import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/match_event.dart';
import '../state/match_controller.dart';

/// Timeline page: per-set tabs, per-game rows, centered score and centered point history
class TimelinePage extends StatefulWidget {
  final MatchController controller;

  const TimelinePage({super.key, required this.controller});

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage>
    with TickerProviderStateMixin {
  TabController? _tabController;

  void _updateTabControllerIfNeeded(int visibleCount) {
    // If no visible sets, we don't create a controller here.
    if (visibleCount <= 0) {
      _tabController?.dispose();
      _tabController = null;
      return;
    }

    final old = _tabController;
    final oldIndex = old?.index ?? 0;
    if (old == null || old.length != visibleCount) {
      old?.dispose();
      _tabController = TabController(
        length: visibleCount,
        vsync: this,
        initialIndex: oldIndex < visibleCount ? oldIndex : (visibleCount - 1),
      );
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sets = _reconstructSets(widget.controller);

    // Mirror the Scoreboard: show one tab per Set tracked in the controller
    // (even if a set has no games yet). This ensures the user can switch to
    // the next set tab immediately after a set finishes and see subsequent
    // games appear there.
    final totalSetsVisible = widget.controller.score.sets.length;
    if (totalSetsVisible <= 0) {
      _updateTabControllerIfNeeded(0);
      return Scaffold(
        appBar: AppBar(title: const Text('Déroulement du match')),
        body: const Center(child: Text('Aucun jeu enregistré')),
      );
    }

    final visibleEntries = List<MapEntry<int, List<_GameRecord>>>.generate(
      totalSetsVisible,
      (i) => MapEntry(i, i < sets.length ? sets[i] : <_GameRecord>[]),
    );

    _updateTabControllerIfNeeded(visibleEntries.length);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Déroulement du match'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [for (var v in visibleEntries) Tab(text: 'Set ${v.key + 1}')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (var v in visibleEntries) _buildSetView(context, v.value),
        ],
      ),
    );
  }

  Widget _buildSetView(BuildContext context, List<_GameRecord> games) {
    if (games.isEmpty) {
      return const Center(child: Text('Aucun jeu joué dans ce set'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: games.length,
      separatorBuilder: (_, __) => const Divider(height: 12),
      itemBuilder: (context, idx) {
        final g = games[idx];
        // scoreText computed inline below using fixed-width fields
        final bg = idx % 2 == 0 ? Colors.white : Colors.grey.shade50;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          color: bg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Four-column layout: 1) player icons, 2) games score, 3) point history, 4) service info
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left flexible spacer
                  const Expanded(child: SizedBox()),

                  // Column 1: single tennis-ball icon colored by current server
                  SizedBox(
                    width: 56,
                    child: Center(
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: (g.server == 0
                                ? Colors.blue
                                : Colors.orange)
                            .withAlpha(220),
                        child: const Icon(
                          Icons.sports_tennis,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Column 2: show the games score if finished, otherwise "jeu en cours"
                  SizedBox(
                    width: 64,
                    child: Center(
                      child:
                          g.winner == null
                              ? const Text(
                                'jeu en cours',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              )
                              : Text(
                                '${g.player1Games}-${g.player2Games}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Column 3: point history (existing)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text.rich(
                        TextSpan(
                          children: _buildPointSpans(
                            g.pointHistory,
                            dropLastIfFollowed: idx < games.length - 1,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Column 4: show "SERVICE PERDU" in red when it's a break, otherwise empty
                  SizedBox(
                    width: 72,
                    child: Center(
                      child:
                          g.isBreak
                              ? _badge(
                                'SERVICE PERDU',
                                Colors.red.shade700,
                                textColor: Colors.white,
                              )
                              : const SizedBox.shrink(),
                    ),
                  ),

                  // Right flexible spacer
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }

  Widget _badge(String text, Color bg, {Color textColor = Colors.black}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
        softWrap: true,
        maxLines: 2,
        overflow: TextOverflow.clip,
      ),
    );
  }

  List<InlineSpan> _buildPointSpans(
    List<String> history, {
    bool dropLastIfFollowed = false,
    String? prevLast,
  }) {
    // Determine whether to drop the last history entry:
    // - dropLastIfFollowed: caller requests dropping the final entry when another
    //   game follows (used to avoid repeating the final score before the next game's description)
    // - prevLast: if provided and equal to history.last, drop it as well
    final shouldDropLast =
        (dropLastIfFollowed && history.isNotEmpty) ||
        (prevLast != null && history.isNotEmpty && history.last == prevLast);
    final items =
        shouldDropLast && history.isNotEmpty
            ? history.sublist(0, history.length - 1)
            : history;
    final spans = <InlineSpan>[];
    for (var i = 0; i < items.length; i++) {
      final entry = items[i];
      var token = '';
      var rest = entry;
      if (entry.startsWith('BM ')) {
        token = 'BM';
        rest = entry.substring(3);
      } else if (entry.startsWith('BS ')) {
        token = 'BS';
        rest = entry.substring(3);
      } else if (entry.startsWith('BB ')) {
        token = 'BB';
        rest = entry.substring(3);
      }

      if (token.isNotEmpty) {
        final Color badgeColor =
            token == 'BM'
                ? Colors.purple.shade700
                : (token == 'BS'
                    ? Colors.amber.shade700
                    : Colors.orange.shade700);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                token,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: rest,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      );
      if (i < items.length - 1) {
        spans.add(const TextSpan(text: ', ', style: TextStyle(fontSize: 12)));
      }
    }
    return spans;
  }

  List<List<_GameRecord>> _reconstructSets(MatchController c) {
    final result = <List<_GameRecord>>[];
    var server = c.config.firstServerIndex;
    var inTie = false;
    var tiePoints = [0, 0];
    var points = [0, 0];
    var setP1 = 0;
    var setP2 = 0;

    var currentSet = <_GameRecord>[];
    _GameRecord currentGame = _GameRecord(
      server: server,
      player1Games: setP1,
      player2Games: setP2,
    );

    String ptsLabel(int v) {
      switch (v) {
        case 0:
          return '0';
        case 1:
          return '15';
        case 2:
          return '30';
        case 3:
          return '40';
        case 4:
          return 'A';
        default:
          return '';
      }
    }

    bool isGamePoint(int playerIndex) {
      if (inTie) {
        return false;
      }
      final opp = 1 - playerIndex;
      if (points[playerIndex] == 3 && points[opp] < 3) {
        return true;
      }
      if (points[playerIndex] == 4) {
        return true;
      }
      return false;
    }

    bool wouldWinSetIfWinGame(int playerIndex) {
      final p1 = setP1 + (playerIndex == 0 ? 1 : 0);
      final p2 = setP2 + (playerIndex == 1 ? 1 : 0);
      final tbAt = c.config.matchFormat.tiebreakAt;
      if (p1 == tbAt && p2 == tbAt) {
        return false;
      }
      if ((p1 >= 6 || p2 >= 6) && (p1 - p2).abs() >= 2) {
        return true;
      }
      return false;
    }

    bool wouldWinMatchIfWinSet(int playerIndex) {
      final setsToWin = c.config.matchFormat.setsToWin;
      final p1sets =
          setP1 + (playerIndex == 0 && wouldWinSetIfWinGame(0) ? 1 : 0);
      final p2sets =
          setP2 + (playerIndex == 1 && wouldWinSetIfWinGame(1) ? 1 : 0);
      if (p1sets >= setsToWin || p2sets >= setsToWin) {
        return true;
      }
      return false;
    }

    var gameHadBB = false;
    var gameHadBS = false;
    var gameHadBM = false;

    for (final e in c.events) {
      const resolving = {
        EventType.ace,
        EventType.doubleFault,
        EventType.winner,
        EventType.unforcedError,
        EventType.forcedError,
        EventType.point,
        EventType.breakPointWon,
        EventType.breakPointSaved,
      };
      if (!resolving.contains(e.type)) {
        continue;
      }

      int winner;
      if (e.type == EventType.ace ||
          e.type == EventType.winner ||
          e.type == EventType.point ||
          e.type == EventType.breakPointWon ||
          e.type == EventType.breakPointSaved) {
        winner = e.playerIndex;
      } else if (e.type == EventType.doubleFault ||
          e.type == EventType.forcedError ||
          e.type == EventType.unforcedError) {
        winner = 1 - e.playerIndex;
      } else {
        winner = e.playerIndex;
      }

      final receiver = 1 - server;
      final receiverHadBP = isGamePoint(receiver);
      final bsForWinner = wouldWinSetIfWinGame(winner);
      final bmForWinner = wouldWinMatchIfWinSet(winner);

      if (inTie) {
        tiePoints[winner]++;
        if (receiverHadBP) {
          gameHadBB = true;
        }
        if (bsForWinner) {
          gameHadBS = true;
        }
        if (bmForWinner) {
          gameHadBM = true;
        }
        final token =
            bmForWinner
                ? 'BM '
                : (bsForWinner ? 'BS ' : (receiverHadBP ? 'BB ' : ''));
        currentGame.pointHistory.add('$token${tiePoints[0]}-${tiePoints[1]}');
        final opp = 1 - winner;
        if (tiePoints[winner] >= 7 &&
            (tiePoints[winner] - tiePoints[opp]) >= 2) {
          if (winner == 0) {
            setP1++;
          } else {
            setP2++;
          }
          currentGame.player1Games = setP1;
          currentGame.player2Games = setP2;
          currentGame.winner = winner;
          currentGame.hasBreakPoint = gameHadBB;
          currentGame.hasSetPoint = gameHadBS;
          currentGame.hasMatchPoint = gameHadBM;
          currentGame.isBreak = (currentGame.winner != currentGame.server);
          // commit the completed game
          currentSet.add(currentGame);

          // decide next server (next game) before deciding set boundary
          final nextServer = 1 - server;

          // if set finished, push it to result and reset per-set counters
          final setFinished =
              (setP1 >= 6 || setP2 >= 6) && (setP1 - setP2).abs() >= 2;
          if (setFinished) {
            result.add(currentSet);
            // reset per-set counters for the new set
            setP1 = 0;
            setP2 = 0;
            currentSet = <_GameRecord>[];
            // prepare a fresh game for the next set
            currentGame = _GameRecord(
              server: nextServer,
              player1Games: 0,
              player2Games: 0,
            );
          } else {
            // continue current set: create next game carrying current set scores
            currentGame = _GameRecord(
              server: nextServer,
              player1Games: setP1,
              player2Games: setP2,
            );
          }

          server = nextServer;
          inTie = false;
          tiePoints = [0, 0];
          gameHadBB = gameHadBS = gameHadBM = false;
        }
      } else {
        if (points[winner] < 3) {
          points[winner]++;
          final token =
              bmForWinner
                  ? 'BM '
                  : (bsForWinner ? 'BS ' : (receiverHadBP ? 'BB ' : ''));
          currentGame.pointHistory.add(
            '$token${ptsLabel(points[0])}:${ptsLabel(points[1])}',
          );
          if (receiverHadBP) {
            gameHadBB = true;
          }
        } else if (points[winner] == 3) {
          final opp = 1 - winner;
          if (points[opp] < 3) {
            if (winner == 0) {
              setP1++;
            } else {
              setP2++;
            }
            final token =
                bmForWinner
                    ? 'BM '
                    : (bsForWinner ? 'BS ' : (receiverHadBP ? 'BB ' : ''));
            currentGame.pointHistory.add(
              '$token${ptsLabel(points[0])}:${ptsLabel(points[1])}',
            );
            if (receiverHadBP) {
              gameHadBB = true;
            }
            if (bsForWinner) gameHadBS = true;
            if (bmForWinner) gameHadBM = true;
            currentGame.player1Games = setP1;
            currentGame.player2Games = setP2;
            currentGame.winner = winner;
            currentGame.hasBreakPoint = gameHadBB;
            currentGame.hasSetPoint = gameHadBS;
            currentGame.hasMatchPoint = gameHadBM;
            currentGame.isBreak = (currentGame.winner != currentGame.server);
            // commit the game
            currentSet.add(currentGame);

            final nextServer = 1 - server;
            final setFinished =
                (setP1 >= 6 || setP2 >= 6) && (setP1 - setP2).abs() >= 2;
            if (setFinished) {
              result.add(currentSet);
              setP1 = 0;
              setP2 = 0;
              currentSet = <_GameRecord>[];
              currentGame = _GameRecord(
                server: nextServer,
                player1Games: 0,
                player2Games: 0,
              );
            } else {
              currentGame = _GameRecord(
                server: nextServer,
                player1Games: setP1,
                player2Games: setP2,
              );
            }

            server = nextServer;
            points = [0, 0];
            gameHadBB = gameHadBS = gameHadBM = false;
            final tbAt = c.config.matchFormat.tiebreakAt;
            if (!inTie && setP1 == tbAt && setP2 == tbAt) {
              inTie = true;
              tiePoints = [0, 0];
              server = 1 - server;
              currentGame = _GameRecord(
                server: server,
                player1Games: setP1,
                player2Games: setP2,
              );
            }
          } else if (points[opp] == 3) {
            points[winner] = 4;
            final token =
                bmForWinner
                    ? 'BM '
                    : (bsForWinner ? 'BS ' : (receiverHadBP ? 'BB ' : ''));
            currentGame.pointHistory.add(
              '$token${ptsLabel(points[0])}:${ptsLabel(points[1])}',
            );
            if (receiverHadBP) {
              gameHadBB = true;
            }
          } else if (points[opp] == 4) {
            points[opp] = 3;
            final token =
                bmForWinner
                    ? 'BM '
                    : (bsForWinner ? 'BS ' : (receiverHadBP ? 'BB ' : ''));
            currentGame.pointHistory.add(
              '$token${ptsLabel(points[0])}:${ptsLabel(points[1])}',
            );
            if (receiverHadBP) {
              gameHadBB = true;
            }
          }
        } else if (points[winner] == 4) {
          if (winner == 0) {
            setP1++;
          } else {
            setP2++;
          }
          final token =
              bmForWinner
                  ? 'BM '
                  : (bsForWinner ? 'BS ' : (receiverHadBP ? 'BB ' : ''));
          currentGame.pointHistory.add(
            '$token${ptsLabel(points[0])}:${ptsLabel(points[1])}',
          );
          if (receiverHadBP) {
            gameHadBB = true;
          }
          if (bsForWinner) gameHadBS = true;
          if (bmForWinner) gameHadBM = true;
          currentGame.player1Games = setP1;
          currentGame.player2Games = setP2;
          currentGame.winner = winner;
          currentGame.hasBreakPoint = gameHadBB;
          currentGame.hasSetPoint = gameHadBS;
          currentGame.hasMatchPoint = gameHadBM;
          currentGame.isBreak = (currentGame.winner != currentGame.server);
          // commit the game
          currentSet.add(currentGame);

          final nextServer = 1 - server;
          final setFinished =
              (setP1 >= 6 || setP2 >= 6) && (setP1 - setP2).abs() >= 2;
          if (setFinished) {
            result.add(currentSet);
            setP1 = 0;
            setP2 = 0;
            currentSet = <_GameRecord>[];
            currentGame = _GameRecord(
              server: nextServer,
              player1Games: 0,
              player2Games: 0,
            );
          } else {
            currentGame = _GameRecord(
              server: nextServer,
              player1Games: setP1,
              player2Games: setP2,
            );
          }

          server = nextServer;
          points = [0, 0];
          gameHadBB = gameHadBS = gameHadBM = false;
          final tbAt = c.config.matchFormat.tiebreakAt;
          if (!inTie && setP1 == tbAt && setP2 == tbAt) {
            inTie = true;
            tiePoints = [0, 0];
            server = 1 - server;
            currentGame = _GameRecord(
              server: server,
              player1Games: setP1,
              player2Games: setP2,
            );
          }
        }
      }
    }

    if (currentGame.pointHistory.isNotEmpty || currentSet.isNotEmpty) {
      currentGame.player1Games = setP1;
      currentGame.player2Games = setP2;
      currentSet.add(currentGame);
    }

    if (currentSet.isNotEmpty) {
      result.add(currentSet);
    }

    final totalSets = c.config.matchFormat.totalSets;
    while (result.length < totalSets) {
      result.add(<_GameRecord>[]);
    }
    return result;
  }
}

class _GameRecord {
  int server;
  int player1Games;
  int player2Games;
  List<String> pointHistory;
  bool hasBreakPoint;
  bool hasSetPoint;
  bool hasMatchPoint;
  int? winner;
  bool isBreak;

  _GameRecord({
    required this.server,
    required this.player1Games,
    required this.player2Games,
  }) : pointHistory = [],
       hasBreakPoint = false,
       hasSetPoint = false,
       hasMatchPoint = false,
       winner = null,
       isBreak = false;
}
