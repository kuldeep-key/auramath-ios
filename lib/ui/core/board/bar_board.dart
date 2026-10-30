import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/tokens.dart';
import 'bar.dart';
import 'brace.dart';
import 'gap_segment.dart';
import 'tray_piece.dart';

/// Where something can be dropped on the board.
enum _Zone { slotA, slotB, gapSlot, totalSlot, barA, barB }

/// The bar-model board. It only draws [state] and reports what the child did
/// as [LessonInput]s; the engine decides what that means. Every drag has a
/// tap alternative (LES-13): tap a piece, then tap where it goes.
class BarBoard extends StatefulWidget {
  const BarBoard({
    super.key,
    required this.problem,
    required this.state,
    required this.onInput,
    this.glowPiece = false,
    this.showHand = false,
  });

  final ComparisonProblem problem;
  final LessonState state;
  final ValueChanged<LessonInput> onInput;
  final bool glowPiece;
  final bool showHand;

  @override
  State<BarBoard> createState() => _BarBoardState();
}

class _BarBoardState extends State<BarBoard> {
  BoardPiece? _armed;
  double? _dragStartY;
  double _dragDy = 0;

  @override
  void didUpdateWidget(BarBoard old) {
    super.didUpdateWidget(old);
    if (old.state.step != widget.state.step) _armed = null;
  }

  LessonStep get _step => widget.state.step;

  BoardPiece? get _piece => switch (_step) {
    LessonStep.drawA || LessonStep.placeB => BoardPiece.bar,
    LessonStep.placeGap => BoardPiece.gap,
    LessonStep.placeTotal => BoardPiece.total,
    _ => null,
  };

  void _drop(BoardPiece piece, _Zone zone) {
    final LessonInput? input = switch ((piece, zone, _step)) {
      (BoardPiece.bar, _Zone.slotA, LessonStep.drawA) => const BarADrawn(),
      (BoardPiece.bar, _Zone.slotB, LessonStep.placeB) => const BarBPlaced(),
      (BoardPiece.gap, _, LessonStep.placeGap) => PieceDropped(
        Piece.gap,
        _target(zone),
      ),
      (BoardPiece.total, _, LessonStep.placeTotal) => PieceDropped(
        Piece.total,
        _target(zone),
      ),
      _ => null,
    };
    setState(() => _armed = null);
    if (input != null) widget.onInput(input);
  }

  Target _target(_Zone z) => switch (z) {
    _Zone.gapSlot => Target.gapSlot,
    _Zone.totalSlot => Target.totalSlot,
    _Zone.barA || _Zone.slotA => Target.barA,
    _Zone.barB || _Zone.slotB => Target.barB,
  };

  void _tapZone(_Zone zone) {
    final armed = _armed;
    if (armed != null) return _drop(armed, zone);
    // Bar slots are the only place a bar can go, so a tap there is enough.
    if (zone == _Zone.slotA || zone == _Zone.slotB) _drop(BoardPiece.bar, zone);
  }

  /// A drop target that also accepts the tap alternative.
  Widget _zone(_Zone zone, Widget child) => DragTarget<BoardPiece>(
    onAcceptWithDetails: (d) => _drop(d.data, zone),
    builder: (context, candidates, _) => GestureDetector(
      key: Key(zone.name),
      behavior: HitTestBehavior.opaque,
      onTap: () => _tapZone(zone),
      child: child,
    ),
  );

