import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/keypad.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';
import 'help_sheet.dart';

/// "I know it" and what follows it. Figma: S1, S2, J17.
class AnswerSheet extends StatefulWidget {
  const AnswerSheet({super.key, required this.vm});

  final LessonViewModel vm;

  @override
  State<AnswerSheet> createState() => _AnswerSheetState();
}

class _AnswerSheetState extends State<AnswerSheet> {
  String _typed = '';

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = widget.vm.problem;
    final askB = l.askB(p.b.name.toLowerCase());
    final (title, sub) = switch (widget.vm.knowPrompt!) {
      KnowPrompt.answer => (p.ask == Ask.total ? l.askTotal : askB, null),
      KnowPrompt.whatAsked => (l.whatAsked, p.text),
      KnowPrompt.recheck => (l.checkSumAgain, null),
      KnowPrompt.checkPart => (l.checkOnePart, askB),
      KnowPrompt.checkTotal => (l.partRight(p.b.name), l.nowCheckAdding),
    };
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.vm.closeKnowIt,
            child: const ColoredBox(color: AuraColors.scrim),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: AuraSheetBody(
            children: [
              Text(title, style: AuraText.title, textAlign: TextAlign.center),
              if (sub != null) ...[
                const SizedBox(height: 6),
                Text(sub, style: AuraText.body, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 120,
                      minHeight: 56,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AuraColors.blueTint,
                      borderRadius: BorderRadius.circular(AuraRadii.small),
                      border: Border.all(color: AuraColors.blue, width: 3),
                    ),
                    child: Text(
                      _typed,
                      style: AuraText.title.copyWith(fontSize: 30),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(p.unit, style: AuraText.title),
                ],
              ),
              const SizedBox(height: 12),
              Keypad(
                keyHeight: widget.vm.biggerPad ? 64 : 48,
                key: ValueKey(widget.vm.knowPrompt),
                onChanged: (v) => setState(() => _typed = v),
                onCheck: (v) => widget.vm.answer(int.parse(v)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
