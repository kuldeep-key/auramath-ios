import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_card.dart';
import '../../../core/parts/lesson_header.dart';
import '../../../core/parts/standing_button.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';
import 'answer_sheet.dart';
import 'help_sheet.dart';
import 'question_overlay.dart';
import 'word_meaning.dart';

/// The question, big and alone, read aloud first. Figma: M0.
class QuestionView extends StatefulWidget {
  const QuestionView({super.key, required this.vm, required this.onHome});

  final LessonViewModel vm;
  final VoidCallback onHome;

  @override
  State<QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<QuestionView> {
  bool _helpOpen = false;

  /// Help from the question: the board opens, then the help chosen.
  Future<void> _help(LessonInput input) async {
    setState(() => _helpOpen = false);
    await widget.vm.send(const Started());
    await widget.vm.send(input);
  }

  @override
  void initState() {
    super.initState();
    widget.vm.autoReadQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = widget.vm.problem;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LessonHeader(
                big: widget.vm.voice.resting.value,
                line: l.todaysCase,
                onSpeak: widget.vm.readQuestion,
                speaking: widget.vm.voice.speaking,
                muted: !widget.vm.readAloud,
                onSound: widget.vm.sound,
                onHome: widget.onHome,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AuraCard(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Text(
                            '${p.a.pic}  ${p.b.pic}',
                            style: const TextStyle(fontSize: 64),
                          ),
                          const SizedBox(height: 12),
                          Text.rich(
                            storySpan(
                              p,
                              words: widget.vm.wordMeanings
                                  ? wordsIn(p)
                                  : const [],
                            ),
                            style: AuraText.story,
                            textAlign: TextAlign.left,
                          ),
                          if (widget.vm.wordMeanings) ...[
                            const SizedBox(height: 16),
                            WordButtons(vm: widget.vm),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // I know it and Help me from the first screen (LES-01, Julia's
              // J41); DRAFT layout for Apoorv: Figma M0 has only Got it
              Row(
                children: [
                  Expanded(
                    child: StandingButton(
                      key: const Key('m0KnowIt'),
                      icon: Icons.lightbulb_rounded,
                      iconColor: AuraColors.yellowInk,
                      label: l.iKnowIt,
                      onPressed: widget.vm.openKnowIt,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StandingButton(
                      key: const Key('m0HelpMe'),
                      icon: Icons.support_rounded,
                      label: l.helpMe,
                      onPressed: () => setState(() => _helpOpen = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AuraButton(
                label: l.gotItLetsDraw,
                color: AuraButtonColor.blue,
                onPressed: () => widget.vm.send(const Started()),
              ),
              const SizedBox(height: 12),
              AuraButton(
                label: l.hearItAgain,
                color: AuraButtonColor.white,
                icon: Icons.volume_up_rounded,
                onPressed: widget.vm.readQuestion,
              ),
            ],
          ),
        ),
        if (_helpOpen)
          HelpSheet(
            onClose: () => setState(() => _helpOpen = false),
            onChoose: _help,
          ),
        if (widget.vm.knowPrompt != null) AnswerSheet(vm: widget.vm),
      ],
    );
  }
}
