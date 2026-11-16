import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../data/services/sound_effects.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/confetti.dart';
import '../../../core/motion/motion.dart';
import '../../../core/motion/play_backdrop.dart';
import '../../../core/motion/sparkle_burst.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/keypad.dart';
import '../../../core/parts/lesson_header.dart';
import '../../../core/theme/tokens.dart';
import '../../lesson/view_models/place_value.dart';
import '../../lesson/views/break_views.dart';
import '../../lesson/views/place_value_board.dart';
import '../view_models/quick_sums_view_model.dart';

/// Quick sums (LES-16): one sum at a time, typed on the keypad, drawn as the
/// prototype's rush (QSgo, QS2, QS3) on the blue play background: a 3, 2, 1,
/// Go! count (700 ms a beat), then each sum flies in on a white card
/// (260 ms) and away when right (200 ms) while the energy meter surges;
/// a wrong one shakes (220 ms). Then "Warmed up!" with confetti. No score,
/// count or timer (LES-16), so the prototype's 30 s fuse is left out.
class QuickSumsScreen extends StatefulWidget {
  const QuickSumsScreen({
    super.key,
    required this.vm,
    required this.onHome,
    required this.onStory,
    this.onSay,
  });

  final QuickSumsViewModel vm;

  /// Reads a line aloud (the speak button).
  final ValueChanged<String>? onSay;
  final VoidCallback onHome;

  /// "A story problem" after the run.
  final VoidCallback onStory;

  @override
  State<QuickSumsScreen> createState() => _QuickSumsScreenState();
}

class _QuickSumsScreenState extends State<QuickSumsScreen> {
  String _typed = '';
  late int _wobbles = widget.vm.wobbles;

  /// The count before the first sum: 0..3 is 3, 2, 1, Go!; null once done.
  int? _count;
  Timer? _beat;
  bool _counted = false;

  /// The meter (0..1) and the run of rights; the tier reached.
  double _energy = 0;
  int _run = 0, _tier = 0, _surges = 0, _toasts = 0;
  String? _toast;
  late int _at = widget.vm.at;

  static const _tiers = [.25, .55, .85];

  void _startCount() {
    _counted = true;
    if (calmMotion(context)) return;
    setState(() => _count = 0);
    _tick();
  }

