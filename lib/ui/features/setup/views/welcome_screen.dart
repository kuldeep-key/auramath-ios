import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import 'setup_parts.dart';

/// Welcome (643:2). "Try a free check first" is left out: the free check
/// isn't built this term.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      top: const AuraTopBar(fallback: Paths.open),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              KidAvatar(size: 130, asset: kidBoy),
              KidAvatar(size: 100, asset: kidGirl),
            ],
          ),
          const SizedBox(height: 50),
          Semantics(
            header: true,
            child: Text(
              l.setupWelcomeTitle,
              textAlign: TextAlign.center,
              style: AuraText.heading.copyWith(fontSize: 34),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            l.setupWelcomeBody,
            textAlign: TextAlign.center,
            style: AuraText.body.copyWith(color: AuraColors.mute, height: 1.4),
          ),
          const SizedBox(height: 16),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraButton(
            label: l.setupGetStarted,
            color: AuraButtonColor.blue,
            onPressed: () => context.push(Paths.setupName),
          ),
          const SizedBox(height: 12),
          AuraLink(
            label: l.setupHaveAccount,
            onPressed: () => context.push(Paths.signIn),
          ),
        ],
      ),
    );
  }
}
