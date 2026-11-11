import 'dart:math' as math;

import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/board/bar_board.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/keypad.dart';
import '../../../core/parts/lesson_header.dart';
import '../../../core/parts/question_strip.dart';
import '../../../core/parts/standing_button.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';
import 'answer_sheet.dart';
import 'help_sheet.dart';
import 'number_sentence.dart';
import 'question_chips.dart';
import 'thinking_cue.dart';
import 'tutor_prompts.dart';

/// Drawing it out, choosing the sum, and working it out. Figma: M1, D1–D6.
class BoardView extends StatefulWidget {
  const BoardView({super.key, required this.vm, required this.onHome});

  final LessonViewModel vm;
  final VoidCallback onHome;

  @override
  State<BoardView> createState() => _BoardViewState();
}

class _BoardViewState extends State<BoardView> {
  bool _helpOpen = false;
  String _typed = '';

  /// A fresh board straight from the question: the strip flies down into
  /// place and the board fades in (the prototype's M0 → M1).
  late final bool _fromQuestion =
      vm.state.step == LessonStep.drawA && !vm.state.barA;

  late int _wobbles = vm.wobbles;

  /// The option tapped last, which wobbles if it was the wrong one, and
  /// the wrong moves before that tap.
  String? _lastOption;
  int _wobblesAtTap = 0;

  LessonViewModel get vm => widget.vm;

  @override
  void didUpdateWidget(BoardView old) {
    super.didUpdateWidget(old);
    if (vm.wobbles > _wobbles) AuraHaptics.wrong();
    _wobbles = vm.wobbles;
  }

