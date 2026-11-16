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
              const Burst(child: KidAvatar(size: 140, asset: kidBoy)),
              const SizedBox(height: 12),
              Semantics(
                header: true,
                child: Text(
                  l.setupReadyTitle(name),
                  textAlign: TextAlign.center,
                  style: AuraText.heading,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.setupReadyBody(name),
                textAlign: TextAlign.center,
                style: AuraText.subtitle,
              ),
              const SizedBox(height: 12),
              // ACC-06 (no help with the sums) and AI-07 (meet the case
              // partner together), as the prototype's Ready
              InfoCard(
                rows: [
                  (
                    Icons.front_hand_rounded,
                    l.setupReadyNoHelp,
                    l.setupReadyNoHelpDetail(name),
                  ),
                  (
                    Icons.smart_toy_rounded,
                    l.setupReadyMeet,
                    l.setupReadyMeetDetail(name),
                  ),
                ],
              ),
              const SizedBox(height: 4),
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
