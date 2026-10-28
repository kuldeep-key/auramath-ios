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

/// SES-04's gentle notice while the server can't be reached. Not designed in
/// Figma yet: a calm strip, never red (NFR-03), and the lesson carries on.
class LostInternetNotice extends StatelessWidget {
  const LostInternetNotice({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AuraColors.yellowTint,
        borderRadius: BorderRadius.circular(AuraRadii.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, color: AuraColors.yellowInk),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              AppLocalizations.of(context)!.lostInternet,
              style: AuraText.body.copyWith(color: AuraColors.yellowInk),
            ),
          ),
        ],
      ),
    ),
  );
}
