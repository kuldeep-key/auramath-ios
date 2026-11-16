import 'dart:async';

import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/motion.dart';
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

/// The question, big and alone, read aloud first. Figma: M0; the
/// prototype's introDef: the card pops in (500 ms), the two pictures float
/// (3 s, the second 0.5 s behind), and as the story is read each word lights
/// in turn (330 ms a word, from 200 ms; 450 ms after the screen opens).
class QuestionView extends StatefulWidget {
  const QuestionView({super.key, required this.vm, required this.onHome});

  final LessonViewModel vm;
  final VoidCallback onHome;

  @override
  State<QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<QuestionView>
    with SingleTickerProviderStateMixin {
  bool _helpOpen = false;

  /// The read-along: one run through the story's words.
  late final AnimationController _read;
  Timer? _readSoon;
  int? _lit;

  static const _perWord = 330, _lead = 200;

  void _readAlong() {
    // calm motion reads the words whole, with nothing lighting up
    if (!mounted || calmMotion(context)) return;
    final n = storyWords(widget.vm.problem, words: _words);
    _read
      ..duration = Duration(milliseconds: n * _perWord + 700)
      ..forward(from: 0);
  }

  void _tick() {
    final ms = _read.value * _read.duration!.inMilliseconds;
    final n = storyWords(widget.vm.problem, words: _words);
    final i = ((ms - _lead) / _perWord).floor();
    final lit = _read.isCompleted || i < 0 || i >= n ? null : i;
    if (lit != _lit) setState(() => _lit = lit);
  }

  void _hear() {
    widget.vm.readQuestion();
    _readAlong();
  }

  List<String> get _words =>
      widget.vm.wordMeanings ? wordsIn(widget.vm.problem) : const [];

  /// Help from the question: the board opens, then the help chosen.
  Future<void> _help(LessonInput input) async {
    setState(() => _helpOpen = false);
    await widget.vm.send(const Started());
    await widget.vm.send(input);
  }

  @override
  void initState() {
    super.initState();
    _read = AnimationController(vsync: this)..addListener(_tick);
    widget.vm.autoReadQuestion();
    if (widget.vm.readAloud && widget.vm.readQuestionAloud) {
      _readSoon = Timer(const Duration(milliseconds: 450), _readAlong);
    }
  }

  @override
  void dispose() {
    _readSoon?.cancel();
    _read.dispose();
    super.dispose();
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
                onHome: widget.onHome,
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Pop(
                  duration: const Duration(milliseconds: 500),
                  child: AuraCard(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 28,
                              children: [
                                _Floating(child: _pic(p.a.pic)),
                                _Floating(
                                  delay: const Duration(milliseconds: 500),
                                  child: _pic(p.b.pic),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text.rich(
                              storySpan(p, words: _words, lit: _lit),
                              key: const Key('story'),
                              style: AuraText.story,
                              textAlign: TextAlign.left,
                            ),
                            if (widget.vm.wordMeanings) ...[
                              const SizedBox(height: 16),
                              WordButtons(vm: widget.vm),
                            ],
                            const SizedBox(height: 18),
                            // the prototype's small white "Hear it again"
                            SmallWhiteButton(
                              key: const Key('hearItAgain'),
                              label: l.hearItAgain,
                              icon: Icons.volume_up_rounded,
                              onPressed: _hear,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // I know it and Help me from the first screen (LES-01, Julia's
              // J41)
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
              const SizedBox(height: 10),
              AuraButton(
                label: l.gotItLetsDraw,
                color: AuraButtonColor.blue,
                onPressed: () => widget.vm.send(const Started()),
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

Widget _pic(String pic) => ExcludeSemantics(
  child: Text(pic, style: const TextStyle(fontSize: 72, height: 1.1)),
);

/// The prototype's `.float`: up 8 and back, 3 s, for ever (still when
/// motion is calm).
class _Floating extends StatelessWidget {
  const _Floating({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) => Loop(
    period: const Duration(seconds: 3),
    delay: delay,
    builder: (context, t, child) =>
        Transform.translate(offset: Offset(0, -8 * halfway(t)), child: child),
    child: child,
  );
}

/// The prototype's `.btn.white.s`: a small white button, sized to its
/// words, with a navy edge and lip; 56 pt tall for a child (NFR-02).
class SmallWhiteButton extends StatelessWidget {
  const SmallWhiteButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: GestureDetector(
      onTap: () {
        AuraHaptics.tap();
        onPressed();
      },
      child: PressScale(
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: AuraColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AuraColors.navy, width: 3),
            boxShadow: const [
              BoxShadow(color: AuraColors.navy, offset: Offset(0, 6)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              if (icon case final i?) Icon(i, color: AuraColors.navy),
              Flexible(
                child: Text(
                  label,
                  style: AuraText.standing.copyWith(
                    fontSize: 18,
                    color: AuraColors.navy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
