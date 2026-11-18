import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/ribbon.dart';
import 'play_icon_button.dart';
import 'play_moment.dart';

/// Back on a later day, or with a case left unfinished (SES-07). The last
/// case is offered first (carry on); with Quick sums on, the second
/// choice is today's work (Choose today, LES-14). Figma: WelcomeBack
/// (651:133, journey 25.1 to 25.3), plus the home button v4.1 §16 asks for.
class WelcomeBackScreen extends StatelessWidget {
  const WelcomeBackScreen({
    super.key,
    required this.name,
    this.caseWaiting = true,
    this.chooseToday = false,
    this.onCarryOn,
    this.figure,
  });

  /// The child's tutor, talking (the prototype's WelcomeBack); without one
  /// the detective portrait bursts in.
  final Widget? figure;

  /// "Let's see" / "Keep going" inside a lesson that greets from the
  /// server's `welcomeBack`; null: to the lesson.
  final VoidCallback? onCarryOn;

  final String? name;

  /// A case is waiting: Let's see carries it on.
  final bool caseWaiting;

  /// Choose today's work is offered too (the flag `quick_sums`).
  final bool chooseToday;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final line = caseWaiting ? l.kidCaseWaiting : l.kidReadyForACase;
    return PlayMoment(
      // the name is on screen only: nothing spoken says it (TTR-02, NFR-08)
      say: '${l.kidWelcomeBackNoName} $line',
      top: Align(
        alignment: Alignment.centerRight,
        child: PlayIconButton(
          icon: Icons.home_rounded,
          tooltip: l.kidHome,
          onPressed: () => context.go(Paths.home),
        ),
      ),
      content: [
        figure ?? const Burst(child: Portrait(size: 180)),
        Ribbon(
          text: name == null ? l.kidWelcomeBackNoName : l.kidWelcomeBack(name!),
        ),
        PlayLine(line),
      ],
      bottom: ButtonStack([
        AuraButton(
          key: const Key('carryOn'),
          label: caseWaiting ? l.kidLetsSee : l.kidLetsGo,
          onPressed: onCarryOn ?? () => context.go(Paths.lessonNext),
        ),
        if (chooseToday)
          AuraButton(
            key: const Key('chooseToday'),
            label: l.kidWelcomeChooseToday,
            color: AuraButtonColor.white,
            onPressed: () => context.go(Paths.chooseToday),
          ),
      ]),
    );
  }
}
