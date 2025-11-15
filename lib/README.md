Tennis Stats — lib/README
==========================

Brief
-----
This Flutter app records tennis match events in an event-sourced controller and computes player statistics. The app is organized under `lib/src` with models, pages, widgets and a central `MatchController` that holds the match state and event history.

Structure
---------
- `lib/main.dart` — app entry point.
- `lib/src/models/` — data models:
  - `match_event.dart` — `MatchEvent` and `EventType` (serialization helpers)
  - `match_models.dart` — `MatchConfig`, `MatchScore`, `SetScore`
  - `player_stats.dart` — counters and helpers for player statistics
  - `enums.dart` — match format helpers
- `lib/src/state/match_controller.dart` — central event-sourced controller. It exposes:
  - `addEvent(MatchEvent)` to record events,
  - `undoLastEvent()` to revert the last event (replay from history),
  - `getPerSetStats()` to compute approximate per-set stats by replay,
  - convenience methods for common events (e.g. `addAce`, `addWinner`).
- `lib/src/pages/` — UI pages (Home, Live, Stats, Timeline, Summary, Input)
- `lib/src/widgets/scoreboard.dart` — scoreboard UI component

Design notes
------------
- Event-sourced: `MatchController.events` is the source-of-truth. All derived state (score, stats) is updated by applying events; undo is implemented by removing the last event and replaying the list.
- Match formats are encapsulated in `MatchFormat` (in `enums.dart`) and control tie-break thresholds, no-ad options, and whether the final set uses a super tie-break.
- The current per-set stats replay in `getPerSetStats()` is an approximation. It should be extended to fully model tie-break point-by-point for precise per-set metrics.

How to extend / clean up
------------------------
- Move persistent-export logic to a dedicated service (e.g. `lib/src/storage/`) and add unit tests around serialization.
- Add unit tests for `MatchController` behaviors: tie-break serving alternation, no-ad scoring, super tie-break, and undo/replay correctness.
- Improve `getPerSetStats()` accuracy by modelling tie-break points and using event indices to split stats precisely at set boundaries.

Contact / notes
---------------
This file was added to centralize developer-facing documentation and reduce excessive inline comments in source files. Keep code comments only where they explain non-obvious algorithms; prefer Dart doc comments (`///`) for public APIs.
