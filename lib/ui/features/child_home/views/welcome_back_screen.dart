import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/ribbon.dart';
import 'play_icon_button.dart';
import 'play_moment.dart';

/// Back with a case left unfinished. Figma: WelcomeBack (651:133), plus the
/// home button v4.1 §16 asks for (SES-07).
class WelcomeBackScreen extends StatelessWidget {
  const WelcomeBackScreen({super.key, required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PlayMoment(
      top: Align(
        alignment: Alignment.centerLeft,
        child: PlayIconButton(
          icon: Icons.home_outlined,
          tooltip: l.kidHome,
          onPressed: () => context.go(Paths.home),
        ),
      ),
      content: [
        const Burst(child: Portrait(size: 180)),
        const SizedBox(height: 10),
        Ribbon(
          text: name == null ? l.kidWelcomeBackNoName : l.kidWelcomeBack(name!),
        ),
        PlayLine(l.kidCaseWaiting),
      ],
      bottom: AuraButton(
        label: l.kidLetsSee,
        onPressed: () => context.go(Paths.lessonNext),
      ),
    );
  }
}