  void _tick() {
    AuraHaptics.tap();
    AuraSound.tap();
    _beat = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final next = _count! + 1;
      if (next < 4) {
        setState(() => _count = next);
        return _tick();
      }
      // the last beat holds its 700 ms, then the first sum (2.8 s in all)
      setState(() => _count = null);
    });
  }

  /// A right answer: the meter surges, maybe a new mark.
  void _right(AppLocalizations l) {
    _run++;
    _energy = (_energy + .17 + math.min(_run, 6) * .008).clamp(0, 1);
    _surges++;
    AuraSound.right();
    final reached = _tiers.where((t) => _energy >= t).length;
    if (reached > _tier) {
      _tier = reached;
      _toast =
          '${const ['⚡', '🔥', '🚀'][_tier - 1]} '
          '${[l.kidQuickTier1, l.kidQuickTier2, l.kidQuickTier3][_tier - 1]}';
      _toasts++;
      AuraSound.celebrate();
      AuraHaptics.win();
    }
  }

  @override
  void dispose() {
    _beat?.cancel();
    super.dispose();
  }

  QuickSumsViewModel get vm => widget.vm;

  Future<void> _home() async {
    await vm.leave();
    widget.onHome();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: vm,
    builder: (context, _) {
      final l = AppLocalizations.of(context)!;
      if (vm.wobbles > _wobbles) {
        AuraHaptics.wrong();
        AuraSound.wrong();
        _run = 0;
      }
      _wobbles = vm.wobbles;
      if (vm.at > _at) {
        // a sum done: right if it didn't wobble on its last try
        if (vm.stage != QuickStage.loading) _right(l);
        _at = vm.at;
      }
      final playing =
          vm.stage == QuickStage.sum || vm.stage == QuickStage.secondTry;
      if (playing && !_counted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_counted) _startCount();
        });
      }
      if (vm.startError case final e?) {
        return NeedInternetView(
          detail: e.offline ? null : e.message,
          onRetry: vm.start,
          onGoHome: widget.onHome,
        );
      }
      final side = vm.stage == QuickStage.sideLesson;
      final body = switch (vm.stage) {
        QuickStage.loading => const Center(child: CircularProgressIndicator()),
        QuickStage.done => _done(l),
        QuickStage.sideLesson => _side(l),
        _ when _count != null || (!_counted && !calmMotion(context)) =>
          _countdown(l),
        _ => _sum(l),
      };
      // the side lesson stays a lesson screen; the rush is play mode
      return Scaffold(
        body: side
            ? SafeArea(
                child: Padding(padding: const EdgeInsets.all(16), child: body),
              )
            : PlayBackdrop(child: SafeArea(child: body)),
      );
    },
  );

  /// QSgo: 3, 2, 1, Go! in white with a navy drop, each in from 2.2x
  /// (qsTick, 600 ms).
  Widget _countdown(AppLocalizations l) => Center(
    child: Entrance(
      key: ValueKey('count$_count'),
      duration: const Duration(milliseconds: 600),
      builder: (context, t, child) {
        final e = cssFrames(t, const [
          (0, 2.2),
          (.6, .92),
          (1, 1),
        ], AuraCurves.burst);
        return Opacity(
          opacity: (t / .6).clamp(0.0, 1.0),
          child: Transform.scale(scale: e, child: child),
        );
      },
      child: Text(
        switch (_count ?? 0) {
          0 => '3',
          1 => '2',
          2 => '1',
          _ => l.kidQuickGo,
        },
        key: const Key('quickCount'),
        style: AuraText.playTitle.copyWith(
          fontSize: 150,
          color: AuraColors.white,
          height: 1,
          shadows: const [Shadow(color: AuraColors.navy, offset: Offset(0, 8))],
        ),
      ),
    ),
  );

  Widget _sum(AppLocalizations l) {
    final line = switch (vm.stage) {
      QuickStage.secondTry when vm.regroupSlip => l.kidQuickRegroup,
      QuickStage.secondTry => l.kidQuickOneMore,
      _ => l.kidQuickLine,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: LessonHeader(
            line: line,
            onSpeak: () => widget.onSay?.call(line),
            onHome: _home,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: _Meter(level: _energy, surges: _surges),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Shake(
                  count: vm.wobbles,
                  times: 1,
                  child: _Card(
                    key: ValueKey('card${vm.at}'),
                    sum: vm.sum.text
                        .replaceAll('= ?', '=')
                        .replaceAll('-', '−'),
                    typed: _typed,
                  ),
                ),
                const SizedBox(height: 16),
                // the mark reached: qsToast, 1 s
                SizedBox(
                  height: 44,
                  child: _toast == null
                      ? null
                      : _Toast(key: ValueKey(_toasts), text: _toast!),
                ),
              ],
            ),
          ),
        ),
        Keypad(
          ours: true,
          key: ValueKey('${vm.at}'),
          onChanged: (v) => setState(() => _typed = v),
          onCheck: (v) {
            setState(() => _typed = '');
            vm.answer(int.parse(v));
          },
        ),
      ],
    );
  }

  /// The regrouping side lesson on the slipped sum's blocks (LES-16), as
  /// the lesson's T1 works it; then back for the sum's one more try. DRAFT
  /// layout: no Figma frame.
  PlaceValue? _blocks;

  Widget _side(AppLocalizations l) {
    final parts = vm.side!;
    final sum = _blocks ??= PlaceValue(
      left: parts.left,
      right: parts.right,
      subtract: parts.subtract,
    );
    final lines = placeValueLines(l, sum, done: () => l.kidQuickSideDone);
    final tapStep = const {
      PlaceStep.breakTen,
      PlaceStep.breakHundred,
      PlaceStep.makeTen,
      PlaceStep.makeHundred,
    }.contains(sum.step);
    return Column(
      key: const Key('quickSide'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LessonHeader(
          line: lines.last,
          onSpeak: () => widget.onSay?.call(lines.join(' ')),
          onHome: _home,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                Text(
                  '${parts.left} ${parts.subtract ? '−' : '+'} ${parts.right}',
                  textAlign: TextAlign.center,
                  style: AuraText.title.copyWith(fontSize: 30),
                ),
                PlaceValueBoard(sum: sum, onAct: () => setState(sum.act)),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    lines.join('\n'),
                    textAlign: TextAlign.center,
                    style: AuraText.chip.copyWith(fontSize: 22),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (sum.step == PlaceStep.done)
          AuraButton(
            key: const Key('quickSideBack'),
            label: l.kidQuickSideBack,
            color: AuraButtonColor.blue,
            onPressed: () {
              _blocks = null;
              vm.backFromSide();
            },
          )
        else if (!tapStep)
          AuraButton(
            label: l.lessonDoIt,
            color: AuraButtonColor.blue,
            onPressed: () => setState(sum.act),
          ),
      ],
    );
  }

  /// QS3: the ⚡ bursts in, "Warmed up!", confetti (60) and SFX.badge,
  /// the same whatever the answers were (REW-19).
  Widget _done(AppLocalizations l) =>
      _Done(l: l, onStory: widget.onStory, onHome: widget.onHome);
}

