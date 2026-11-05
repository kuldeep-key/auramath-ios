import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/keypad.dart';
import '../../../core/parts/lesson_header.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';

/// The starting check (SKL-07): before a new child's first case, four
/// warm-up sums for their age, typed on the number pad. Calm: no clock, no
/// score, nothing says right or wrong; each answer just moves on. (no Figma
/// frame yet)
class StartingCheckView extends StatefulWidget {
  const StartingCheckView({super.key, required this.vm, required this.onHome});

  final LessonViewModel vm;
  final VoidCallback onHome;

  @override
  State<StartingCheckView> createState() => _StartingCheckViewState();
}

class _StartingCheckViewState extends State<StartingCheckView> {
  /// Digits typed so far.
  String _typed = '';

  String get _sum => widget.vm.startingSums[widget.vm.startingAt].text;

  String _line(AppLocalizations l) =>
      widget.vm.startingAt == 0 ? l.lessonWarmUpStart : l.lessonWarmUpNext;

  /// The line, then the sum with its ? said as a word.
  String _spoken(AppLocalizations l) =>
      '${_line(l)} ${_sum.replaceAll('?', l.lessonWarmUpBlank)}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.vm.autoSay(
      _spoken(AppLocalizations.of(context)!),
      target: 'question',
    );
  }

  Future<void> _typedIn(String digits) async {
    final value = int.tryParse(digits);
    setState(() => _typed = '');
    if (value == null) return;
    final vm = widget.vm;
    await vm.answerStarting(value);
    if (mounted && vm.inStartingCheck) {
      vm.autoSay(_spoken(AppLocalizations.of(context)!), target: 'question');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final vm = widget.vm;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LessonHeader(
            big: vm.voice.resting.value,
            line: _line(l),
            onSpeak: () => vm.say(_spoken(l), target: 'question'),
            speaking: vm.voice.speaking,
            onHome: widget.onHome,
          ),
          const Spacer(),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: AuraColors.navy,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _sum,
                style: AuraText.title.copyWith(
                  color: AuraColors.white,
                  fontSize: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _typed.isEmpty ? '?' : _typed,
            textAlign: TextAlign.center,
            style: AuraText.title.copyWith(fontSize: 30),
          ),
          const Spacer(),
          Keypad(
            // a fresh pad for each sum
            key: ValueKey(vm.startingAt),
            keyHeight: vm.biggerPad ? 64 : 56,
            onChanged: (s) => setState(() => _typed = s),
            onCheck: _typedIn,
          ),
        ],
      ),
    );
  }
}
