import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/keypad.dart';
import '../../../core/parts/lesson_header.dart';
import '../../../core/theme/tokens.dart';
import '../../lesson/view_models/place_value.dart';
import '../../lesson/views/break_views.dart';
import '../../lesson/views/place_value_board.dart';
import '../view_models/quick_sums_view_model.dart';

/// Quick sums (LES-16): one sum at a time, typed on the keypad. No score,
/// timer or count. Figma has no Quick sums frames yet (Figma 4.2 shows
/// only its choice): DRAFT layout, the lesson's header and keypad.
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
      if (vm.wobbles > _wobbles) AuraHaptics.wrong();
      _wobbles = vm.wobbles;
      if (vm.startError case final e?) {
        return NeedInternetView(
          detail: e.offline ? null : e.message,
          onRetry: vm.start,
          onGoHome: widget.onHome,
        );
      }
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: switch (vm.stage) {
              QuickStage.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              QuickStage.done => _done(l),
              QuickStage.sideLesson => _side(l),
              _ => _sum(l),
            },
          ),
        ),
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
        LessonHeader(
          line: line,
          onSpeak: () => widget.onSay?.call(line),
          onHome: _home,
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  vm.sum.text.replaceAll('= ?', '=').replaceAll('-', '−'),
                  key: const Key('quickSum'),
                  style: AuraText.title.copyWith(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Wobbly(
              count: vm.wobbles,
              child: Container(
                key: const Key('quickAnswer'),
                constraints: const BoxConstraints(minWidth: 88, minHeight: 64),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AuraColors.blueTint,
                  borderRadius: BorderRadius.circular(AuraRadii.small),
                  border: Border.all(color: AuraColors.blue, width: 3),
                ),
                child: _typed.isEmpty
                    ? const BlinkCaret()
                    : Text(
                        _typed,
                        style: AuraText.title.copyWith(fontSize: 34),
                      ),
              ),
            ),
          ],
        ),
        const Spacer(),
        Keypad(
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

  Widget _done(AppLocalizations l) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Spacer(),
      Text(
        l.kidQuickDone,
        textAlign: TextAlign.center,
        style: AuraText.title.copyWith(fontSize: 32),
      ),
      const Spacer(),
      AuraButton(
        label: l.kidQuickStory,
        color: AuraButtonColor.blue,
        onPressed: widget.onStory,
      ),
      const SizedBox(height: 12),
      AuraButton(
        label: l.kidQuickHome,
        color: AuraButtonColor.white,
        onPressed: widget.onHome,
      ),
    ],
  );
}