  void _endSizing(double maxH) {
    final dy = _dragDy;
    setState(() {
      _dragStartY = null;
      _dragDy = 0;
    });
    final rel = dy > maxH * 0.1
        ? Relation.shorter
        : dy < -maxH * 0.1
        ? Relation.taller
        : Relation.same;
    widget.onInput(BarBSized(rel));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = widget.problem;
    final s = widget.state;
    final piece = _piece;
    final showTray = piece != null || _step == LessonStep.sizeB;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final trayH = showTray ? 76.0 : 0.0;
        final totH = p.ask == Ask.total ? 58.0 : 0.0;
        const capH = 56.0, topH = 40.0;
        final base = trayH + totH + capH;
        final maxH = (h - base - topH).clamp(60.0, double.infinity);
        final bw = ((w - 60) / 2.6).clamp(40.0, 92.0);
        final gapX = (bw * 0.55).clamp(0.0, 48.0);
        final xA = (w - (2 * bw + gapX)) / 2, xB = xA + bw + gapX;

        final bigA = p.big == BigSide.a;
        final hA = (bigA ? 0.85 : 0.48) * maxH;
        final sized = s.step.index > LessonStep.sizeB.index;
        final hBFinal = (hA * p.bValue / p.aValue).clamp(0.15 * maxH, maxH);
        final hB = sized
            ? hBFinal
            : (hA + _dragDy * -1).clamp(0.1 * maxH, maxH).toDouble();
        final lo = hA < hB ? hA : hB, hi = hA < hB ? hB : hA;
        final shortX = hA < hB ? xA : xB;
        final bFound = s.step.index > LessonStep.findB.index;
        final solved = s.step == LessonStep.solved;

        Widget at(
          double x,
          double bottom,
          double width,
          double height,
          Widget child,
        ) => AnimatedPositioned(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutBack,
          left: x,
          bottom: bottom,
          width: width,
          height: height,
          child: child,
        );

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // baseline
            Positioned(
              left: xA - 6,
              width: xB + bw - xA + 12,
              bottom: base - 3,
              height: 6,
              child: Container(
                decoration: BoxDecoration(
                  color: AuraColors.line,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            // bar A, or its slot
            if (!s.barA)
              at(
                xA,
                base,
                bw,
                0.7 * maxH,
                _zone(
                  _Zone.slotA,
                  DashedSlot(label: p.a.name, highlight: _armed != null),
                ),
              )
            else ...[
              at(
                xA,
                base,
                bw,
                hA,
                _zone(_Zone.barA, const Bar(color: AuraColors.yellow)),
              ),
              at(
                xA - 20,
                base + hA + 6,
                bw + 40,
                30,
                Center(
                  child: Text(
                    '${p.aValue} ${p.unit}',
                    style: AuraText.barValue,
                  ),
                ),
              ),
            ],
            // bar B, or its slot
            if (s.barA && !s.barB)
              at(
                xB,
                base,
                bw,
                0.7 * maxH,
                _zone(
                  _Zone.slotB,
                  DashedSlot(label: p.b.name, highlight: _armed != null),
                ),
              ),
            if (s.barB) ...[
              at(
                xB,
                base,
                bw,
                hB,
                _zone(
                  _Zone.barB,
                  Bar(
                    color: AuraColors.blue,
                    child: Text(
                      bFound ? '${p.bValue}\n${p.unit}' : '?\n${p.unit}',
                      textAlign: TextAlign.center,
                      style: AuraText.barInside,
                    ),
                  ),
                ),
              ),
              if (_step == LessonStep.sizeB)
                at(
                  xB + bw / 2 - 24,
                  base + hB - 14,
                  48,
                  28,
                  Listener(
                    key: const Key('handleB'),
                    onPointerDown: (e) => _dragStartY = e.position.dy,
                    onPointerMove: (e) => setState(
                      () => _dragDy =
                          e.position.dy - (_dragStartY ?? e.position.dy),
                    ),
                    onPointerUp: (_) => _endSizing(maxH),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AuraColors.white,
                        borderRadius: BorderRadius.circular(AuraRadii.small),
                        border: Border.all(color: AuraColors.navy, width: 3),
                      ),
                    ),
                  ),
                ),
            ],
            // the gap
            if (_step == LessonStep.placeGap)
              at(
                shortX,
                base + lo,
                bw,
                (hi - lo).clamp(30.0, maxH),
                _zone(
                  _Zone.gapSlot,
                  DashedSlot(
                    label: '${l.pieceGap}?',
                    highlight: _armed != null,
                  ),
                ),
              ),
            if (s.gapPlaced)
              at(
                shortX,
                base + lo,
                bw,
                (hi - lo).clamp(30.0, maxH),
                GapSegment(label: '${p.diff}'),
              ),
            // captions
            for (final (x, item) in [(xA, p.a), (xB, p.b)])
              Positioned(
                left: x - 14,
                width: bw + 28,
                bottom: base - capH,
                height: capH,
                child: Column(
                  children: [
                    // Figma's caption: the emoji at 26 / 28.6
                    Text(
                      item.pic,
                      style: const TextStyle(fontSize: 26, height: 1.1),
                    ),
                    Text(
                      item.name,
                      textAlign: TextAlign.center,
                      style: AuraText.barName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            // the total
            if (_step == LessonStep.placeTotal)
              Positioned(
                left: xA,
                width: xB + bw - xA,
                bottom: trayH + 8,
                height: 44,
                child: _zone(
                  _Zone.totalSlot,
                  DashedSlot(
                    label: '${l.pieceTotal}?',
                    highlight: _armed != null,
                  ),
                ),
              ),
            if (s.totalPlaced)
              Positioned(
                left: xA,
                width: xB + bw - xA,
                bottom: trayH + 4,
                child: Brace(
                  label: solved ? '${p.total} ${p.unit}' : '? ${p.unit}',
                ),
              ),
            // the tray
            if (showTray)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: trayH - 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: AuraColors.blueTint,
                    borderRadius: BorderRadius.circular(AuraRadii.panel),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (piece != null)
                        _trayPiece(piece, switch (piece) {
                          BoardPiece.bar => l.pieceBar,
                          BoardPiece.gap => l.pieceGap,
                          BoardPiece.total => l.pieceTotal,
                        }),
                      if (_step == LessonStep.sizeB)
                        Padding(
                          // leaves the undo key its corner
                          padding: const EdgeInsets.only(left: 12, right: 68),
                          child: Row(
                            children: [
                              Expanded(
                                child: _chip(l.shorter, Relation.shorter),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: _chip(l.taller, Relation.taller)),
                            ],
                          ),
                        ),
                      if (s.barB)
                        Positioned(
                          right: 10,
                          child: GestureDetector(
                            key: const Key('undo'),
                            onTap: () => widget.onInput(const Undo()),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AuraColors.white,
                                borderRadius: BorderRadius.circular(
                                  AuraRadii.small,
                                ),
                                border: Border.all(
                                  color: AuraColors.navy,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.undo_rounded,
                                color: AuraColors.navy,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (widget.showHand && piece != null)
              Positioned(left: w / 2, bottom: trayH / 2, child: const _Hand()),
          ],
        );
      },
    );
  }

  Widget _trayPiece(BoardPiece piece, String label) {
    final visual = TrayPiece(
      piece: piece,
      label: label,
      armed: _armed == piece,
      glow: widget.glowPiece,
    );
    return Draggable<BoardPiece>(
      key: const Key('piece'),
      data: piece,
      feedback: Material(color: Colors.transparent, child: visual),
      childWhenDragging: Opacity(opacity: 0.3, child: visual),
      child: GestureDetector(
        onTap: () => setState(() => _armed = _armed == piece ? null : piece),
        child: visual,
      ),
    );
  }

  /// Tap alternative to dragging B's handle. Not in Figma: drawn as a tray
  /// piece, with a picture of B next to A so it reads without reading.
  Widget _chip(String label, Relation rel) {
    Widget bar(double h, {bool outline = false}) => Container(
      width: 12,
      height: h,
      decoration: BoxDecoration(
        color: outline ? null : AuraColors.blue,
        border: outline ? Border.all(color: AuraColors.navy, width: 2) : null,
        borderRadius: BorderRadius.circular(4),
      ),
    );
    void tap() => widget.onInput(BarBSized(rel));
    return Semantics(
      button: true,
      label: label,
      onTap: tap,
      excludeSemantics: true,
      child: GestureDetector(
        key: Key(rel == Relation.taller ? 'sizeTaller' : 'sizeShorter'),
        onTap: tap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AuraColors.white,
            borderRadius: BorderRadius.circular(AuraRadii.panel),
            border: Border.all(color: AuraColors.blue, width: 3),
            boxShadow: const [
              BoxShadow(color: AuraColors.blueLip, offset: Offset(0, 5)),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  key: const Key('sizePic'),
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    bar(24, outline: true),
                    const SizedBox(width: 4),
                    bar(rel == Relation.taller ? 34 : 14),
                  ],
                ),
                const SizedBox(width: 10),
                Text(label, style: AuraText.standing),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The quiet-child hand: shows where the piece goes, once.
class _Hand extends StatefulWidget {
  const _Hand();

  @override
  State<_Hand> createState() => _HandState();
}

class _HandState extends State<_Hand> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => Opacity(
      // clamped: (1 - 0.85) / 0.15 rounds to just over 1
      opacity: _c.value < 0.85 ? 1 : ((1 - _c.value) / 0.15).clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, -160 * Curves.easeInOut.transform(_c.value)),
        child: const Icon(
          Icons.touch_app_rounded,
          size: 44,
          color: AuraColors.navy,
        ),
      ),
    ),
  );
}
