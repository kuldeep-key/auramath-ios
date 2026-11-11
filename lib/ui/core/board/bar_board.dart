import 'dart:async';
import 'dart:math' as math;

import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../motion/motion.dart';
import '../motion/sparkle_burst.dart';
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
    this.wobbles = 0,
  });

  final ComparisonProblem problem;
  final LessonState state;
  final ValueChanged<LessonInput> onInput;
  final bool glowPiece;
  final bool showHand;

  /// Goes up on each wrong move: bar B wobbles while it's being sized.
  final int wobbles;

  @override
  State<BarBoard> createState() => _BarBoardState();
}

/// Something that just landed, for its star burst.
enum _Landed { barA, barB, gap, total }

class _BarBoardState extends State<BarBoard> {
  BoardPiece? _armed;
  double? _dragStartY;
  double _dragDy = 0;

  // the prototype's board motion
  bool _dragging = false;
  int _homeBack = 0; // a drop that missed: the piece springs home
  int _cheers = 0; // a right answer: the bars bounce
  int _barWobble = 0;
  int _bursts = 0;
  _Landed? _landed;
  Timer? _hintTimer;
  bool _hinting = false; // the hand shows the move, 5 s after a piece

  @override
  void initState() {
    super.initState();
    _hintSoon();
  }

