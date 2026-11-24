import 'dart:async';
import 'dart:math' as math;

import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../data/services/sound_effects.dart';
import '../../../l10n/app_localizations.dart';
import '../motion/fx_burst.dart';
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
    this.across = false,
  });

  final ComparisonProblem problem;
  final LessonState state;
  final ValueChanged<LessonInput> onInput;
  final bool glowPiece;
  final bool showHand;

  /// Goes up on each wrong move: bar B wobbles while it's being sized.
  final int wobbles;

  /// Bars drawn across, not upright: a weight story (LES-04, CON-11).
  final bool across;

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
  int _steps = 0; // a step right: the prototype's celebrate('step')
  _Landed? _landed;
  Timer? _hintTimer;
  bool _hinting = false; // the hand shows the move, 5 s after a piece

  // a drop near enough its slot lands in it (24 Nov): each slot's box,
  // the board's, and the size of the piece being dragged
  final _slotKeys = <_Zone, GlobalKey>{};
  final _boardKey = GlobalKey();
  final _trayKey = GlobalKey();
  final _missKey = GlobalKey();
  Size? _dragSize;

  /// Where a wrong drop left the piece (the board's own coordinates, its
  /// centre): it stays there, not at the bar's middle (24 Nov).
  Offset? _missAt;

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
    if (now.misplaced == null || was.step != now.step) _missAt = null;
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
      // SFX.snap as it lands; the gap and the total are right moves too
      AuraSound.snap();
      if (landed == _Landed.gap || landed == _Landed.total) _rightMove();
    }
    // B sized the right way (checkB2): it snaps
    if (!was.bSized && now.bSized) AuraSound.snap();
    // the right sum chosen (pickop)
    if (was.step == LessonStep.chooseOp &&
        now.step != LessonStep.chooseOp &&
        now.op != null) {
      _rightMove();
    }
    if (!was.bFound && now.bFound ||
        was.step != LessonStep.solved && now.step == LessonStep.solved) {
      _cheers++;
      if (!was.bFound && now.bFound) _rightMove();
    }
    if (widget.wobbles > old.wobbles && now.step == LessonStep.sizeB) {
      _barWobble++;
    }
  }

  /// SFX.right, and the step's small celebration over the board.
  void _rightMove() {
    AuraSound.right();
    _steps++;
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

  /// The slot this step's piece goes in.
  _Zone? get _stepSlot => switch (_step) {
    LessonStep.drawA => _Zone.slotA,
    LessonStep.placeB => _Zone.slotB,
    LessonStep.placeGap => _Zone.gapSlot,
    LessonStep.placeTotal => _Zone.totalSlot,
    _ => null,
  };

  static Rect? _boxOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _measure(GlobalKey key) =>
      _dragSize = (key.currentContext?.findRenderObject() as RenderBox?)?.size;

  /// Whether a piece dropped with its top left at [at] (on the screen) is
  /// near enough its slot to land in it: its middle on the slot or just
  /// off its border, or at least 30% of it (or of the slot, when the slot
  /// is the smaller) over the slot. A child's drop on the border counts.
  bool _nearSlot(Offset at) {
    final zone = _stepSlot, size = _dragSize;
    if (zone == null || size == null) return false;
    final slot = _slotKeys[zone] == null ? null : _boxOf(_slotKeys[zone]!);
    if (slot == null) return false;
    final piece = at & size;
    if (slot.inflate(16).contains(piece.center)) return true;
    final over = slot.intersect(piece);
    if (over.width <= 0 || over.height <= 0) return false;
    final least = math.min(
      piece.width * piece.height,
      slot.width * slot.height,
    );
    return over.width * over.height >= 0.3 * least;
  }

  /// The board's own point for a piece dropped with its top left at [at].
  Offset? _boardPoint(Offset at) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    final size = _dragSize;
    if (box == null || size == null) return null;
    return box.globalToLocal(at + size.center(Offset.zero));
  }

  /// A piece dropped on [zone], its top left at [at] when dragged: near
  /// enough its own slot, it lands there instead.
  void _drop(BoardPiece piece, _Zone zone, {Offset? at}) {
    if (at != null && zone != _stepSlot && _nearSlot(at)) zone = _stepSlot!;
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
      // a wrong drop on a bar stays where it was let go
      if (input is PieceDropped &&
          (input.target == Target.barA || input.target == Target.barB)) {
        _missAt = at == null ? null : _boardPoint(at);
      }
    });
    if (input == null) AuraSound.wrong();
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
      onAcceptWithDetails: (d) => _drop(d.data, zone, at: d.offset),
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
      key: _slotKeys.putIfAbsent(zone, GlobalKey.new),
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
    if (widget.across) return _across(l, p, s, piece, showTray);

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        // working the sum out (the prototype's .board.compact): the keypad
        // is up, so the names, the total and the tray step aside and the
        // bars keep their height; each value carries its picture instead
        final compact =
            _step == LessonStep.findB || _step == LessonStep.findTotal;
        final trayH = showTray ? 76.0 : 0.0;
        final totH = p.ask == Ask.total && !compact ? 62.0 : 0.0;
        final capH = compact ? 14.0 : 56.0;
        const topH = 40.0;
        final base = trayH + totH + capH;
        final valueStyle = compact
            ? AuraText.barValue.copyWith(fontSize: 20)
            : AuraText.barValue;
        String valued(String pic, String v) => compact ? '$pic $v' : v;
        // B's value sits inside the top of its bar once there's room
        // (the prototype's .measure.in: white 22, 42 down from the top)
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
          key: _boardKey,
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
                xA - 30,
                base + hA + 10,
                bw + 60,
                34,
                Center(
                  child: Pop(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        valued(p.a.pic, '${p.aValue} ${p.unit}'),
                        style: valueStyle,
                      ),
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
                        childAlignment: Alignment.topCenter,
                        child: hB <= 40
                            ? null
                            : Padding(
                                padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: bFound
                                      // found: the answer grows in (from 1.4x)
                                      ? Entrance(
                                          duration: const Duration(
                                            milliseconds: 400,
                                          ),
                                          builder: (context, t, child) =>
                                              Transform.scale(
                                                scale: 1.4 - 0.4 * t,
                                                child: child,
                                              ),
                                          child: Text(
                                            valued(
                                              p.b.pic,
                                              '${p.bValue} ${p.unit}',
                                            ),
                                            style: AuraText.barInside,
                                          ),
                                        )
                                      : Text(
                                          valued(p.b.pic, '? ${p.unit}'),
                                          style: AuraText.barInside,
                                        ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  label: p.b.name,
                ),
              ),
              if (_step == LessonStep.sizeB)
                at(
                  xB + bw / 2 - 32,
                  base + hB - 22,
                  64,
                  48,
                  Listener(
                    key: const Key('handleB'),
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) => _dragStartY = e.position.dy,
                    onPointerMove: (e) => setState(
                      () => _dragDy =
                          e.position.dy - (_dragStartY ?? e.position.dy),
                    ),
                    onPointerUp: (_) => _endSizing(maxH),
                    child: const Align(
                      alignment: Alignment(0, -0.33),
                      child: _Handle(),
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
              if (!compact)
                Positioned(
                  left: x - 14,
                  width: bw + 28,
                  bottom: base - capH,
                  height: capH,
                  // large text (NFR-04, 1.3x): the caption shrinks into its box
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
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
            if (s.totalPlaced && !compact)
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
              if (_missAt case final m?)
                _missed(m, w, h - trayH, _misplaced(p, l))
              else
                Positioned(
                  left: (on == Target.barA ? xA : xB) + bw / 2 - 80,
                  width: 160,
                  bottom: base + (on == Target.barA ? hA : hB) / 2 - 28,
                  height: 56,
                  child: Center(child: _misplaced(p, l)),
                ),
            // the tray
            if (showTray) _tray(l, s, piece, trayH),
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
            if (_steps > 0)
              Positioned.fill(
                child: FxBurst.moment(
                  FxMoment.step,
                  key: ValueKey('step$_steps'),
                  at: const Offset(0.5, 0.5),
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
      barColor: _step == LessonStep.drawA ? AuraColors.yellow : AuraColors.blue,
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
      // a miss springs home with SFX.soft
      if (!accepted) AuraSound.wrong();
    }

    return Draggable<BoardPiece>(
      key: const Key('piece'),
      data: piece,
      feedback: Material(color: Colors.transparent, child: lifted),
      // the piece itself moves with the finger
      childWhenDragging: Opacity(opacity: 0, child: visual),
      onDragStarted: () {
        _touched();
        _measure(_trayKey);
        setState(() => _dragging = true);
      },
      onDragEnd: (d) {
        // let go off every target but near enough its slot: it lands there
        if (!d.wasAccepted && _nearSlot(d.offset)) {
          setState(() => _dragging = false);
          return _drop(piece, _stepSlot!, at: d.offset);
        }
        dropped(accepted: d.wasAccepted);
      },
      child: GestureDetector(
        key: _trayKey,
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

  /// A weight story's board (LES-04, CON-11): the bars lie across from a
  /// shared left edge, A above B, each named on its left; the gap sits
  /// past the shorter bar's end, and the total is a bracket holding both
  /// on the right. Bar B is sized by dragging its right end. DRAFT design
  /// for Apoorv: Figma has no weight screens yet.
  Widget _across(
    AppLocalizations l,
    ComparisonProblem p,
    LessonState s,
    BoardPiece? piece,
    bool showTray,
  ) => LayoutBuilder(
    builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      final trayH = showTray ? 76.0 : 0.0;
      const capW = 72.0, valueW = 72.0;
      final totW = p.ask == Ask.total ? 64.0 : 0.0;
      final maxL = (w - capW - valueW - totW).clamp(60.0, double.infinity);
      final bw = ((h - trayH - 40) / 3).clamp(56.0, 80.0);
      final rows = 2 * bw + 24;
      final yA = ((h - trayH - rows) / 2).clamp(0.0, double.infinity);
      final yB = yA + bw + 24;
      final bigA = p.big == BigSide.a;
      final lA = (bigA ? 0.85 : 0.48) * maxL;
      final lBFinal = (lA * p.bValue / p.aValue).clamp(0.15 * maxL, maxL);
      final lB = s.bSized
          ? lBFinal
          : (lA - _dragDy).clamp(0.1 * maxL, maxL).toDouble();
      final lo = lA < lB ? lA : lB, hi = lA < lB ? lB : lA;
      final shortY = lA < lB ? yA : yB;

      Widget at(double x, double y, double width, double height, Widget c) =>
          AnimatedPositioned(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            left: x,
            top: y,
            width: width,
            height: height,
            child: c,
          );

      return Stack(
        key: _boardKey,
        clipBehavior: Clip.none,
        children: [
          // the shared left edge
          Positioned(
            left: capW - 3,
            top: yA - 6,
            width: 6,
            height: rows + 12,
            child: Container(
              decoration: BoxDecoration(
                color: AuraColors.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          for (final (y, item) in [(yA, p.a), (yB, p.b)])
            Positioned(
              left: 0,
              top: y,
              width: capW - 8,
              height: bw,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ExcludeSemantics(child: storyPicture(item.pic, 28)),
                  Text(
                    item.name,
                    style: AuraText.barName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          if (!s.barA && _step != LessonStep.nameQuantities)
            at(capW, yA, 0.7 * maxL, bw, _slot(_Zone.slotA, p.a.name))
          else if (s.barA) ...[
            at(
              capW,
              yA,
              lA,
              bw,
              _zone(
                _Zone.barA,
                (_) => _cheered(
                  0,
                  const Bar(color: AuraColors.yellow, across: true),
                ),
                label: p.a.name,
              ),
            ),
            at(
              capW + lA + 6,
              yA,
              valueW,
              bw,
              Align(
                alignment: Alignment.centerLeft,
                child: Text('${p.aValue} ${p.unit}', style: AuraText.barValue),
              ),
            ),
          ],
          if (s.barA && !s.barB)
            at(capW, yB, 0.7 * maxL, bw, _slot(_Zone.slotB, p.b.name)),
          if (s.barB) ...[
            at(
              capW,
              yB,
              lB,
              bw,
              _zone(
                _Zone.barB,
                (_) => Wobbly(
                  count: _barWobble,
                  child: _cheered(
                    1,
                    Bar(
                      color: AuraColors.blue,
                      across: true,
                      child: Text(
                        s.bFound ? '${p.bValue} ${p.unit}' : '? ${p.unit}',
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
                capW + lB - 14,
                yB + bw / 2 - 24,
                28,
                48,
                Listener(
                  key: const Key('handleB'),
                  onPointerDown: (e) => _dragStartY = e.position.dx,
                  // stored as the upright board's dy: right is longer
                  onPointerMove: (e) => setState(
                    () => _dragDy =
                        -(e.position.dx - (_dragStartY ?? e.position.dx)),
                  ),
                  onPointerUp: (_) => _endSizing(maxL),
                  child: const _Handle(across: true),
                ),
              ),
          ],
          if (_step == LessonStep.placeGap)
            at(
              capW + lo,
              shortY,
              (hi - lo).clamp(56.0, maxL),
              bw,
              _slot(_Zone.gapSlot, '${l.pieceGap}?'),
            ),
          if (s.gapPlaced)
            at(
              capW + lo,
              shortY,
              (hi - lo).clamp(56.0, maxL),
              bw,
              Pop(child: GapSegment(label: '${p.diff}')),
            ),
          if (_step == LessonStep.placeTotal)
            at(
              w - totW,
              yA,
              totW,
              rows,
              _slot(_Zone.totalSlot, '${l.pieceTotal}?'),
            ),
          if (s.totalPlaced)
            at(
              w - totW,
              yA,
              totW,
              rows,
              Pop(
                child: AcrossBrace(
                  label: s.step == LessonStep.solved
                      ? '${p.total}\n${p.unit}'
                      : '?\n${p.unit}',
                ),
              ),
            ),
          if ((_stepPiece, s.misplaced) case (final pc?, final on?))
            if (_missAt case final m?)
              _missed(m, w, h - trayH, _misplaced(pc, l))
            else
              Positioned(
                left: capW + (on == Target.barA ? lA : lB) / 2 - 80,
                width: 160,
                top: (on == Target.barA ? yA : yB) + bw / 2 - 28,
                height: 56,
                child: Center(child: _misplaced(pc, l)),
              ),
          if (showTray) _tray(l, s, piece, trayH),
          if (_steps > 0)
            Positioned.fill(
              child: FxBurst.moment(
                FxMoment.step,
                key: ValueKey('step$_steps'),
                at: const Offset(0.5, 0.5),
              ),
            ),
        ],
      );
    },
  );

  /// The tray: the piece waiting, the sizing chips, and undo.
  Widget _tray(
    AppLocalizations l,
    LessonState s,
    BoardPiece? piece,
    double trayH,
  ) => Positioned(
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
                    child: _chip(
                      widget.across ? l.lessonLighter : l.shorter,
                      Relation.shorter,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _chip(
                      widget.across ? l.lessonHeavier : l.taller,
                      Relation.taller,
                    ),
                  ),
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
                      borderRadius: BorderRadius.circular(AuraRadii.small),
                      border: Border.all(color: AuraColors.navy, width: 3),
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
  );

  /// The misplaced piece where it was let go, [m] its centre, kept on the
  /// board ([w] wide, [h] high above the tray).
  Widget _missed(Offset m, double w, double h, Widget piece) => Positioned(
    left: (m.dx - 80).clamp(0.0, math.max(0.0, w - 160)),
    top: (m.dy - 28).clamp(0.0, math.max(0.0, h - 56)),
    width: 160,
    height: 56,
    child: Center(child: piece),
  );

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
      onDragStarted: () {
        _touched();
        _measure(_missKey);
      },
      // let go off every target: near enough its slot it lands there, else
      // it stays where it was let go (24 Nov), not back on the bar
      onDragEnd: (d) {
        if (d.wasAccepted) return;
        if (_nearSlot(d.offset)) return _drop(piece, _stepSlot!, at: d.offset);
        setState(() => _missAt = _boardPoint(d.offset) ?? _missAt);
      },
      child: Semantics(
        key: _missKey,
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

/// The grip on B's top (the prototype's .handle): a white pill, 44 by 28,
/// a navy edge and three navy lines; across, it stands on B's end.
class _Handle extends StatelessWidget {
  const _Handle({this.across = false});

  final bool across;

  @override
  Widget build(BuildContext context) {
    Widget line() => Container(
      width: across ? 3 : 16,
      height: across ? 16 : 3,
      decoration: BoxDecoration(
        color: AuraColors.navy,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    return Container(
      width: across ? 28 : 44,
      height: across ? 44 : 28,
      decoration: BoxDecoration(
        color: AuraColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AuraColors.navy, width: 3),
      ),
      child: Flex(
        direction: across ? Axis.horizontal : Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 2,
        children: [line(), line(), line()],
      ),
    );
  }
}

/// The story's picture: the prototype's Fluent 3D bowl and mug for Julia's
/// weight story (WT1, WT2), else the pack's emoji.
Widget storyPicture(String pic, double size) => switch (pic) {
  '🥣' || '☕' => Image.asset(
    'assets/proto/pictures/${pic == '🥣' ? 'bowl-with-spoon' : 'mug-hot-beverage'}.png',
    width: size,
    height: size,
  ),
  _ => Text(pic, style: TextStyle(fontSize: size * .86)),
};
