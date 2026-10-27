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
      color: AuraColors.yellow,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AuraColors.navy, width: 3),
      boxShadow: const [
        BoxShadow(color: AuraColors.navy, offset: Offset(0, 5)),
      ],
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: AuraText.title.copyWith(color: AuraColors.yellowFg),
    ),
  );
}

/// A child's round portrait. Figma: Prototype parts › Avatar.
class Portrait extends StatelessWidget {
  const Portrait({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AuraColors.navy, width: 4),
      image: const DecorationImage(
        image: AssetImage('assets/images/detective_boy.jpg'),
        fit: BoxFit.cover,
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
