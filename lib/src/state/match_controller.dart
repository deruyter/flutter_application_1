import '../models/enums.dart';
import '../models/match_event.dart';
import '../models/match_models.dart';
import '../models/player_stats.dart';

/// Central controller that stores the event history and derived match state.
///
/// Use `addEvent` to record any match event (aces, winners, faults, points, etc.).
/// The controller keeps an ordered `events` list which is the source-of-truth; derived
/// state (score, player stats) is computed by applying events. Call `undoLastEvent`
/// to remove the final event and replay the history.
class MatchController {
  final MatchConfig config;
  final MatchScore score = MatchScore();
  final List<PlayerStats> stats = [PlayerStats(), PlayerStats()];
  final List<MatchEvent> events = [];
  final List<bool> awaitingSecondServe = [false, false];
  int currentServerIndex;
  // Tie-break internal state
  bool _isSuperTieBreak = false;
  int _tieBreakPointCount =
      0; // number of tie-break points played in current TB
  int _tieBreakTarget =
      7; // points needed to win current TB (7 normal, 10 super)
  int? _tieBreakStartServer;
  // Internal flags previously used for advanced point-tracking have been
  // removed to simplify the controller. Keep the event history as the
  // authoritative source-of-truth and infer state during replay when needed.

  bool matchFinished = false;

  /// Points du jeu normal (0,15,30,40,Avantage)
  List<int> currentPoints = [0, 0];

  /// Points du tie-break
  List<int> tieBreakPoints = [0, 0];

  bool inTieBreak = false;

  MatchController(this.config)
    : currentServerIndex = config.firstServerIndex; // 0 ou 1 selon qui commence

  /// Record an event and apply it to update score/stats.
  ///
  /// The event is appended to `events` and then processed via `_applyEvent`.
  void addEvent(MatchEvent event) {
    // If the match has already finished, ignore further events. This keeps
    // the recorded event history consistent and prevents continuing play
    // after a match-winning condition has been reached. `undoLastEvent`
    // can still remove the final event, allowing replay.
    if (matchFinished) return;

    events.add(event);
    _applyEvent(event);
  }

  /// Remove the last recorded event and recompute derived state by replaying
  /// the remaining events from scratch.
  void undoLastEvent() {
    if (events.isEmpty) return;
    events.removeLast();
    _recomputeFromEvents();
  }

  void _recomputeFromEvents() {
    _resetState();
    for (final e in events) {
      _applyEvent(e);
      if (matchFinished) break;
    }
  }

  /// Toggle service fault for a player: record first serve fault, then if toggled again convert to double fault.
  void toggleServiceFault(int playerIndex) {
    final pending = awaitingSecondServe[playerIndex];
    if (!pending) {
      // record first serve out and mark pending
      addEvent(
        MatchEvent(type: EventType.firstServeOut, playerIndex: playerIndex),
      );
      awaitingSecondServe[playerIndex] = true;
      return;
    }
    // pending == true -> record a double fault for this point.
    // We keep the original firstServeOut event in the history (a double fault
    // semantically includes a first-serve fault followed by a second-serve fault)
    addEvent(MatchEvent(type: EventType.doubleFault, playerIndex: playerIndex));
    awaitingSecondServe[playerIndex] = false;
  }

  void _resetState() {
    // reset score
    score.sets.clear();
    score.sets.add(SetScore());
    score.setsWonP1 = 0;
    score.setsWonP2 = 0;

    // reset points
    currentPoints = [0, 0];
    tieBreakPoints = [0, 0];
    inTieBreak = false;
    _isSuperTieBreak = false;
    _tieBreakPointCount = 0;
    _tieBreakTarget = 7;
    matchFinished = false;

    // reset stats
    stats.clear();
    stats.addAll([PlayerStats(), PlayerStats()]);

    // reset server
    currentServerIndex = config.firstServerIndex;
  }

