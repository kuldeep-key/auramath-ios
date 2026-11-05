import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// The yellow label ribbon ("Case cracked!", "Ready for a new case?").
/// Figma: Prototype parts › Ribbon.
class Ribbon extends StatelessWidget {
  const Ribbon({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
    decoration: BoxDecoration(
      // Figma: a gloss from light yellow, radius 12
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(AuraColors.yellow, AuraColors.white, 0.3)!,
          AuraColors.yellow,
        ],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AuraColors.navy, width: 3),
      boxShadow: const [
        BoxShadow(color: AuraColors.navy, offset: Offset(0, 5)),
      ],
    ),
    child: Text(text, textAlign: TextAlign.center, style: AuraText.ribbon),
  );
}

/// A child's round portrait. Figma: Prototype parts › Avatar.
class Portrait extends StatelessWidget {
  const Portrait({
    super.key,
    required this.size,
    this.image = 'assets/images/detective_boy.jpg',
  });

  final double size;

  /// The detective's picture (an asset path).
  final String image;

  // Centred so a stretching parent (a sheet's column) can't widen it into a
  // strip that crops the face.
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AuraColors.navy, width: 4),
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
      ),
    ),
  );
}

/// The blue play background of the child's celebration and home screens.
const auraPlayBackground = BoxDecoration(
  gradient: RadialGradient(
    center: Alignment(0, -0.3),
    radius: 1.1,
    colors: [AuraColors.blue, AuraColors.blueLip],
  ),
);
