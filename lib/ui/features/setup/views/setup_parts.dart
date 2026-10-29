import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show toBeginningOfSentenceCase;

import '../../../../l10n/app_localizations.dart';
import '../../../core/parts/aura_card.dart';
import '../../../core/parts/aura_page.dart';
import '../../../core/theme/tokens.dart';
import '../../../../routing/paths.dart';

/// Setup's steps, for the progress bar (Figma 686:102): Name … SavePlace,
/// and Ready full.
abstract final class SetupStep {
  static const name = 1 / 8;
  static const age = 2 / 8;
  static const year = 3 / 8;
  static const start = 4 / 8;
  static const notSure = 4.5 / 8;
  static const goal = 5 / 8;
  static const data = 6 / 8;
  static const save = 7 / 8;
}

/// The back arrow and the setup progress bar.
AuraTopBar setupTopBar(double progress) =>
    AuraTopBar(progress: progress, fallback: Paths.welcome);

/// [CodeBoxes] measures itself with a LayoutBuilder, which can't answer
/// the intrinsic height [AuraPage]'s body asks for: a fixed height (its
/// tallest boxes, 52 × 1.15) answers instead.
const codeBoxesHeight = 60.0;

/// The child's typed name, or "your child" when setup was entered sideways.
String childName(BuildContext context, String? name) =>
    name ?? AppLocalizations.of(context)!.setupYourChild;

/// A title that may start with "your child": capitalised.
String sentence(String s) => toBeginningOfSentenceCase(s);

/// A failure, shown where the grown-up is looking, with an icon so colour
/// is never the only signal.
class ErrorNote extends StatelessWidget {
  const ErrorNote(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: AuraColors.blueInk),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: AuraText.body)),
        ],
      ),
    ),
  );
}

/// A round portrait on the yellow glow. Figma: Prototype parts › Avatar.
class KidAvatar extends StatelessWidget {
  const KidAvatar({super.key, required this.size, required this.asset});

  final double size;
  final String asset;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AuraColors.navy, width: 4),
      gradient: const RadialGradient(
        center: Alignment(0, -0.2),
        colors: [AuraColors.flag, AuraColors.yellow],
      ),
      image: DecorationImage(image: AssetImage(asset), fit: BoxFit.cover),
    ),
  );
}

const kidBoy = 'assets/images/kid0.jpg';
const kidGirl = 'assets/images/kid3.jpg';

/// One line of an [InfoCard]: an icon tile, a title and a detail.
typedef InfoRow = (IconData icon, String title, String detail);

/// The card of icon rows (Figma "Pcard" with "Li" rows, 686:109).
class InfoCard extends StatelessWidget {
  const InfoCard({super.key, required this.rows});

  final List<InfoRow> rows;

  @override
  Widget build(BuildContext context) => AuraCard(
    child: Column(
      children: [
        for (final (icon, title, detail) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AuraColors.yellowTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 18, color: AuraColors.mute),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AuraText.body.copyWith(
                          fontWeight: FontWeight.w700,
                          fontVariations: const [FontVariation('wght', 700)],
                        ),
                      ),
                      Text(
                        detail,
                        style: AuraText.small.copyWith(color: AuraColors.mute),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// A big icon on a soft tile (CheckEmail's envelope, Lock's face).
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 126,
      height: 74,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Icon(icon, size: 64, color: color),
    ),
  );
}