  // Return the last serve-related event for `playerIndex` that belongs to the
  // current point (used to infer first/second serve context).
  EventType? _lastServeEventForPlayer(int playerIndex) {
    // We must only consider serve events that belong to the current point.
    // Scan backward from the event just before the current one and stop if we
    // encounter a point-resolving event (that marks the end of the previous point).
    // If we find a serve event after the last resolving event, return it; otherwise null.
    const resolving = {
      EventType.ace,
      EventType.doubleFault,
      EventType.winner,
      EventType.unforcedError,
      EventType.forcedError,
      EventType.point,
      EventType.breakPointWon,
    };
    const serveEvents = {
      EventType.firstServeIn,
      EventType.ace,
      EventType.firstServeOut,
      EventType.secondServeIn,
      EventType.secondServeOut,
      EventType.doubleFault,
    };

    for (var i = events.length - 2; i >= 0; i--) {
      final e = events[i];
      // If we hit a resolving event, there is no serve for the current point in history
      if (resolving.contains(e.type)) {
        break;
      }
      if (e.playerIndex != playerIndex) continue;
      if (serveEvents.contains(e.type)) return e.type;
    }
    return null;
  }

  /// Apply a single `MatchEvent` to update stats and scoring state.
  ///
  /// This is the central dispatcher that interprets event types (ace, winner,
  /// double fault, serve in/out, etc.) and updates `stats`, `currentPoints`,
  /// `score`, and other internal flags accordingly.
  void _applyEvent(MatchEvent e) {
    final p = e.playerIndex;
    final opp = 1 - p;
    // Helper: detect if the given player currently has a game-point (would win the game by winning this point).
    bool isGamePointForPlayer(int playerIndex) {
      if (inTieBreak) {
        return false;
      }
      final opponent = 1 - playerIndex;
      // 40 (3) and opponent has less than 40 -> game point
      if (currentPoints[playerIndex] == 3 && currentPoints[opponent] < 3) {
        return true;
      }
      // Advantage (4) is a game-winning point
      if (currentPoints[playerIndex] == 4) {
        return true;
      }
      return false;
    }

    // Helper: if at the start of this point the receiver had a break opportunity, record faced/won/saved accordingly
    void recordBreakIfPresent(int winnerIndex) {
      final server = currentServerIndex;
      final receiver = 1 - server;
      final receiverHadBP = isGamePointForPlayer(receiver);
      if (!receiverHadBP) return;
      // The server is the player who "faced" the break opportunity.
      stats[server].breakPointsFaced++;
      if (winnerIndex == receiver) {
        // receiver converted the break
        stats[receiver].breakPointsWon++;
      } else {
        // server saved the break
        stats[server].breakPointsSaved++;
      }
    }

    // Manage awaitingSecondServe flag:
    // - if event is firstServeOut, mark that player as awaiting second serve
    // - when an event resolves a point (ace, doubleFault, winner, unforcedError, forcedError, point, breakPointWon)
    //   reset awaitingSecondServe for both players so the next point starts at first serve by default.
    if (e.type == EventType.firstServeOut) {
      awaitingSecondServe[p] = true;
    }
    // No-op: serve events are handled below; no separate "point in
    // progress" flag is maintained — the event history defines the flow.
    switch (e.type) {
      case EventType.ace:
        // Ace counts as a first-serve point won
        stats[p].aces++;
        // update serve-related point counters
        {
          final server = currentServerIndex;
          // treat as first serve
          stats[server].firstServeIn++;
          stats[server].firstServePointsTotal++;
          stats[server].firstServePointsWon++;
        }
        // check for break opportunity at start of point and record saved/converted
        recordBreakIfPresent(p);
        addPoint(p);
      case EventType.doubleFault:
        // double fault: server loses point on 2nd serve
        stats[p].doubleFaults++;
        // ensure we also count the first serve fault if it wasn't recorded before
        final server = currentServerIndex;
        final lastServe = _lastServeEventForPlayer(server);
        if (lastServe != EventType.firstServeOut) {
          // if no explicit firstServeOut exists for this point, count it
          stats[server].firstServeOut++;
        }
        // opponent wins point on return of 2nd serve
        stats[server].secondServePointsTotal++;
        stats[opp].secondServeReturnPointsWon++;
        recordBreakIfPresent(opp);
        addPoint(opp);
      case EventType.forcedError:
        stats[p].forcedErrors++;
        // decide serve context and update first/second serve point totals
        recordBreakIfPresent(opp);
        _applyPointServeContext(opp);
        addPoint(opp);
      case EventType.winner:
        stats[p].winners++;
        // winner scored a point; determine serve context (server at time of point)
        recordBreakIfPresent(p);
        _applyPointServeContext(p);
        addPoint(p);
      case EventType.unforcedError:
        stats[p].unforcedErrors++;
        // opponent wins point
        recordBreakIfPresent(opp);
        _applyPointServeContext(opp);
        addPoint(opp);
      case EventType.firstServeIn:
        stats[p].firstServeIn++;
      case EventType.firstServeOut:
        stats[p].firstServeOut++;
      case EventType.secondServeIn:
        stats[p].secondServeIn++;
      case EventType.secondServeOut:
        stats[p].secondServeOut++;
      case EventType.point:
        recordBreakIfPresent(p);
        _applyPointServeContext(p);
        addPoint(p);
      case EventType.breakPointFaced:
        // keep explicit faced event for compatibility
        stats[p].breakPointsFaced++;
      case EventType.breakPointWon:
        // if explicit breakPointWon event is added, rely on automatic detection
        // to increment faced/won counters and avoid double-counting. We still
        // need to award the point.
        recordBreakIfPresent(p);
        _applyPointServeContext(p);
        addPoint(p);
      case EventType.breakPointSaved:
        // explicit saved event: rely on automatic detection to record faced/saved
        recordBreakIfPresent(p);
        _applyPointServeContext(p);
        addPoint(p);
    }

    // If this event resolves a point, reset the awaitingSecondServe flags so next point starts on 1st serve.
    const resolving = {
      EventType.ace,
      EventType.doubleFault,
      EventType.winner,
      EventType.unforcedError,
      EventType.forcedError,
      EventType.point,
      EventType.breakPointWon,
    };
    if (resolving.contains(e.type)) {
      awaitingSecondServe[0] = false;
      awaitingSecondServe[1] = false;
      // point resolved
    }
  }