class _Done extends StatefulWidget {
  const _Done({required this.l, required this.onStory, required this.onHome});

  final AppLocalizations l;
  final VoidCallback onStory;
  final VoidCallback onHome;

  @override
  State<_Done> createState() => _DoneState();
}

class _DoneState extends State<_Done> {
  @override
  void initState() {
    super.initState();
    AuraSound.badge();
    AuraHaptics.win();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 16,
                  children: [
                    const Burst(
                      child: ExcludeSemantics(
                        child: Text('⚡', style: TextStyle(fontSize: 120)),
                      ),
                    ),
                    Ribbon(text: l.kidQuickDone),
                    Text(
                      l.kidQuickOnToday,
                      textAlign: TextAlign.center,
                      style: AuraText.cheer,
                    ),
                  ],
                ),
              ),
              AuraButton(label: l.kidQuickStory, onPressed: widget.onStory),
              const SizedBox(height: 12),
              AuraButton(
                label: l.kidQuickHome,
                color: AuraButtonColor.white,
                onPressed: widget.onHome,
              ),
            ],
          ),
        ),
        const Positioned.fill(child: IgnorePointer(child: Confetti(count: 60))),
      ],
    );
  }
}

/// The energy meter (`.qsmeter`): a navy track with a white edge, the gold
/// fill growing on a spring (350 ms) with its stripes running and a ✨ at
/// its end, the three marks' pictures along it. Each right answer squashes
/// it (220 ms) and throws sparkles from the fill's end. Never a number.
class _Meter extends StatelessWidget {
  const _Meter({required this.level, required this.surges});

