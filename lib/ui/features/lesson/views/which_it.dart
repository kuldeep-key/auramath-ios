import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/theme/tokens.dart';
import '../view_models/lesson_view_model.dart';

/// The question split where "it" and the thing it means are, so both can
/// be drawn in one colour (TUT-16 H1-4b). Each part says whether it is
/// one of them.
List<(String, bool)> itParts(String text, String aName) {
  final words = RegExp(
    '\\b(it|${RegExp.escape(aName)})\\b',
    caseSensitive: false,
  );
  final out = <(String, bool)>[];
  var at = 0;
  for (final m in words.allMatches(text)) {
    if (m.start > at) out.add((text.substring(at, m.start), false));
    out.add((m[0]!, true));
    at = m.end;
  }
  if (at < text.length) out.add((text.substring(at), false));
  return out;
}

/// "Which tree does 'it' mean?" (TUT-16): the question, and a pick between
/// the two things it names. On H1-4b "it" and the thing it means share a
/// colour and an underline, so colour is not the only signal.
///
/// DRAFT for Design: Figma has no H1-4a or H1-4b screen yet ("TBD
/// (Apoorv)"). This is a card over the board's buttons, as the quiet
/// child's sheet is.
class WhichItCard extends StatelessWidget {
  const WhichItCard({super.key, required this.vm});

  final LessonViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = vm.problem;
    final a = p.a.name.toLowerCase(), b = p.b.name.toLowerCase();
    const lit = TextStyle(
      color: AuraColors.blueInk,
      fontWeight: FontWeight.w900,
      decoration: TextDecoration.underline,
      decorationColor: AuraColors.blueInk,
      decorationThickness: 2,
    );
    return Entrance(
      duration: const Duration(milliseconds: 420),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 60 * (1 - AuraCurves.sheet.transform(t))),
          child: child,
        ),
      ),
      child: Material(
        key: const Key('whichIt'),
        color: AuraColors.white,
        elevation: 6,
        borderRadius: BorderRadius.circular(AuraRadii.card),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: vm.highlightIt ? l.lessonItHighlighted(a) : null,
                child: Text.rich(
                  key: const Key('whichItQuestion'),
                  TextSpan(
                    children: [
                      for (final (part, isIt)
                          in vm.highlightIt
                              ? itParts(p.text, a)
                              : [(p.text, false)])
                        TextSpan(text: part, style: isIt ? lit : null),
                    ],
                  ),
                  style: AuraText.body,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final (option, name) in [('a', a), ('b', b)]) ...[
                    if (option == 'b') const SizedBox(width: 10),
                    Expanded(
                      child: AuraButton(
                        label: l.lessonItIs(name),
                        color: AuraButtonColor.white,
                        onPressed: () => vm.pickIt(option),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