  // Helper to update first/second serve point counters depending on last serve event
  void _applyPointServeContext(int winnerIndex) {
    final server = currentServerIndex;
    final winner = winnerIndex;

    // find the last serve event for the server (before the current event)
    final lastServe = _lastServeEventForPlayer(server);
    final isFirst =
        lastServe == EventType.firstServeIn ||
        lastServe == EventType.ace ||
        lastServe == null;
    final isSecond = !isFirst;

    if (isFirst) {
      stats[server].firstServePointsTotal++;
      if (winner == server) {
        stats[server].firstServePointsWon++;
      } else {
        // returner won on server's first serve
        stats[winner].firstServeReturnPointsWon++;
      }
    } else if (isSecond) {
      stats[server].secondServePointsTotal++;
      if (winner == server) {
        stats[server].secondServePointsWon++;
      } else {
        stats[winner].secondServeReturnPointsWon++;
      }
    }
  }

  /// Add a point to `playerIndex`. Dispatches to tie-break or normal logic.
  void addPoint(int playerIndex) {
    if (inTieBreak) {
      _addTieBreakPoint(playerIndex);
    } else {
      _addNormalPoint(playerIndex);
    }
    _addPointToServeStats(playerIndex, currentServerIndex);
    if (matchFinished) return;
  }

  /// Points en jeu normal
  void _addNormalPoint(int playerIndex) {
    final opponent = 1 - playerIndex;

    if (currentPoints[playerIndex] < 3) {
      currentPoints[playerIndex]++;
    } else if (currentPoints[playerIndex] == 3) {
      if (currentPoints[opponent] < 3) {
        _winGame(playerIndex);
      } else if (currentPoints[opponent] == 3) {
        // At 40-40: if no-ad scoring configured, next point wins the game
        if (config.matchFormat.noAd) {
          _winGame(playerIndex);
        } else {
          // Passe à Avantage
          currentPoints[playerIndex] = 4;
        }
      } else if (currentPoints[opponent] == 4) {
        // retour à 40-40
        currentPoints[opponent] = 3;
      }
    } else if (currentPoints[playerIndex] == 4) {
      _winGame(playerIndex);
    }
  }