  @override
  void didUpdateWidget(BarBoard old) {
    super.didUpdateWidget(old);
    final was = old.state, now = widget.state;
    if (was.step != now.step) {
      _armed = null;
      _hintSoon();
    }
    final landed = !was.barA && now.barA
        ? _Landed.barA
        : !was.barB && now.barB
        ? _Landed.barB
        : !was.gapPlaced && now.gapPlaced
        ? _Landed.gap
        : !was.totalPlaced && now.totalPlaced
        ? _Landed.total
        : null;
    if (landed != null) {
      _landed = landed;
      _bursts++;
      AuraHaptics.snap();
    }
    if (!was.bFound && now.bFound ||
        was.step != LessonStep.solved && now.step == LessonStep.solved) {
      _cheers++;
    }
    if (widget.wobbles > old.wobbles && now.step == LessonStep.sizeB) {
      _barWobble++;
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  /// A few quiet seconds after a piece shows, a hand shows its move once.
  void _hintSoon() {
    _hintTimer?.cancel();
    _hinting = false;
    if (_piece == null) return;
    _hintTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _dragging || _armed != null) return;
      setState(() => _hinting = true);
      _hintTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _hinting = false);
      });
    });
  }

  /// The child picked the piece up: no hint now.
  void _touched() {
    _hintTimer?.cancel();
    if (_hinting) setState(() => _hinting = false);
  }

  LessonStep get _step => widget.state.step;

  /// The piece this step places, whether it waits in the tray or sits
  /// where it was wrongly dropped.
  BoardPiece? get _stepPiece => switch (_step) {
    LessonStep.drawA || LessonStep.placeB => BoardPiece.bar,
    LessonStep.placeGap => BoardPiece.gap,
    LessonStep.placeTotal => BoardPiece.total,
    _ => null,
  };

  /// The piece in the tray: none while it sits on the board, misplaced.
  BoardPiece? get _piece => widget.state.misplaced == null ? _stepPiece : null;

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
    setState(() {
      _armed = null;
      if (input == null) _homeBack++;
    });
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

  /// A drop target that also accepts the tap alternative; [child] is told
  /// when a piece is over it.
  /// A bar takes a tap only while a gap or total can be put on it: then
  /// it's a target with its name, else just a drawing.
  Widget _zone(_Zone zone, Widget Function(bool hot) child, {String? label}) {
    final bar = zone == _Zone.barA || zone == _Zone.barB;
    final taps =
        !bar || _stepPiece == BoardPiece.gap || _stepPiece == BoardPiece.total;
    return DragTarget<BoardPiece>(
      onAcceptWithDetails: (d) => _drop(d.data, zone),
      builder: (context, candidates, _) => Semantics(
        label: taps ? label : null,
        child: GestureDetector(
          key: Key(zone.name),
          behavior: HitTestBehavior.opaque,
          onTap: taps ? () => _tapZone(zone) : null,
          child: child(candidates.isNotEmpty),
        ),
      ),
    );
  }

  /// A dashed slot that pulses while its piece is on the way.
  Widget _slot(_Zone zone, String label) => _zone(
    zone,
    (hot) => DashedSlot(
      label: label,
      waiting: _armed != null || _dragging || _hinting,
      hot: hot,
    ),
    label: label,
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
    final showTray = _stepPiece != null || _step == LessonStep.sizeB;

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final trayH = showTray ? 76.0 : 0.0;
        final totH = p.ask == Ask.total ? 62.0 : 0.0;
        const capH = 56.0, topH = 40.0;
        final base = trayH + totH + capH;
        final maxH = (h - base - topH).clamp(60.0, double.infinity);
        final bw = ((w - 60) / 2.6).clamp(40.0, 92.0);
        final gapX = (bw * 0.55).clamp(0.0, 48.0);
        final xA = (w - (2 * bw + gapX)) / 2, xB = xA + bw + gapX;

        final bigA = p.big == BigSide.a;
        final hA = (bigA ? 0.85 : 0.48) * maxH;
        final sized = s.bSized;
        final hBFinal = (hA * p.bValue / p.aValue).clamp(0.15 * maxH, maxH);
        final hB = sized
            ? hBFinal
            : (hA + _dragDy * -1).clamp(0.1 * maxH, maxH).toDouble();
        final lo = hA < hB ? hA : hB, hi = hA < hB ? hB : hA;
        final shortX = hA < hB ? xA : xB;
        final bFound = s.bFound;
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
            // naming the heights comes before any drawing (LES-12)
            if (!s.barA && _step != LessonStep.nameQuantities)
              at(xA, base, bw, 0.7 * maxH, _slot(_Zone.slotA, p.a.name))
            else ...[
              at(
                xA,
                base,
                bw,
                hA,
                _zone(
                  _Zone.barA,
                  (_) =>
                      _grown(_cheered(0, const Bar(color: AuraColors.yellow))),
                  label: p.a.name,
                ),
              ),
              at(
                xA - 20,
                base + hA + 6,
                bw + 40,
                30,
                Center(
                  child: Pop(
                    child: Text(
                      '${p.aValue} ${p.unit}',
                      style: AuraText.barValue,
                    ),
                  ),
                ),
              ),
            ],
            // bar B, or its slot
            if (s.barA && !s.barB)
              at(xB, base, bw, 0.7 * maxH, _slot(_Zone.slotB, p.b.name)),
            if (s.barB) ...[
              at(
                xB,
                base,
                bw,
                hB,
                _zone(
                  _Zone.barB,
                  (_) => Wobbly(
                    count: _barWobble,
                    child: _cheered(
                      1,
                      Bar(
                        color: AuraColors.blue,
                        child: bFound
                            // found: the answer grows in (from 1.4×)
                            ? Entrance(
                                duration: const Duration(milliseconds: 400),
                                builder: (context, t, child) => Transform.scale(
                                  scale: 1.4 - 0.4 * t,
                                  child: child,
                                ),
                                child: Text(
                                  '${p.bValue}\n${p.unit}',
                                  textAlign: TextAlign.center,
                                  style: AuraText.barInside,
                                ),
                              )
                            : Text(
                                '?\n${p.unit}',
                                textAlign: TextAlign.center,
                                style: AuraText.barInside,
                              ),
                      ),
                    ),
                  ),
                  label: p.b.name,
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
                (hi - lo).clamp(56.0, maxH),
                _slot(_Zone.gapSlot, '${l.pieceGap}?'),
              ),
            if (s.gapPlaced)
              at(
                shortX,
                base + lo,
                bw,
                (hi - lo).clamp(30.0, maxH),
                Pop(child: GapSegment(label: '${p.diff}')),
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
                    // Figma's caption: the emoji at 26 / 28.6; a picture
                    // of the name under it, so not read out
                    ExcludeSemantics(
                      child: Text(
                        item.pic,
                        style: const TextStyle(fontSize: 26, height: 1.1),
                      ),
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
                bottom: trayH + 4,
                height: 56,
                child: _slot(_Zone.totalSlot, '${l.pieceTotal}?'),
              ),
            if (s.totalPlaced)
              Positioned(
                left: xA,
                width: xB + bw - xA,
                bottom: trayH + 4,
                child: Pop(
                  child: Brace(
                    label: solved ? '${p.total} ${p.unit}' : '? ${p.unit}',
                  ),
                ),
              ),
            // a wrong drop stays where it landed, wobbling (LES-07, Figma W1,
            // W2): tap it to take it back (free, LES-15), or drag it on
            if ((_stepPiece, s.misplaced) case (final p?, final on?))
              Positioned(
                left: (on == Target.barA ? xA : xB) + bw / 2 - 80,
                width: 160,
                bottom: base + (on == Target.barA ? hA : hB) / 2 - 28,
                height: 56,
                child: Center(child: _misplaced(p, l)),
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
                          child: Semantics(
                            button: true,
                            label: l.lessonUndo,
                            child: GestureDetector(
                              key: const Key('undo'),
                              onTap: () => widget.onInput(const Undo()),
                              child: Container(
                                // a child's target: 56 pt (NFR-02)
                                width: 56,
                                height: 56,
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
                        ),
                    ],
                  ),
                ),
              ),
            // star bursts where a piece landed, and on the bars when right
            if (_landed case final landed?)
              Positioned(
                key: ValueKey('burst$_bursts'),
                left: switch (landed) {
                  _Landed.barA => xA + bw / 2,
                  _Landed.barB => xB + bw / 2,
                  _Landed.gap => shortX + bw / 2,
                  _Landed.total => xA + (xB + bw - xA) / 2,
                },
                top:
                    h -
                    switch (landed) {
                      _Landed.barA => base + hA / 2,
                      _Landed.barB => base + hB / 2,
                      _Landed.gap => base + (lo + hi) / 2,
                      _Landed.total => trayH + 20,
                    },
                child: const SparkleBurst(),
              ),
            if (_cheers > 0)
              for (final (i, (x, hBar)) in [(xA, hA), (xB, hB)].indexed)
                Positioned(
                  key: ValueKey('cheer$_cheers$i'),
                  left: x + bw / 2,
                  top: h - (base + hBar / 2),
                  child: const SparkleBurst(count: 8),
                ),
            // the hand: from the piece to where it goes, once at 5 s; twice
            // for a quiet child (40 s)
            if (piece != null && (widget.showHand || _hinting))
              Positioned.fill(
                child: _Hand(
                  key: ValueKey(widget.showHand),
                  from: Offset(w / 2, h - (trayH - 8) / 2),
                  to: switch (_step) {
                    LessonStep.drawA => Offset(
                      xA + bw / 2,
                      h - base - 0.35 * maxH,
                    ),
                    LessonStep.placeB => Offset(
                      xB + bw / 2,
                      h - base - 0.35 * maxH,
                    ),
                    LessonStep.placeGap => Offset(
                      shortX + bw / 2,
                      h - base - (lo + hi) / 2,
                    ),
                    _ => Offset(xA + (xB + bw - xA) / 2, h - trayH - 30),
                  },
                  times: widget.showHand ? 2 : 1,
                ),
              ),
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
    // picked up: bigger, tilted, a deeper shadow (the prototype's .dragging)
    final lifted = Transform.rotate(
      angle: -3 * math.pi / 180,
      child: Transform.scale(
        scale: 1.1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AuraRadii.panel),
            boxShadow: [
              BoxShadow(
                color: AuraColors.navy.withValues(alpha: 0.45),
                offset: const Offset(0, 18),
                blurRadius: 26,
                spreadRadius: -8,
              ),
            ],
          ),
          child: visual,
        ),
      ),
    );
    void dropped({required bool accepted}) {
      setState(() {
        _dragging = false;
        if (!accepted) _homeBack++;
      });
    }

    return Draggable<BoardPiece>(
      key: const Key('piece'),
      data: piece,
      feedback: Material(color: Colors.transparent, child: lifted),
      // the piece itself moves with the finger
      childWhenDragging: Opacity(opacity: 0, child: visual),
      onDragStarted: () {
        _touched();
        setState(() => _dragging = true);
      },
      onDragEnd: (d) => dropped(accepted: d.wasAccepted),
      child: GestureDetector(
        onTap: () {
          _touched();
          setState(() => _armed = _armed == piece ? null : piece);
        },
        // a new piece pops into the tray; it bobs while it waits; a miss
        // springs it home
        child: Entrance(
          key: ValueKey('in${widget.state.step}'),
          duration: const Duration(milliseconds: 380),
          builder: (context, t, child) => Opacity(
            opacity: t,
            child: Transform.scale(
              scale: 0.4 + 0.6 * AuraCurves.spring.transform(t),
              child: child,
            ),
          ),
          child: Entrance(
            key: ValueKey('home$_homeBack'),
            duration: Duration(milliseconds: _homeBack == 0 ? 1 : 450),
            builder: (context, t, child) {
              if (_homeBack == 0) return child!;
              final e = AuraCurves.spring.transform(t);
              final scale = keyframes(e, const [
                (0, 0.85),
                (0.6, 1.06),
                (1, 1),
              ]);
              final turn = keyframes(e, const [(0, 4), (0.6, -2), (1, 0)]);
              return Transform.rotate(
                angle: turn * math.pi / 180,
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: Loop(
              period: const Duration(milliseconds: 2600),
              builder: (context, t, child) => Transform.translate(
                offset: Offset(0, -5 * halfway(t)),
                child: Transform.rotate(
                  angle: -1.5 * halfway(t) * math.pi / 180,
                  child: child,
                ),
              ),
              child: visual,
            ),
          ),
        ),
      ),
    );
  }

  /// The piece where it was wrongly dropped: it wobbles with each wrong
  /// move; a tap takes it back to the tray, a drag moves it on.
  Widget _misplaced(BoardPiece piece, AppLocalizations l) {
    final visual = FittedBox(
      fit: BoxFit.scaleDown,
      child: TrayPiece(
        piece: piece,
        label: piece == BoardPiece.gap ? l.pieceGap : l.pieceTotal,
      ),
    );
    return Draggable<BoardPiece>(
      key: const Key('misplaced'),
      data: piece,
      feedback: Material(color: Colors.transparent, child: visual),
      childWhenDragging: Opacity(opacity: 0.3, child: visual),
      onDragStarted: _touched,
      child: Semantics(
        button: true,
        label: l.lessonTakeBack,
        child: GestureDetector(
          onTap: () => widget.onInput(const Undo()),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Wobbly(count: widget.wobbles, child: visual),
          ),
        ),
      ),
    );
  }

  /// Bar A grows up from the baseline when it's first drawn.
  Widget _grown(Widget bar) => Entrance(
    duration: const Duration(milliseconds: 450),
    builder: (context, t, child) => Transform.scale(
      alignment: Alignment.bottomCenter,
      scaleX: 1,
      scaleY: 0.5 + 0.5 * AuraCurves.spring.transform(t),
      child: child,
    ),
    child: bar,
  );

  /// A right answer: the bar squashes and stretches (620 ms), B 90 ms later.
  Widget _cheered(int i, Widget bar) => _cheers == 0
      ? bar
      : Entrance(
          key: ValueKey('cheer$_cheers'),
          delay: Duration(milliseconds: 90 * i),
          duration: const Duration(milliseconds: 620),
          builder: (context, t, child) {
            final e = Curves.easeOut.transform(t);
            const x = [(0.0, 1.0), (0.25, 1.06), (0.55, 0.96), (1.0, 1.0)];
            const y = [(0.0, 1.0), (0.25, 0.9), (0.55, 1.08), (1.0, 1.0)];
            return Transform.scale(
              alignment: Alignment.bottomCenter,
              scaleX: keyframes(e, x),
              scaleY: keyframes(e, y),
              child: child,
            );
          },
          child: bar,
        );

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