  void _help() => setState(() => _helpOpen = true);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = vm.problem;
    final s = vm.state;
    final rel = p.big == BigSide.a ? l.taller : l.shorter;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LessonHeader(
                big: vm.voice.resting.value,
                line: vm.coachText,
                onSpeak: vm.sayAgain,
                speaking: vm.voice.speaking,
                onHome: widget.onHome,
              ),
              const SizedBox(height: 12),
              _arrive(
                duration: 650,
                builder: (t, child) => Opacity(
                  opacity: 0.3 + 0.7 * t.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(
                      0,
                      220 * (1 - AuraCurves.sheet.transform(t)),
                    ),
                    child: Transform.scale(
                      scale: 1.18 - 0.18 * AuraCurves.sheet.transform(t),
                      child: child,
                    ),
                  ),
                ),
                child: QuestionStrip(
                  chips: [
                    StripChip(label: '${p.a.pic} ${p.aValue}', lit: true),
                    StripChip(
                      label: '${p.diff} ${rel.toLowerCase()}',
                      lit: s.gapPlaced,
                    ),
                  ],
                  onSeeQuestion: vm.seeQuestion,
                  seeQuestionLabel: l.lessonSeeQuestion,
                ),
              ),
              if (vm.questions case final qs when qs.isNotEmpty) ...[
                const SizedBox(height: 8),
                QuestionChips(questions: qs, onAsk: vm.ask),
              ],
              const SizedBox(height: 12),
              Expanded(
                child: _arrive(
                  duration: 500,
                  delay: 300,
                  builder: (t, child) => Opacity(opacity: t, child: child),
                  child: BarBoard(
                    problem: p,
                    state: s,
                    onInput: vm.send,
                    glowPiece: vm.glowPiece,
                    showHand: vm.showHand,
                    wobbles: vm.wobbles,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _bottom(l, p, s),
            ],
          ),
        ),
        if (vm.thinking)
          Positioned(
            top: 84,
            left: 16,
            right: 16,
            child: ThinkingCue(text: l.lessonThinking),
          ),
        if (vm.stillThere) _stillThere(l),
        if (_helpOpen)
          HelpSheet(
            onClose: () => setState(() => _helpOpen = false),
            onChoose: (input) {
              setState(() => _helpOpen = false);
              vm.send(input);
            },
            onEasierSentence: vm.canEaseSentence
                ? () {
                    setState(() => _helpOpen = false);
                    vm.showEasierSentence();
                  }
                : null,
          ),
        if (vm.knowPrompt != null) AnswerSheet(vm: vm),
        if (vm.prompt != null) TutorPromptSheet(vm: vm),
      ],
    );
  }

  /// Plays [builder]'s entrance only on a board fresh from the question.
  Widget _arrive({
    required int duration,
    int delay = 0,
    required Widget Function(double t, Widget child) builder,
    required Widget child,
  }) => !_fromQuestion
      ? child
      : Entrance(
          duration: Duration(milliseconds: duration),
          delay: Duration(milliseconds: delay),
          builder: (context, t, child) => builder(t, child!),
          child: child,
        );

  Widget _bottom(AppLocalizations l, ComparisonProblem p, LessonState s) {
    switch (s.step) {
      case LessonStep.chooseOp || LessonStep.nameQuantities:
        // the template's options (LES-12): D4's sums, or naming the height
        final stepId = specStepId(s.step)!;
        final options = choiceOptions(vm.pack, p, stepId);
        return Column(
          children: [
            if (s.step == LessonStep.nameQuantities)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  p.isMass
                      ? l.lessonNameHowHeavy(p.a.name.toLowerCase())
                      : l.lessonNameHowTall(p.a.name.toLowerCase()),
                  style: AuraText.title,
                  textAlign: TextAlign.center,
                ),
              ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in options)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: options.length > 2 ? 100 : 150,
                    ),
                    child: Wobbly(
                      count: _lastOption == o.id
                          ? vm.wobbles - _wobblesAtTap
                          : 0,
                      child: AuraButton(
                        key: Key('option-${o.id}'),
                        label: o.label,
                        color: AuraButtonColor.white,
                        onPressed: () {
                          setState(() {
                            _lastOption = o.id;
                            _wobblesAtTap = vm.wobbles;
                          });
                          vm.send(o.input(stepId));
                        },
                      ),
                    ),
                  ),
              ],
            ),
            TextButton.icon(
              // a child's target: 56 pt (NFR-02)
              style: TextButton.styleFrom(minimumSize: const Size(56, 56)),
              onPressed: _help,
              icon: const Icon(Icons.support_rounded),
              label: Text(l.helpMe, style: AuraText.link),
            ),
          ],
        );
      case LessonStep.numberSentence:
        return Column(
          children: [
            Text(
              l.lessonSentenceTitle(p.b.name.toLowerCase()),
              style: AuraText.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            SentenceBuilder(
              problem: p,
              wobbles: vm.wobbles,
              onSentence: vm.send,
            ),
            TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(56, 56)),
              onPressed: _help,
              icon: const Icon(Icons.support_rounded),
              label: Text(l.helpMe, style: AuraText.link),
            ),
          ],
        );
      case LessonStep.findB || LessonStep.findTotal:
        final sentence = s.step == LessonStep.findB
            ? '${p.aValue} ${s.op == Op.add ? '+' : '−'} ${p.diff} ='
            : '${p.aValue} + ${p.bValue} =';
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: vm.easierSentence
                        ? _wordsUnder(l, p, s)
                        : Text(
                            sentence,
                            style: AuraText.title.copyWith(fontSize: 32),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                _AnswerBox(text: _typed, wobbles: vm.wobbles),
                const SizedBox(width: 8),
                IconButton.outlined(
                  constraints: const BoxConstraints.tightFor(
                    width: 56,
                    height: 56,
                  ),
                  onPressed: _help,
                  icon: const Icon(Icons.support_rounded),
                  tooltip: l.helpMe,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Keypad(
              keyHeight: vm.biggerPad ? 64 : 56,
              key: ValueKey(s.step),
              onChanged: (v) => setState(() => _typed = v),
              onCheck: (v) => vm.send(NumberEntered(int.parse(v))),
            ),
          ],
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(
                child: StandingButton(
                  icon: Icons.lightbulb_rounded,
                  iconColor: AuraColors.yellowInk,
                  label: l.iKnowIt,
                  onPressed: vm.openKnowIt,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StandingButton(
                  icon: Icons.support_rounded,
                  label: l.helpMe,
                  onPressed: _help,
                  attention: vm.helpAttention,
                  nudge: l.trickyTapMe,
                ),
              ),
            ],
          ),
        );
    }
  }

  /// The sum with each number's name under it (TUT-09), so the sentence
  /// reads off the bars above it.
  // Draft: Figma 37.2 shows a different layout; this reuses the sum row.
  Widget _wordsUnder(AppLocalizations l, ComparisonProblem p, LessonState s) {
    final findB = s.step == LessonStep.findB;
    final parts = findB
        ? [
            ('${p.aValue}', '${p.a.pic} ${p.a.name.toLowerCase()}'),
            (s.op == Op.add ? '+' : '−', ''),
            ('${p.diff}', l.lessonSentenceGap),
            ('=', ''),
          ]
        : [
            ('${p.aValue}', '${p.a.pic} ${p.a.name.toLowerCase()}'),
            ('+', ''),
            ('${p.bValue}', '${p.b.pic} ${p.b.name.toLowerCase()}'),
            ('=', ''),
          ];
    return Row(
      key: const Key('easierSentence'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (n, word) in parts)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Text(n, style: AuraText.title.copyWith(fontSize: 32)),
                Text(word, style: AuraText.small),
              ],
            ),
          ),
        // the answer box says what the ? is
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Text(
            findB
                ? '${p.b.pic} ${p.b.name.toLowerCase()}'
                : l.lessonSentenceBoth,
            style: AuraText.small,
          ),
        ),
      ],
    );
  }

  /// "Still there?" or the way-out offer answered (DAT-03).
  void _answered(String choice) =>
      vm.promptAnswered(vm.tooHard ? 'too_hard' : 'still_there', choice);

  Widget _stillThere(AppLocalizations l) => Positioned(
    left: 16,
    right: 16,
    bottom: 110,
    // arrives like the prototype's sheets
    child: Entrance(
      duration: const Duration(milliseconds: 420),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 60 * (1 - AuraCurves.sheet.transform(t))),
          child: child,
        ),
      ),
      child: Material(
        color: AuraColors.white,
        elevation: 6,
        borderRadius: BorderRadius.circular(AuraRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                vm.tooHard ? l.tooHardTitle : l.stillThere,
                style: AuraText.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              AuraButton(
                label: l.helpMe,
                color: AuraButtonColor.white,
                onPressed: () {
                  _answered('help_me');
                  vm.dismissStillThere();
                  _help();
                },
              ),
              const SizedBox(height: 8),
              AuraButton(
                label: l.anEasierOne,
                color: AuraButtonColor.white,
                onPressed: () {
                  _answered('easier_one');
                  vm.send(EasierTaken(noProgress: vm.tooHard));
                },
              ),
              const SizedBox(height: 8),
              AuraButton(
                label: l.stillThinking,
                color: AuraButtonColor.blue,
                onPressed: () {
                  _answered('still_thinking');
                  vm.dismissStillThere();
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The box a typed answer goes in; it wobbles on a wrong answer.
class _AnswerBox extends StatelessWidget {
  const _AnswerBox({required this.text, required this.wobbles});

  final String text;
  final int wobbles;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: ValueKey(wobbles),
    tween: Tween(begin: 1, end: 0),
    duration: const Duration(milliseconds: 500),
    builder: (context, t, child) => Transform.translate(
      offset: Offset(wobbles == 0 ? 0 : 8 * t * math.sin(t * math.pi * 6), 0),
      child: child,
    ),
    child: Container(
      constraints: const BoxConstraints(minWidth: 72, minHeight: 56),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AuraColors.blueTint,
        borderRadius: BorderRadius.circular(AuraRadii.small),
        border: Border.all(color: AuraColors.blue, width: 3),
      ),
      child: text.isEmpty
          ? const BlinkCaret()
          : Text(text, style: AuraText.title.copyWith(fontSize: 30)),
    ),
  );
}