  void _winGame(int playerIndex) {
    currentPoints = [0, 0];
    if (playerIndex == 0) {
      score.currentSet.gamesP1++;
    } else {
      score.currentSet.gamesP2++;
    }
    // update service/return game counters for the completed game
    final server = currentServerIndex;
    final returner = 1 - server;
    // server completed one service game
    stats[server].serviceGamesPlayed++;
    stats[returner].returnGamesPlayed++;
    if (playerIndex == server) {
      stats[server].serviceGamesWon++;
    } else {
      stats[returner].returnGamesWon++;
    }
    // Vérifie tie-break based on selected match format
    final p1 = score.currentSet.gamesP1;
    final p2 = score.currentSet.gamesP2;
    final tbAt = config.matchFormat.tiebreakAt;
    final isFinalSet = score.sets.length == config.matchFormat.totalSets;

    if (p1 == tbAt && p2 == tbAt) {
      // begin tie-break
      inTieBreak = true;
      tieBreakPoints = [0, 0];
      // decide if this tie-break is a super tiebreak (final-set special)
      if (config.matchFormat.finalSetSuperTieBreak && isFinalSet) {
        _isSuperTieBreak = true;
        _tieBreakTarget = 10;
      } else {
        _isSuperTieBreak = false;
        _tieBreakTarget = 7;
      }
      _tieBreakPointCount = 0;
      // the player to serve first in the tie-break is the next server
      currentServerIndex = 1 - currentServerIndex;
      _tieBreakStartServer = currentServerIndex;
    } else {
      _checkSetWin();
      // normal server rotation for next game
      currentServerIndex = 1 - currentServerIndex;
    }
  }

  /// Handle a tie-break point for `playerIndex` and rotate server according to
  /// standard tie-break serving rules (1, then 2/2/2... alternating).
  void _addTieBreakPoint(int playerIndex) {
    final opponent = 1 - playerIndex;
    tieBreakPoints[playerIndex]++;
    _tieBreakPointCount++;

    // Vérifie si le tie-break est gagné (target depends on normal/super TB)
    final target = _tieBreakTarget;
    if (tieBreakPoints[playerIndex] >= target &&
        (tieBreakPoints[playerIndex] - tieBreakPoints[opponent]) >= 2) {
      // winner of tie-break wins the set
      if (playerIndex == 0) {
        score.setsWonP1++;
        score.currentSet.gamesP1 =
            (_isSuperTieBreak ? target : (target == 7 ? 7 : target));
        score.currentSet.gamesP2 =
            (_isSuperTieBreak ? 0 : (target == 7 ? 6 : target - 1));
      } else {
        score.setsWonP2++;
        score.currentSet.gamesP1 =
            (_isSuperTieBreak ? 0 : (target == 7 ? 6 : target - 1));
        score.currentSet.gamesP2 =
            (_isSuperTieBreak ? target : (target == 7 ? 7 : target));
      }
      inTieBreak = false;
      _isSuperTieBreak = false;
      _tieBreakPointCount = 0;
      _tieBreakTarget = 7;
      tieBreakPoints = [0, 0];
      score.sets.add(SetScore());

      if (score.setsWonP1 == config.matchFormat.setsToWin ||
          score.setsWonP2 == config.matchFormat.setsToWin) {
        matchFinished = true;
      }
    } else {
      // rotate server for next tie-break point
      // tie-break serving sequence: 1 point for starting server, then 2,2,2,...
      final q = _tieBreakPointCount + 1; // upcoming point number (1-based)
      final start = _tieBreakStartServer ?? currentServerIndex;
      final oppOfStart = 1 - start;
      int nextServer;
      if (q == 1) {
        nextServer = start;
      } else {
        final pairIndex = ((q - 2) ~/ 2);
        nextServer = (pairIndex % 2 == 0) ? oppOfStart : start;
      }
      currentServerIndex = nextServer;
    }
  }

  void _checkSetWin() {
    final p1 = score.currentSet.gamesP1;
    final p2 = score.currentSet.gamesP2;

    if ((p1 >= 6 || p2 >= 6) && (p1 - p2).abs() >= 2) {
      if (p1 > p2) {
        score.setsWonP1++;
      } else {
        score.setsWonP2++;
      }
      score.sets.add(SetScore());
    }

    if (score.setsWonP1 == config.matchFormat.setsToWin ||
        score.setsWonP2 == config.matchFormat.setsToWin) {
      matchFinished = true;
    }
  }

  // === Helper API for common events (convenience wrappers) ===
  void addAce(int playerIndex) {
    addEvent(MatchEvent(type: EventType.ace, playerIndex: playerIndex));
  }

  void addBreakPointFaced(int playerIndex) {
    addEvent(
      MatchEvent(type: EventType.breakPointFaced, playerIndex: playerIndex),
    );
  }

  void addBreakPointWon(int playerIndex) {
    addEvent(
      MatchEvent(type: EventType.breakPointWon, playerIndex: playerIndex),
    );
  }

  void addBreakPointSaved(int playerIndex) {
    addEvent(
      MatchEvent(type: EventType.breakPointSaved, playerIndex: playerIndex),
    );
  }

