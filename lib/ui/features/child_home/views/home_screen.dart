import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/ribbon.dart';

/// The child's home: their detective and the next case. Figma: Home
/// (649:2). My trail and My badges arrive with the child-home plan.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onKeepGoing});

  final VoidCallback onKeepGoing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      body: DecoratedBox(
        decoration: auraPlayBackground,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Spacer(),
                const Portrait(size: 210),
                const SizedBox(height: 32),
                Ribbon(text: l.readyForNewCase),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: AuraButton(
                    label: l.keepGoing,
                    icon: Icons.play_arrow_rounded,
                    onPressed: onKeepGoing,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
