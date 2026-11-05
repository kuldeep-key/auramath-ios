import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../routing/paths.dart';
import '../../../core/motion/confetti.dart';
import '../../../core/motion/motion.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import '../setup_paths.dart';
import 'setup_parts.dart';

/// Ready (644:2): the child is saved; hand this phone over, or join theirs.
class ReadyScreen extends StatelessWidget {
  const ReadyScreen({super.key, required this.childId, required this.name});

  final String childId;
  final String name;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Stack(
      children: [
        AuraPage(
          top: const SizedBox(
            height: 48,
            child: Center(child: AuraProgress(value: 1)),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Burst(child: KidAvatar(size: 150, asset: kidBoy)),
              const SizedBox(height: 50),
              Semantics(
                header: true,
                child: Text(l.setupReadyTitle, style: AuraText.heading),
              ),
              const SizedBox(height: 22),
              Text(
                l.setupReadyBody(name),
                textAlign: TextAlign.center,
                style: AuraText.subtitle,
              ),
              const SizedBox(height: 12),
              // ACC-06; wording to agree with Julia (not in Figma)
              Text(
                l.setupReadyNoHelp(name),
                textAlign: TextAlign.center,
                style: AuraText.cardLine,
              ),
              const SizedBox(height: 16),
            ],
          ),
          bottom: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuraButton(
                label: l.setupHandOver(name),
                color: AuraButtonColor.blue,
                onPressed: () => context.push(
                  SetupPaths.withChild(
                    Paths.setupLock,
                    id: childId,
                    name: name,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AuraButton(
                label: l.setupOwnPhone(name),
                color: AuraButtonColor.white,
                onPressed: () => context.push(
                  SetupPaths.withChild(
                    Paths.setupJoinCode,
                    id: childId,
                    name: name,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Positioned.fill(child: Confetti(count: 60)),
      ],
    );
  }
}
