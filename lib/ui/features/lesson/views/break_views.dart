import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
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
        Text(
          l.takeABreak,
          style: AuraText.sheetTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l.drawingSaved,
          style: AuraText.sheetLine,
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
                style: AuraText.play,
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

/// Online-first (SES-04 as changed): the connection dropped, so the lesson
/// pauses here; every tap so far is held and resent, and the lesson carries
/// on from the same spot. Not designed in Figma yet: calm, never red
/// (NFR-03), an icon plus words, not colour alone.
class LostInternetPause extends StatelessWidget {
  const LostInternetPause({
    super.key,
    required this.onRetry,
    required this.onGoHome,
  });

  final VoidCallback onRetry;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      child: AuraSheet(
        onClose: onRetry,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 56,
            color: AuraColors.yellowInk,
          ),
          const SizedBox(height: 12),
          Text(
            l.lostInternet,
            style: AuraText.sheetTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l.lessonLostInternetBody,
            style: AuraText.sheetLine,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AuraButton(
            label: l.lessonTryAgain,
            color: AuraButtonColor.blue,
            onPressed: onRetry,
          ),
          const SizedBox(height: 10),
          AuraButton(
            label: l.goHome,
            color: AuraButtonColor.white,
            icon: Icons.home_outlined,
            onPressed: onGoHome,
          ),
        ],
      ),
    );
  }
}

/// The lesson couldn't start: no connection (online-first). Not designed in
/// Figma yet. [detail] is the server's own message when it answered.
class NeedInternetView extends StatelessWidget {
  const NeedInternetView({
    super.key,
    required this.onRetry,
    required this.onGoHome,
    this.detail,
  });

  final VoidCallback onRetry;
  final VoidCallback onGoHome;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuraPage(
      play: true,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 72, color: AuraColors.white),
          const SizedBox(height: 20),
          Ribbon(text: l.lessonNeedInternet),
          const SizedBox(height: 16),
          Text(
            detail ?? l.lessonNeedInternetBody,
            textAlign: TextAlign.center,
            style: AuraText.play,
          ),
        ],
      ),
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuraButton(label: l.lessonTryAgain, onPressed: onRetry),
          const SizedBox(height: 10),
          AuraButton(
            label: l.goHome,
            color: AuraButtonColor.white,
            icon: Icons.home_outlined,
            onPressed: onGoHome,
          ),
        ],
      ),
    );
  }
}
