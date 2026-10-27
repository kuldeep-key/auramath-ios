import 'dart:math' as math;

import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/board/bar_board.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/keypad.dart';
import '../../../core/parts/lesson_header.dart';
import '../../../core/parts/question_strip.dart';
import '../../../core/parts/standing_button.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';
import 'answer_sheet.dart';
import 'help_sheet.dart';

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

  LessonViewModel get vm => widget.vm;

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
                line: vm.coachText,
                onSpeak: vm.sayAgain,
                onHome: widget.onHome,
              ),
              const SizedBox(height: 12),
              QuestionStrip(
                chips: [
                  StripChip(label: '${p.a.pic} ${p.aValue}', lit: true),
                  StripChip(
                    label: '${p.diff} ${rel.toLowerCase()}',
                    lit: s.gapPlaced,
                  ),
                ],
                onSeeQuestion: vm.readQuestion,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: BarBoard(
                  problem: p,
                  state: s,
                  onInput: vm.send,
                  glowPiece: vm.glowPiece,
                  showHand: vm.showHand,
                ),
              ),
              const SizedBox(height: 12),
              _bottom(l, p, s),
            ],
          ),
        ),
        if (vm.stillThere) _stillThere(l),
        if (_helpOpen)
          HelpSheet(
            onClose: () => setState(() => _helpOpen = false),
            onChoose: (input) {
              setState(() => _helpOpen = false);
              vm.send(input);
            },
          ),
        if (vm.knowPrompt != null) AnswerSheet(vm: vm),
      ],
    );
  }

  Widget _bottom(AppLocalizations l, ComparisonProblem p, LessonState s) {
    switch (s.step) {
      case LessonStep.chooseOp:
        return Column(
          children: [
            Row(
              children: [
                for (final (op, sign) in [(Op.subtract, '−'), (Op.add, '+')])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AuraButton(
                        label: '${p.aValue} $sign ${p.diff}',
                        color: AuraButtonColor.white,
                        onPressed: () => vm.send(OpChosen(op)),
                      ),
                    ),
                  ),
              ],
            ),
            TextButton.icon(
              onPressed: _help,
              icon: const Icon(Icons.support_rounded),
              label: Text(
                l.helpMe,
                style: AuraText.chip.copyWith(fontSize: 18),
              ),
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
                    child: Text(
                      sentence,
                      style: AuraText.title.copyWith(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _AnswerBox(text: _typed, wobbles: vm.wobbles),
                const SizedBox(width: 8),
                IconButton.outlined(
                  onPressed: _help,
                  icon: const Icon(Icons.support_rounded),
                  tooltip: l.helpMe,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Keypad(
              key: ValueKey(s.step),
              onChanged: (v) => setState(() => _typed = v),
              onCheck: (v) => vm.send(NumberEntered(v)),
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

  Widget _stillThere(AppLocalizations l) => Positioned(
    left: 16,
    right: 16,
    bottom: 110,
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
              l.stillThere,
              style: AuraText.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            AuraButton(
              label: l.helpMe,
              color: AuraButtonColor.white,
              onPressed: () {
                vm.dismissStillThere();
                _help();
              },
            ),
            const SizedBox(height: 8),
            AuraButton(
              label: l.anEasierOne,
              color: AuraButtonColor.white,
              onPressed: () => vm.send(const EasierTaken()),
            ),
            const SizedBox(height: 8),
            AuraButton(
              label: l.stillThinking,
              color: AuraButtonColor.blue,
              onPressed: vm.dismissStillThere,
            ),
          ],
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AuraColors.blue, width: 3),
      ),
      child: Text(text, style: AuraText.title.copyWith(fontSize: 30)),
    ),
  );
}
