import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/ribbon.dart';
import 'play_moment.dart';

/// Back with a case left unfinished. Figma: WelcomeBack (651:133).
class WelcomeBackScreen extends StatelessWidget {
  const WelcomeBackScreen({super.key, required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PlayMoment(
      content: [
        const Portrait(size: 180),
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
