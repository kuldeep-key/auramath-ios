import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';
import 'help_sheet.dart';

/// "Take a break?" when Home is tapped mid-lesson. Figma M1-pause (666:70).
class BreakSheet extends StatelessWidget {
  const BreakSheet({
    super.key,
    required this.onKeepGoing,
    required this.onGoHome,
  });

  final VoidCallback onKeepGoing;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraSheet(
      onClose: onKeepGoing,
      children: [
        const Portrait(size: 88),
        const SizedBox(height: 12),
        Text(l.takeABreak, style: AuraText.title, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          l.drawingSaved,
          style: AuraText.body.copyWith(color: AuraColors.mute),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        AuraButton(
          label: l.keepGoing,
          color: AuraButtonColor.blue,
          onPressed: onKeepGoing,
        ),
        const SizedBox(height: 10),
        AuraButton(
          label: l.goHome,
          color: AuraButtonColor.white,
          icon: Icons.home_outlined,
          onPressed: onGoHome,
        ),
      ],
    );
  }
}

/// "That's today's time!" at the sitting's cap. Figma TU (650:118), plus the
/// "finish this one" choice SES-01 asks for, which the design doesn't have
/// yet. No clock or countdown anywhere (SES-02).
class TimeUpView extends StatelessWidget {
  const TimeUpView({super.key, required this.onStop, required this.onFinish});

  final VoidCallback onStop;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      decoration: auraPlayBackground,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Spacer(),
              const Text('🌙', style: TextStyle(fontSize: 96)),
              const SizedBox(height: 24),
              Ribbon(text: l.timeUpTitle),
              const SizedBox(height: 16),
              Text(
                l.timeUpBody,
                style: AuraText.body.copyWith(
                  color: AuraColors.white,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AuraButton(label: l.ok, onPressed: onStop),
              const SizedBox(height: 10),
              AuraButton(
                label: l.finishThisOne,
                color: AuraButtonColor.white,
                onPressed: onFinish,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
