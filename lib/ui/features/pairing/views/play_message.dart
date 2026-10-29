import 'package:flutter/material.dart';

import '../../../../data/services/api.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/parts/ribbon.dart';
import '../../../core/theme/tokens.dart';

/// The blue play screen that says one thing: a picture, a ribbon, a line
/// under it, and the buttons at the bottom. CodeWrong, IsThisYou,
/// PhoneJoined, OtherPhone and the child's Removed share it.
class PlayMessage extends StatelessWidget {
  const PlayMessage({
    super.key,
    required this.art,
    required this.title,
    this.line,
    this.lineStyle,
    required this.buttons,
  });

  /// A large emoji or the child's portrait.
  final Widget art;
  final String title;
  final String? line;

  /// Defaults to the 20 pt white line under the ribbon.
  final TextStyle? lineStyle;
  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) => AuraPage(
    play: true,
    body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        art,
        const SizedBox(height: 28),
        Ribbon(text: title),
        if (line != null) ...[
          const SizedBox(height: 18),
          Text(
            line!,
            textAlign: TextAlign.center,
            style:
                lineStyle ?? AuraText.bubble.copyWith(color: AuraColors.white),
          ),
        ],
      ],
    ),
    bottom: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, b) in buttons.indexed) ...[
          if (i > 0) const SizedBox(height: 12),
          b,
        ],
      ],
    ),
  );
}

/// A big emoji as a picture: decorative, so screen readers skip it.
class EmojiArt extends StatelessWidget {
  const EmojiArt(this.emoji, {super.key, this.size = 90});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Text(emoji, style: TextStyle(fontSize: size)),
  );
}

/// What to say about a failed call: offline, or the server's own message.
String failureText(AppLocalizations l, Object error) => switch (error) {
  ApiException(offline: true) => l.pairOffline,
  ApiException(:final message) => l.pairFailed(message),
  _ => l.pairFailed('$error'),
};

/// A failed load or call: what went wrong and a way to try again.
class LoadError extends StatelessWidget {
  const LoadError({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.light = false,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  /// White text, for the blue play background.
  final bool light;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(
        liveRegion: true,
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AuraText.body.copyWith(
            color: light ? AuraColors.white : AuraColors.ink,
          ),
        ),
      ),
      AuraLink(label: retryLabel, onPressed: onRetry, light: light),
    ],
  );
}
