import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_card.dart';
import '../../../core/parts/lesson_header.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';
import 'question_overlay.dart';

/// The question, big and alone, read aloud first. Figma: M0.
class QuestionView extends StatefulWidget {
  const QuestionView({super.key, required this.vm, required this.onHome});

  final LessonViewModel vm;
  final VoidCallback onHome;

  @override
  State<QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<QuestionView> {
  @override
  void initState() {
    super.initState();
    widget.vm.autoReadQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = widget.vm.problem;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LessonHeader(
            big: widget.vm.voice.resting.value,
            line: l.todaysCase,
            onSpeak: widget.vm.readQuestion,
            speaking: widget.vm.voice.speaking,
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
                        storySpan(p),
                        style: AuraText.story,
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
    );
  }
}