/// The hand that shows a move: it appears on the piece, presses, carries it
/// to where it goes and lets go (2 s); a quiet child sees it twice.
class _Hand extends StatelessWidget {
  const _Hand({
    super.key,
    required this.from,
    required this.to,
    required this.times,
  });

  final Offset from;
  final Offset to;
  final int times;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Loop(
      period: const Duration(milliseconds: 2000),
      times: times,
      builder: (context, t, _) {
        final e = Curves.easeInOut.transform(t);
        final k = ((e - 0.25) / 0.5).clamp(0.0, 1.0);
        final at = Offset.lerp(from, to, k)!;
        final rise = keyframes(e, const [(0, 30), (0.15, 10), (1, 10)]);
        return Stack(
          children: [
            Positioned(
              left: at.dx - 14,
              top: at.dy + rise - 30,
              child: Opacity(
                opacity: keyframes(e, const [
                  (0, 0),
                  (0.15, 1),
                  (0.75, 1),
                  (1, 0),
                ]),
                child: Transform.scale(
                  scale: keyframes(e, const [
                    (0, 0.8),
                    (0.15, 1),
                    (0.25, 0.85),
                    (0.75, 0.85),
                    (1, 1),
                  ]),
                  child: const Text('👆', style: TextStyle(fontSize: 40)),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
