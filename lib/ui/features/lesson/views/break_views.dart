import 'package:auramath_engine/auramath_engine.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/motion/motion.dart';
import '../../../core/motion/play_backdrop.dart';
import '../../../core/parts/aura_button.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';
import 'help_sheet.dart';
import '../../../core/parts/speak_button.dart';

/// "Take a break?" when Home is tapped mid-lesson. Figma M1-pause (666:70),
/// plus "leave this one" (SES-06), which the design doesn't have yet.
class BreakSheet extends StatelessWidget {
  const BreakSheet({
    super.key,
    required this.onKeepGoing,
    required this.onGoHome,
    this.onLeave,
  });

  final VoidCallback onKeepGoing;
  final VoidCallback onGoHome;

  /// A new case now; this one comes back another day.
  final VoidCallback? onLeave;

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
        if (onLeave case final onLeave?) ...[
          const SizedBox(height: 10),
          AuraButton(
            label: l.leaveThisOne,
            color: AuraButtonColor.white,
            onPressed: onLeave,
          ),
        ],
      ],
    );
  }
}

/// "Try it again?" for the case the child left last time (SES-06). Not in
/// Figma yet.
class OfferLeftView extends StatelessWidget {
  const OfferLeftView({
    super.key,
    required this.problem,
    required this.onAgain,
    required this.onNew,
  });

  final ComparisonProblem problem;
  final VoidCallback onAgain;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PlayBackdrop(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Spacer(),
              Burst(
                child: Text(
                  problem.a.pic,
                  style: const TextStyle(fontSize: 96),
                ),
              ),
              const SizedBox(height: 24),
              Ribbon(text: l.leftWaitingTitle),
              const SizedBox(height: 16),
              Text(
                l.leftWaitingBody(problem.a.name.toLowerCase()),
                style: AuraText.play,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              AuraButton(label: l.leftTryAgain, onPressed: onAgain),
              const SizedBox(height: 10),
              AuraButton(
                label: l.leftSomethingNew,
                color: AuraButtonColor.white,
                onPressed: onNew,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The server ended the lesson (away too long, or its log is full). Not in
/// Figma: TU's calm layout, one way out, nothing lost.
class KeptForNextTimeView extends StatelessWidget {
  const KeptForNextTimeView({super.key, required this.onOk});

  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Moment(
      emoji: '🗂️',
      title: l.keptTitle,
      body: l.keptBody,
      onOk: onOk,
    );
  }
}

/// The server has no child to start a lesson for (409): a grown-up adds
/// one first. Not designed in Figma.
class NoChildYetView extends StatelessWidget {
  const NoChildYetView({super.key, required this.onOk});

  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Moment(
      emoji: '🧑‍🧒',
      title: l.lessonNoChildTitle,
      body: l.lessonNoChildBody,
      onOk: onOk,
    );
  }
}

/// A new session's 403: a grown-up withdrew consent (ACC-03), so lessons
/// are paused. The child is told kindly to ask; the reason is for the
/// grown-up area (no Figma frame yet).
class LessonsPausedView extends StatelessWidget {
  const LessonsPausedView({super.key, required this.onOk});

  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _Moment(
      emoji: '🧑‍🧒',
      title: l.lessonPausedTitle,
      body: l.lessonPausedBody,
      onOk: onOk,
    );
  }
}

class _Moment extends StatelessWidget {
  const _Moment({
    required this.emoji,
    required this.title,
    required this.body,
    required this.onOk,
  });

  final String emoji;
  final String title;
  final String body;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PlayBackdrop(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: SpeakButton(text: '$title $body'),
              ),
              const Spacer(),
              Burst(child: Text(emoji, style: const TextStyle(fontSize: 96))),
              const SizedBox(height: 24),
              Ribbon(text: title),
              const SizedBox(height: 16),
              Text(body, style: AuraText.play, textAlign: TextAlign.center),
              const Spacer(),
              AuraButton(label: l.ok, onPressed: onOk),
            ],
          ),
        ),
      ),
    );
  }
}

/// "That's today's time!" at the sitting's cap. Figma TU (650:118), plus the
/// "finish this one" choice SES-01 asks for, which the design doesn't have
/// yet. No clock or countdown anywhere (SES-02).
class TimeUpView extends StatelessWidget {
  const TimeUpView({super.key, required this.onStop, this.onFinish});

  final VoidCallback onStop;

  /// Null when the problem hadn't begun: nothing to finish.
  final VoidCallback? onFinish;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PlayBackdrop(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: SpeakButton(text: '${l.timeUpTitle} ${l.timeUpBody}'),
              ),
              const Spacer(),
              const Burst(child: Text('🌙', style: TextStyle(fontSize: 96))),
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
              if (onFinish case final onFinish?) ...[
                const SizedBox(height: 10),
                AuraButton(
                  label: l.finishThisOne,
                  color: AuraButtonColor.white,
                  onPressed: onFinish,
                ),
              ],
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
      say: '${l.lessonNeedInternet} ${detail ?? l.lessonNeedInternetBody}',
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Float(
            child: Icon(
              Icons.wifi_off_rounded,
              size: 72,
              color: AuraColors.white,
            ),
          ),
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
