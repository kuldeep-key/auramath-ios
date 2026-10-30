import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../theme/tokens.dart';
import 'ribbon.dart' show auraPlayBackground;

/// The frame every screen outside the lesson board sits in.
///
/// - Content is centred and capped at [maxWidth], so an iPad or a large
///   phone shows the same column as the 390-wide Figma frame.
/// - [body] fills the space between [top] and [bottom]; when it is taller
///   (small phones, large text) it scrolls and [bottom] stays put.
/// - [bottom] (the main buttons) rises above the keyboard.
/// - [play] is the child's blue background; otherwise the grown-ups' white.
class AuraPage extends StatelessWidget {
  const AuraPage({
    super.key,
    this.top,
    required this.body,
    this.bottom,
    this.play = false,
    this.maxWidth = 560,
  });

  final Widget? top;
  final Widget body;
  final Widget? bottom;
  final bool play;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    // white clock and battery on the blue play background
    value: play ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    child: _scaffold(),
  );

  Widget _scaffold() => Scaffold(
    backgroundColor: play ? AuraColors.blueLip : AuraColors.white,
    body: DecoratedBox(
      decoration: play
          ? auraPlayBackground
          : const BoxDecoration(color: AuraColors.white),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ?top,
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverFillRemaining(hasScrollBody: false, child: body),
                      ],
                    ),
                  ),
                  if (bottom != null) ...[const SizedBox(height: 12), bottom!],
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Back (or close) on the left, an optional progress bar, an optional
/// action on the right. Figma: Prototype parts › Top bar (686:96, 686:102).
class AuraTopBar extends StatelessWidget {
  const AuraTopBar({
    super.key,
    this.progress,
    this.close = false,
    this.trailing,
    this.onBack,
    this.fallback,
    this.light = false,
  });

  /// 0..1; null hides the bar.
  final double? progress;

  /// An ✕ instead of ←.
  final bool close;
  final Widget? trailing;

  /// Overrides the default: pop, or go to [fallback] when nothing is
  /// underneath (a deep link, or a screen reached with `go`).
  final VoidCallback? onBack;
  final String? fallback;

  /// White icons, for the blue play background.
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? AuraColors.white : AuraColors.ink;
    final canLeave = onBack != null || context.canPop() || fallback != null;
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          if (canLeave)
            // the arrow sits on the 16 pt margin, the tap area spills left
            IconButton(
              // a full 48 pt target; the arrow sits at its left edge
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              tooltip: close
                  ? MaterialLocalizations.of(context).closeButtonTooltip
                  : MaterialLocalizations.of(context).backButtonTooltip,
              icon: Icon(
                close ? Icons.close_rounded : Icons.arrow_back_rounded,
                color: color,
              ),
              onPressed:
                  onBack ??
                  () =>
                      context.canPop() ? context.pop() : context.go(fallback!),
            )
          else
            const SizedBox(width: 48),
          if (progress != null) ...[
            const SizedBox(width: 4),
            Expanded(child: AuraProgress(value: progress!)),
            const SizedBox(width: 8),
          ] else
            const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

/// The setup progress bar. Figma: Prototype parts › Progress (684:45).
class AuraProgress extends StatelessWidget {
  const AuraProgress({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => Semantics(
    value: '${(value * 100).round()}%',
    child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 8,
        backgroundColor: AuraColors.track,
        color: AuraColors.blue,
      ),
    ),
  );
}

/// Screen title and the line under it.
class AuraHeading extends StatelessWidget {
  const AuraHeading({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(header: true, child: Text(title, style: AuraText.heading)),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: AuraText.subtitle),
        ],
      ],
    ),
  );
}

/// A blue text link ("I already have an account", "Learn more").
class AuraLink extends StatelessWidget {
  const AuraLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.light = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool light;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: light
          ? AuraText.link.copyWith(color: AuraColors.linkOnBlue)
          : AuraText.link,
    ),
  );
}
