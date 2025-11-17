import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../models/draw.dart';

typedef OnSlotUpdate = void Function(String slotId, String? playerName);

class BracketView extends StatefulWidget {
  final Draw draw;
  final OnSlotUpdate? onSlotUpdate;

  const BracketView({super.key, required this.draw, this.onSlotUpdate});

  @override
  State<BracketView> createState() => _BracketViewState();
}

class _BracketViewState extends State<BracketView> {
  Draw get draw => widget.draw;

  static const double _kCardHeight = 110.0;
  // Increase vertical gap between match cards to prevent visual overlap and overflow
  static const double _kCardGap = 24.0;

  void _updateSlot(String slotId, String? playerName) {
    for (final r in draw.rounds) {
      for (final s in r.slots) {
        if (s.id == slotId) {
          setState(() => s.playerId = playerName);
          widget.onSlotUpdate?.call(slotId, playerName);
          return;
        }
      }
    }
  }

  void _setWinner(int roundIndex, int matchIndex, String? winnerPlayerId) {
    final nextRoundIndex = roundIndex + 1;
    if (nextRoundIndex >= draw.rounds.length) return;

    final nextRound = draw.rounds[nextRoundIndex];
    if (matchIndex < 0 || matchIndex >= nextRound.slots.length) return;

    setState(() {
      nextRound.slots[matchIndex].playerId = winnerPlayerId;

      // Clear downstream rounds that depended on previous winners
      for (var t = nextRoundIndex + 1; t < draw.rounds.length; t++) {
        final distance = t - roundIndex - 1;
        final idx = matchIndex >> distance;
        if (idx >= 0 && idx < draw.rounds[t].slots.length) {
          draw.rounds[t].slots[idx].playerId = null;
        }
      }
    });
  }

  // Scroll controllers for visible scrollbars
  late final ScrollController _verticalController;
  late final ScrollController _horizontalController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _verticalController = ScrollController();
    _horizontalController = ScrollController();
    _focusNode = FocusNode(debugLabel: 'bracket_focus');
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // responsive sizes
    final screenW = MediaQuery.of(context).size.width;
    final playerW = screenW >= 1000 ? 260.0 : (screenW >= 600 ? 200.0 : 160.0);
    const connectorW = 40.0;
    const hPadding = 16.0;

    // compute sizes
    final rounds = draw.rounds.length;
    final matchesPerRound =
        draw.rounds.map((r) => (r.slots.length / 2).ceil()).toList();
    final maxMatches = matchesPerRound.fold<int>(0, (p, n) => n > p ? n : p);
    final totalHeight = maxMatches * (_kCardHeight + _kCardGap) + 32.0;
    final totalWidth = rounds * (playerW + connectorW) + hPadding * 2;

    // compute centers Y recursively so that each next-round match is centered between its two children
    // connectorYOffset nudges the connector attachment point downward so it lands on the
    // divider between the two player rows inside the match card (improves visual alignment)
    const connectorYOffset = 8.0;
    final centers = <int, Map<int, Offset>>{}; // round -> matchIndex -> center

    // round 0 positions
    centers[0] = {};
    final matches0 = matchesPerRound[0];
    for (var m = 0; m < matches0; m++) {
      final x = hPadding + 0 * (playerW + connectorW) + playerW / 2;
      // Use a slightly larger top offset so the first match is not clipped
      final y =
          24.0 +
          m * (_kCardHeight + _kCardGap) +
          _kCardHeight / 2 +
          connectorYOffset;
      centers[0]![m] = Offset(x, y);
    }

    // subsequent rounds: center between children
    for (var ri = 1; ri < rounds; ri++) {
      centers[ri] = {};
      final matches = matchesPerRound[ri];
      for (var m = 0; m < matches; m++) {
        final child1 = centers[ri - 1]![m * 2];
        final child2 =
            centers[ri - 1]!.containsKey(m * 2 + 1)
                ? centers[ri - 1]![m * 2 + 1]
                : null;
        final y = child2 != null ? (child1!.dy + child2.dy) / 2 : (child1!.dy);
        // apply same connectorYOffset so connector points land on the divider area
        final yWithOffset = y + connectorYOffset;
        final x = hPadding + ri * (playerW + connectorW) + playerW / 2;
        centers[ri]![m] = Offset(x, yWithOffset);
      }
    }

    // build connector pairs from match center to its parent center in next round
    final lines = <_Line>[];
    for (var ri = 0; ri < rounds - 1; ri++) {
      final matches = centers[ri]!;
      for (final entry in matches.entries) {
        final mi = entry.key;
        final Offset? from = entry.value;
        final Offset? to = centers[ri + 1]?[mi ~/ 2];
        // create L-shaped path via mid x between columns
        if (from != null && to != null) lines.add(_Line(from, to));
      }
    }