  void addDoubleFault(int playerIndex) {
    addEvent(MatchEvent(type: EventType.doubleFault, playerIndex: playerIndex));
  }

  void addWinner(int playerIndex) {
    addEvent(MatchEvent(type: EventType.winner, playerIndex: playerIndex));
  }

  void addUnforcedError(int playerIndex) {
    addEvent(
      MatchEvent(type: EventType.unforcedError, playerIndex: playerIndex),
    );
  }

  void addFirstServe(int playerIndex) {
    addEvent(
      MatchEvent(type: EventType.firstServeIn, playerIndex: playerIndex),
    );
  }

  void _addPointToServeStats(int winnerIndex, int serverIndex) {
    if (winnerIndex == serverIndex) {
      // Le serveur a gagné le point
      stats[serverIndex].pointsWonOnServe++;
    } else {
      // Le joueur en retour a gagné le point
      stats[1 - serverIndex].pointsWonOnReturn++;
    }
  }

  /// Replay the recorded `events` and produce per-set cumulative `PlayerStats`.
  ///
  /// NOTE: this routine currently approximates tie-break behaviour and is
  /// intended as a quick way to compute per-set snapshots. Improve it if you
  /// need exact tie-break per-point statistics.
  List<PlayerStats> getPerSetStats() {
    // snapshots will contain cumulative stats after each set boundary.
    final snapshots = <List<PlayerStats>>[];
    // baseline: zeroed stats before any event
    snapshots.add([PlayerStats(), PlayerStats()]);

    // temp state mirrors the minimal parts of the controller needed for scoring
    final tempStats = [PlayerStats(), PlayerStats()];
    final tempScoreSets = <SetScore>[];
    tempScoreSets.add(SetScore());
    var tempCurrentPoints = [0, 0];
    // tie-break temporary state not modelled in this simplified replay
    var tempCurrentServer = config.firstServerIndex;

    // local helpers that operate on temp state
    void tempWinGame(int playerIndex) {
      tempCurrentPoints = [0, 0];
      final set = tempScoreSets.last;
      if (playerIndex == 0) {
        set.gamesP1++;
      } else {
        set.gamesP2++;
      }

      final server = tempCurrentServer;
      final returner = 1 - server;
      tempStats[server].serviceGamesPlayed++;
      tempStats[returner].returnGamesPlayed++;
      if (playerIndex == server) {
        tempStats[server].serviceGamesWon++;
      } else {
        tempStats[returner].returnGamesWon++;
      }

      final p1 = set.gamesP1;
      final p2 = set.gamesP2;
      if (p1 == 6 && p2 == 6) {
        // tie-break begins; we won't model per-point tie-break counters in this replay
      } else if ((p1 >= 6 || p2 >= 6) && (p1 - p2).abs() >= 2) {
        // set finished
        // commit a clone snapshot
        tempScoreSets.add(SetScore());
        snapshots.add([tempStats[0].clone(), tempStats[1].clone()]);
      }

      tempCurrentServer = 1 - tempCurrentServer;
    }

    void tempAddNormalPoint(int playerIndex) {
      final opponent = 1 - playerIndex;
      if (tempCurrentPoints[playerIndex] < 3) {
        tempCurrentPoints[playerIndex]++;
      } else if (tempCurrentPoints[playerIndex] == 3) {
        if (tempCurrentPoints[opponent] < 3) {
          tempWinGame(playerIndex);
        } else if (tempCurrentPoints[opponent] == 3) {
          tempCurrentPoints[playerIndex] = 4;
        } else if (tempCurrentPoints[opponent] == 4) {
          tempCurrentPoints[opponent] = 3;
        }
      } else if (tempCurrentPoints[playerIndex] == 4) {
        tempWinGame(playerIndex);
      }
    }

    // apply an event to temp state (mirrors _applyEvent but only for counters needed)
    // helper: find last serve event for the tempCurrentServer that occurs after the
    // previous point-resolving event and before index `idx`.
    // helper: detect if temp player has a game-point in the temp state
    bool tempIsGamePointFor(int playerIndex) {
      final opponent = 1 - playerIndex;
      if (tempCurrentPoints[playerIndex] == 3 &&
          tempCurrentPoints[opponent] < 3) {
        return true;
      }
      if (tempCurrentPoints[playerIndex] == 4) {
        return true;
      }
      return false;
    }

    void tempRecordBreakIfPresent(int winnerIndex) {
      final server = tempCurrentServer;
      final receiver = 1 - server;
      final receiverHadBP = tempIsGamePointFor(receiver);
      if (!receiverHadBP) return;
      // server faced the break opportunity in the temp state
      tempStats[server].breakPointsFaced++;
      if (winnerIndex == receiver) {
        tempStats[receiver].breakPointsWon++;
      } else {
        tempStats[server].breakPointsSaved++;
      }
    }

    EventType? findLastServeBefore(int idx, int server) {
      const resolving = {
        EventType.ace,
        EventType.doubleFault,
        EventType.winner,
        EventType.unforcedError,
        EventType.forcedError,
        EventType.point,
        EventType.breakPointWon,
      };
      const serveEvents = {
        EventType.firstServeIn,
        EventType.ace,
        EventType.firstServeOut,
        EventType.secondServeIn,
        EventType.secondServeOut,
        EventType.doubleFault,
      };
      for (var i = idx - 1; i >= 0; i--) {
        final ev = events[i];
        if (resolving.contains(ev.type)) return null;
        if (ev.playerIndex != server) continue;
        if (serveEvents.contains(ev.type)) return ev.type;
      }
      return null;
    }

    for (final e in events) {
      final p = e.playerIndex;
      final opp = 1 - p;
      switch (e.type) {
        case EventType.ace:
          tempStats[p].aces++;
          // first serve in
          tempStats[tempCurrentServer].firstServeIn++;
          tempStats[tempCurrentServer].firstServePointsTotal++;
          tempStats[tempCurrentServer].firstServePointsWon++;
          tempRecordBreakIfPresent(p);
          tempAddNormalPoint(p);
        case EventType.doubleFault:
          tempStats[p].doubleFaults++;
          // ensure the firstServeOut is counted in the temp stats if missing
          final idx = events.indexOf(e);
          final lastServe = findLastServeBefore(idx, tempCurrentServer);
          if (lastServe != EventType.firstServeOut) {
            tempStats[tempCurrentServer].firstServeOut++;
          }
          tempStats[tempCurrentServer].secondServePointsTotal++;
          tempStats[opp].secondServeReturnPointsWon++;
          tempRecordBreakIfPresent(opp);
          tempAddNormalPoint(opp);
        case EventType.forcedError:
          tempStats[p].forcedErrors++;
          // infer serve context: look for recent serve events in the replay sequence before this event
          // For simplicity, approximate by treating as server's last serve was first if a firstServeIn or ace
          // search backwards in events up to current index
          {
            final idx = events.indexOf(e);
            final lastServe = findLastServeBefore(idx, tempCurrentServer);
            final isFirst =
                lastServe == EventType.firstServeIn ||
                lastServe == EventType.ace ||
                lastServe == null;
            if (isFirst) {
              tempStats[tempCurrentServer].firstServePointsTotal++;
              tempStats[opp].firstServeReturnPointsWon++;
            } else {
              tempStats[tempCurrentServer].secondServePointsTotal++;
              tempStats[opp].secondServeReturnPointsWon++;
            }
          }
          tempRecordBreakIfPresent(opp);
          tempAddNormalPoint(opp);
        case EventType.winner:
          tempStats[p].winners++;
          // infer by searching last serve as above
          {
            final idx = events.indexOf(e);
            final lastServe = findLastServeBefore(idx, tempCurrentServer);
            final isFirst =
                lastServe == EventType.firstServeIn ||
                lastServe == EventType.ace ||
                lastServe == null;
            if (isFirst) {
              tempStats[tempCurrentServer].firstServePointsTotal++;
              if (p == tempCurrentServer) {
                tempStats[tempCurrentServer].firstServePointsWon++;
              } else {
                tempStats[p].firstServeReturnPointsWon++;
              }
            } else {
              tempStats[tempCurrentServer].secondServePointsTotal++;
              if (p == tempCurrentServer) {
                tempStats[tempCurrentServer].secondServePointsWon++;
              } else {
                tempStats[p].secondServeReturnPointsWon++;
              }
            }
          }
          tempRecordBreakIfPresent(p);
          tempAddNormalPoint(p);
        case EventType.unforcedError:
          tempStats[p].unforcedErrors++;
          // opponent wins
          // infer serve context for opponent
          {
            final idx = events.indexOf(e);
            final lastServe = findLastServeBefore(idx, tempCurrentServer);
            final isFirst =
                lastServe == EventType.firstServeIn ||
                lastServe == EventType.ace ||
                lastServe == null;
            if (isFirst) {
              tempStats[tempCurrentServer].firstServePointsTotal++;
              tempStats[1 - tempCurrentServer].firstServeReturnPointsWon++;
            } else {
              tempStats[tempCurrentServer].secondServePointsTotal++;
              tempStats[1 - tempCurrentServer].secondServeReturnPointsWon++;
            }
          }
          tempRecordBreakIfPresent(opp);
          tempAddNormalPoint(opp);
        case EventType.firstServeIn:
          tempStats[p].firstServeIn++;
        case EventType.firstServeOut:
          tempStats[p].firstServeOut++;
        case EventType.secondServeIn:
          tempStats[p].secondServeIn++;
        case EventType.secondServeOut:
          tempStats[p].secondServeOut++;
        case EventType.point:
          // generic point event - assume it's a point won by p and try to infer serve
          // We'll treat similar to winner
          {
            final idx = events.indexOf(e);
            final lastServe = findLastServeBefore(idx, tempCurrentServer);
            final isFirst =
                lastServe == EventType.firstServeIn ||
                lastServe == EventType.ace ||
                lastServe == null;
            if (isFirst) {
              tempStats[tempCurrentServer].firstServePointsTotal++;
              if (p == tempCurrentServer) {
                tempStats[tempCurrentServer].firstServePointsWon++;
              } else {
                tempStats[p].firstServeReturnPointsWon++;
              }
            } else {
              tempStats[tempCurrentServer].secondServePointsTotal++;
              if (p == tempCurrentServer) {
                tempStats[tempCurrentServer].secondServePointsWon++;
              } else {
                tempStats[p].secondServeReturnPointsWon++;
              }
            }
          }
          tempRecordBreakIfPresent(p);
          tempAddNormalPoint(p);
        case EventType.breakPointFaced:
          tempStats[p].breakPointsFaced++;
        case EventType.breakPointWon:
          // similar to winner
          {
            final idx = events.indexOf(e);
            final lastServe = findLastServeBefore(idx, tempCurrentServer);
            final isFirst =
                lastServe == EventType.firstServeIn ||
                lastServe == EventType.ace ||
                lastServe == null;
            if (isFirst) {
              tempStats[tempCurrentServer].firstServePointsTotal++;
              if (p == tempCurrentServer) {
                tempStats[tempCurrentServer].firstServePointsWon++;
              } else {
                tempStats[p].firstServeReturnPointsWon++;
              }
            } else {
              tempStats[tempCurrentServer].secondServePointsTotal++;
              if (p == tempCurrentServer) {
                tempStats[tempCurrentServer].secondServePointsWon++;
              } else {
                tempStats[p].secondServeReturnPointsWon++;
              }
            }
          }
          tempRecordBreakIfPresent(p);
          tempAddNormalPoint(p);
        case EventType.breakPointSaved:
          // similar to breakPointWon: award the point to the saving player and
          // update serve-related point counters using last serve inference
          {
            final idx = events.indexOf(e);
            final lastServe = findLastServeBefore(idx, tempCurrentServer);
            final isFirst =
                lastServe == EventType.firstServeIn ||
                lastServe == EventType.ace ||
                lastServe == null;
            if (isFirst) {
              tempStats[tempCurrentServer].firstServePointsTotal++;
              if (p == tempCurrentServer) {
                tempStats[tempCurrentServer].firstServePointsWon++;
              } else {
                tempStats[p].firstServeReturnPointsWon++;
              }
            } else {
              tempStats[tempCurrentServer].secondServePointsTotal++;
              if (p == tempCurrentServer) {
                tempStats[tempCurrentServer].secondServePointsWon++;
              } else {
                tempStats[p].secondServeReturnPointsWon++;
              }
            }
          }
          tempRecordBreakIfPresent(p);
          tempAddNormalPoint(p);
      }
    }

    // Instead of returning ambiguous structure, return the cumulative stats after each set for player 0 only
    // (StatsPage will use PlayerStats.clone/diff helpers to compute per-player values). We'll return the cumulative for player 0 at each set end.
    // Build result: for each snapshot (excluding baseline) return stats for player 0 at that boundary.
    final result = <PlayerStats>[];
    for (var i = 1; i < snapshots.length; i++) {
      result.add(snapshots[i][0].clone());
    }
    return result;
  }
}