  final double level;
  final int surges;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Entrance(
      key: ValueKey('surge$surges'),
      duration: Duration(milliseconds: surges == 0 ? 1 : 220),
      builder: (context, t, child) => Transform(
        alignment: Alignment.centerLeft,
        transform: Matrix4.diagonal3Values(
          1 + .03 * math.sin(t * math.pi),
          1 + .25 * math.sin(t * math.pi),
          1,
        ),
        child: child,
      ),
      child: SizedBox(
        height: 46,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final hot = level >= .55, max = level >= .85;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AuraColors.navy.withValues(alpha: .38),
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(
                        color: AuraColors.white.withValues(alpha: .6),
                        width: 3,
                      ),
                    ),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: level),
                  duration: const Duration(milliseconds: 350),
                  curve: AuraCurves.spring,
                  builder: (context, v, _) => Positioned(
                    left: 3,
                    top: 3,
                    bottom: 3,
                    width: math.max(40, (w - 6) * v),
                    child: _Fill(hot: hot, max: max),
                  ),
                ),
                for (final (i, at) in const [.25, .55, .85].indexed)
                  Positioned(
                    left: w * at - 14,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Text(
                        const ['⚡', '🔥', '🚀'][i],
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                if (surges > 0)
                  Positioned(
                    key: ValueKey('spark$surges'),
                    left: math.max(40, (w - 6) * level),
                    top: 23,
                    child: const SparkleBurst(count: 7),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// The fill: gold, then orange-gold past the second mark and pink-orange
/// at the top (pulsing), with white stripes running (600 ms) and the
/// sparkle at its end spinning (350 ms each way).
class _Fill extends StatelessWidget {
  const _Fill({required this.hot, required this.max});

  final bool hot;
  final bool max;

  @override
  Widget build(BuildContext context) => Loop(
    period: const Duration(milliseconds: 600),
    builder: (context, t, child) => ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: max
                ? const [
                    Color(0xFFFF5FA2),
                    Color(0xFFFF8A3D),
                    Color(0xFFFFE48A),
                  ]
                : hot
                ? const [
                    Color(0xFFFF8A3D),
                    Color(0xFFFFC531),
                    Color(0xFFFFE48A),
                  ]
                : const [Color(0xFFFFC531), Color(0xFFFFE48A)],
          ),
          boxShadow: const [
            BoxShadow(color: Color(0xFFFFC531), blurRadius: 18),
          ],
        ),
        child: CustomPaint(
          painter: _Stripes(t),
          child: const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 4),
              child: SparkleSpin(
                child: Text('✨', style: TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Stripes extends CustomPainter {
  _Stripes(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x47FFFFFF);
    // 135° stripes, 10 on 10 off, sliding 28 px a loop
    for (var x = -size.height - 28 + 28 * t; x < size.width; x += 20) {
      canvas.drawPath(
        Path()
          ..moveTo(x, size.height)
          ..lineTo(x + 10, size.height)
          ..lineTo(x + 10 + size.height, 0)
          ..lineTo(x + size.height, 0)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Stripes old) => old.t != t;
}

/// The sum on its white card (`.qscard`); it flies in from above (260 ms)
/// as it arrives.
class _Card extends StatelessWidget {
  const _Card({super.key, required this.sum, required this.typed});

  final String sum;
  final String typed;

  @override
  Widget build(BuildContext context) => Entrance(
    duration: const Duration(milliseconds: 260),
    builder: (context, t, child) {
      const out = Curves.easeOut;
      final y = cssFrames(t, const [(0, -60), (.7, 6), (1, 0)], out);
      final s = cssFrames(t, const [(0, .85), (.7, 1.03), (1, 1)], out);
      return Opacity(
        opacity: cssFrames(t, const [(0, 0), (.7, 1), (1, 1)], out),
        child: Transform.translate(
          offset: Offset(0, y),
          child: Transform.scale(scale: s, child: child),
        ),
      );
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      decoration: BoxDecoration(
        color: AuraColors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(color: AuraColors.navy, offset: Offset(0, 8)),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            Text(
              sum,
              key: const Key('quickSum'),
              style: AuraText.title.copyWith(fontSize: 48),
            ),
            Container(
              key: const Key('quickAnswer'),
              constraints: const BoxConstraints(minWidth: 84, minHeight: 66),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AuraColors.blueTint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AuraColors.blue, width: 3),
              ),
              child: typed.isEmpty
                  ? const BlinkCaret()
                  : Text(typed, style: AuraText.title.copyWith(fontSize: 42)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A mark reached (`qsToast`, 1 s): pops in tilted, holds, rises away.
class _Toast extends StatelessWidget {
  const _Toast({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Entrance(
    duration: const Duration(seconds: 1),
    builder: (context, t, child) {
      final s = cssFrames(t, const [
        (0, .4),
        (.25, 1.15),
        (.45, 1),
        (1, 1),
      ], AuraCurves.burst);
      final turn = cssFrames(t, const [(0, -8), (.25, 3), (.45, 0), (1, 0)]);
      final o = cssFrames(t, const [(0, 0), (.25, 1), (.8, 1), (1, 0)]);
      final y = cssFrames(t, const [(0, 0), (.8, 0), (1, -20)]);
      return Opacity(
        opacity: o.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, y),
          child: Transform.rotate(
            angle: turn * math.pi / 180,
            child: Transform.scale(scale: s, child: child),
          ),
        ),
      );
    },
    child: Text(
      text,
      style: AuraText.playTitle.copyWith(
        fontSize: 28,
        color: AuraColors.white,
        shadows: const [Shadow(color: AuraColors.navy, offset: Offset(0, 3))],
      ),
    ),
  );
}
