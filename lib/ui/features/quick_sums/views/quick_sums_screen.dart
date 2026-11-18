import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../data/services/sound_effects.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/confetti.dart';
import '../../../core/motion/motion.dart';
import '../../../core/motion/play_backdrop.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/keypad.dart';
import '../../../core/parts/lesson_header.dart';
import '../../../core/theme/tokens.dart';
import '../../lesson/view_models/place_value.dart';
import '../../lesson/views/break_views.dart';
import '../../lesson/views/place_value_board.dart';
import '../view_models/quick_sums_view_model.dart';

/// Quick sums (LES-16): one sum at a time, typed on the keypad, on the
/// blue play background: each sum flies in on a white card (260 ms) and
/// away when right (200 ms); a wrong one shakes (220 ms). Then "Warmed
/// up!" with confetti. No score, count or timer is shown (LES-16), and no
/// countdown (SES-02), so the prototype's 3, 2, 1, Go!, its energy meter
/// with its tier toasts and its 30 s fuse are left out.
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

  /// Quick sums never read on their own: the speaker reads on a tap.
  bool _muted = true;

  late int _at = widget.vm.at;

  /// A right answer: its sound, nothing counted on screen.
  void _right() => AuraSound.right();

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
      }
      _wobbles = vm.wobbles;
      if (vm.at > _at) {
        // a sum done: right if it didn't wobble on its last try
        if (vm.stage != QuickStage.loading) _right();
        _at = vm.at;
      }
      if (vm.startError case final e? when e.timesUp) {
        // SES-01: none of the child's time is left today: no sums open
        return Scaffold(body: TimeUpView(onStop: widget.onHome));
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
            muted: _muted,
            onSound: (on) => setState(() => _muted = !on),
            onHome: _home,
          ),
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
          muted: _muted,
          onSound: (on) => setState(() => _muted = !on),
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