    // Use LayoutBuilder to get available height and show scrollbars
    return LayoutBuilder(
      builder: (context, constraints) {
        // available height the parent gives us (e.g. inside Expanded)
        final availH =
            constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : totalHeight;

        // Fix outer box to available height so Column/Expanded don't overflow.
        return SizedBox(
          height: availH,
          child: Scrollbar(
            controller: _verticalController,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.right,
            child: SingleChildScrollView(
              controller: _verticalController,
              child: SizedBox(
                // ensure inner content has intrinsic height for vertical scrolling
                height: totalHeight,
                child: Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,
                  scrollbarOrientation: ScrollbarOrientation.bottom,
                  // wrap the horizontal scroll with a GestureDetector for drag-to-scroll
                  child: GestureDetector(
                    onTap: () => _focusNode.requestFocus(),
                    onHorizontalDragUpdate: (details) {
                      final pos = _horizontalController.position;
                      final newOffset = (_horizontalController.offset -
                              details.delta.dx)
                          .clamp(0.0, pos.maxScrollExtent);
                      _horizontalController.jumpTo(newOffset);
                    },
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: totalWidth,
                        height: totalHeight,
                        child: Stack(
                          children: [
                            // connectors
                            CustomPaint(
                              size: Size(totalWidth, totalHeight),
                              painter: _ConnectorPainter(lines),
                            ),

                            // player cards positioned at computed centers
                            for (var ri = 0; ri < rounds; ri++)
                              for (final entry in centers[ri]!.entries)
                                Positioned(
                                  left: entry.value.dx - playerW / 2,
                                  top: entry.value.dy - _kCardHeight / 2,
                                  child: SizedBox(
                                    width: playerW,
                                    height: _kCardHeight,
                                    child: _MatchCard(
                                      slot1:
                                          _slotForMatch(ri, entry.key, 0) ??
                                          Slot(seedOrNote: '(vide)'),
                                      slot2: _slotForMatch(ri, entry.key, 1),
                                      roundIndex: ri,
                                      matchIndex: entry.key,
                                      onEditSlot:
                                          (id, name) => _updateSlot(id, name),
                                      onWinnerSelected:
                                          (winnerId) => _setWinner(
                                            ri,
                                            entry.key,
                                            winnerId,
                                          ),
                                      isWinner1: _isSlotWinner(
                                        ri,
                                        entry.key,
                                        _slotForMatch(ri, entry.key, 0),
                                      ),
                                      isWinner2: _isSlotWinner(
                                        ri,
                                        entry.key,
                                        _slotForMatch(ri, entry.key, 1),
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Slot? _slotForMatch(int roundIndex, int matchIndex, int which) {
    final slots = draw.rounds[roundIndex].slots;
    final idx = matchIndex * 2 + which;
    return idx < slots.length ? slots[idx] : null;
  }

  bool _isSlotWinner(int roundIndex, int matchIndex, Slot? s) {
    if (s == null) return false;
    final nextIdx = roundIndex + 1;
    if (nextIdx >= draw.rounds.length) return false;
    final nextRound = draw.rounds[nextIdx];
    if (matchIndex >= nextRound.slots.length) return false;
    final np = nextRound.slots[matchIndex].playerId;
    return np != null && np == s.playerId && s.playerId != null;
  }
}

class _Line {
  final Offset a;
  final Offset b;
  _Line(this.a, this.b);
}

class _ConnectorPainter extends CustomPainter {
  final List<_Line> lines;
  _ConnectorPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.grey.shade500
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    for (final l in lines) {
      final path = Path();
      path.moveTo(l.a.dx, l.a.dy);
      final midX = (l.a.dx + l.b.dx) / 2;
      path.lineTo(midX, l.a.dy);
      path.lineTo(midX, l.b.dy);
      path.lineTo(l.b.dx, l.b.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MatchCard extends StatelessWidget {
  final Slot slot1;
  final Slot? slot2;
  final int roundIndex;
  final int matchIndex;
  final void Function(String slotId, String? name) onEditSlot;
  final void Function(String? winnerId) onWinnerSelected;
  final bool isWinner1;
  final bool isWinner2;

  const _MatchCard({
    Key? key,
    required this.slot1,
    this.slot2,
    required this.roundIndex,
    required this.matchIndex,
    required this.onEditSlot,
    required this.onWinnerSelected,
    this.isWinner1 = false,
    this.isWinner2 = false,
  }) : super(key: key);

  bool get isFirstRound => roundIndex == 0;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _slotRow(context, slot1, true, highlighted: isWinner1),
            const Divider(height: 8),
            if (slot2 != null)
              _slotRow(context, slot2!, false, highlighted: isWinner2),
          ],
        ),
      ),
    );
  }

  Widget _slotRow(
    BuildContext context,
    Slot s,
    bool top, {
    bool highlighted = false,
  }) {
    final label = s.playerId ?? s.seedOrNote ?? '(vide)';
    final style =
        highlighted
            ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)
            : null;
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        // Edit only allowed on first round
        IconButton(
          icon: const Icon(Icons.edit, size: 16),
          onPressed: isFirstRound ? () => _editSlot(context, s) : null,
        ),
        // Winner button: if pressed, propagate to next round
        IconButton(
          icon: const Icon(Icons.emoji_events, size: 16),
          tooltip: 'Marquer gagnant',
          onPressed: () {
            // if no player assigned, treat as clearing
            final winnerId = s.playerId;
            onWinnerSelected(winnerId);
          },
        ),
      ],
    );
  }

  void _editSlot(BuildContext context, Slot s) {
    final controller = TextEditingController(text: s.playerId ?? '');
    showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Attribuer un joueur'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Nom du joueur'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  final v = controller.text.trim();
                  final newName = v.isEmpty ? null : v;
                  onEditSlot(s.id, newName);
                  Navigator.of(ctx).pop();
                },
                child: const Text('Ok'),
              ),
            ],
          ),
    );
  }
}
