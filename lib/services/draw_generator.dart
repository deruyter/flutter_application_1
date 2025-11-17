import '../models/draw.dart';
import 'dart:math' as math;

/// Generate an empty Draw for a given size.
class DrawGenerator {
  /// Create a draw for [size] players (e.g., 32, 56, 128).
  /// This returns rounds where the first round has `size` slots and each next round halves.
  static Draw emptyDraw(String name, int size) {
    final rounds = <Round>[];
    // compute bracket size (next power of two)
    int bracketSize = 1;
    while (bracketSize < size) bracketSize <<= 1;
    final roundsCount = (math.log(bracketSize) / math.log(2)).ceil();

    // first round: bracketSize slots, fill with players or byes
    final firstRoundSlots = List<Slot>.generate(bracketSize, (i) => Slot());

    final byes = bracketSize - size;
    if (byes > 0) {
      // distribute byes across the bracket: simple approach -> place at fixed seed offsets
      // A typical distribution places byes to top seeds; we'll spread them evenly for now
      final step = bracketSize ~/ (byes == 0 ? 1 : byes);
      int placed = 0;
      for (var i = 0; i < bracketSize && placed < byes; i++) {
        // pick positions at even intervals
        if (i % step == 0) {
          firstRoundSlots[i].seedOrNote = 'Bye';
          placed++;
        }
      }
      // if not all placed (due to integer division), fill from the end
      for (var i = bracketSize - 1; placed < byes && i >= 0; i--) {
        if (firstRoundSlots[i].seedOrNote == null) {
          firstRoundSlots[i].seedOrNote = 'Bye';
          placed++;
        }
      }
    }

    rounds.add(
      Round(name: _roundNameForIndex(0, roundsCount), slots: firstRoundSlots),
    );

    int currentSlots = bracketSize ~/ 2;
    for (var r = 1; r < roundsCount; r++) {
      final roundName = _roundNameForIndex(r, roundsCount);
      final slots = List<Slot>.generate(currentSlots, (i) => Slot());
      rounds.add(Round(name: roundName, slots: slots));
      currentSlots = (currentSlots / 2).ceil();
    }

    return Draw(name: name, size: size, rounds: rounds);
  }

  static String _roundNameForIndex(int idx, int total) {
    final fromFinal = total - idx;
    if (fromFinal == 1) return 'Finale';
    if (fromFinal == 2) return 'Demi-finale';
    if (fromFinal == 3) return 'Quart de finale';
    return '${1 << (fromFinal - 1)}e de finale';
  }
}
