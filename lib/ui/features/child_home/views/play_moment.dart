import 'package:flutter/material.dart';

import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';

/// The child's blue screens that say one thing: art, a ribbon and a line,
/// centred, with the buttons pinned below (WelcomeBack, Check, Streak, Up,
/// TrailTop, B2).
class PlayMoment extends StatelessWidget {
  const PlayMoment({
    super.key,
    required this.content,
    required this.bottom,
    this.top,
    this.gap = 18,
  });

  final List<Widget> content;
  final Widget bottom;
  final Widget? top;
  final double gap;

  @override
  Widget build(BuildContext context) => AuraPage(
    play: true,
    top: top,
    body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: gap,
      children: content,
    ),
    bottom: bottom,
  );
}

/// The white line under a ribbon on a blue screen.
class PlayLine extends StatelessWidget {
  const PlayLine(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: AuraText.play.copyWith(color: AuraColors.white),
  );
}

/// Buttons stacked 12 apart, full width.
class ButtonStack extends StatelessWidget {
  const ButtonStack(this.buttons, {super.key});

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: buttons,
  );
}

/// An emoji standing in for art Figma hasn't drawn yet; hidden from screen
/// readers, the words next to it carry the meaning.
class Art extends StatelessWidget {
  const Art(this.emoji, {super.key, required this.size});

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Text(emoji, style: TextStyle(fontSize: size, height: 1.2)),
  );
}
