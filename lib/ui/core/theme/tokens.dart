import 'package:flutter/painting.dart';

/// The Auramath palette, from the living prototype's V2 tokens. The only
/// place a colour value lives.
abstract final class AuraColors {
  static const blue = Color(0xFF2F6BFF);
  static const blueLip = Color(0xFF1F4FD6);
  static const navy = Color(0xFF0F2A73);
  static const blueTint = Color(0xFFE8EEFF);
  static const blueInk = Color(0xFF1D3FB8);
  static const yellow = Color(0xFFFFC531);
  static const yellowLip = Color(0xFFE5A100);
  static const yellowTint = Color(0xFFFFF4CC);
  static const yellowInk = Color(0xFF8A5A00);
  static const yellowFg = Color(0xFF2A1C00);
  static const ink = Color(0xFF23263A);
  static const mute = Color(0xFF5B6178);
  static const line = Color(0xFFE3E6EE);
  static const white = Color(0xFFFFFFFF);
  static const soft = Color(0xFFF5F7FC);
  static const green = Color(0xFF22A06B);
  static const coral = Color(0xFFFF7A59);
  static const keypadBg = Color(0xFFD1D5DB);
  static const keyShadow = Color(0xFF898A8D);
  static const keyText = Color(0xFF111111);

  /// The Button component (265:25562): each colour's gradient, top to
  /// bottom, and the yellow button's label.
  static const yellowTop = Color(0xFFFFE45C);
  static const yellowBottom = Color(0xFFFFB000);
  static const buttonYellowText = Color(0xFF3A2600);
  static const blueTop = Color(0xFF4A86FF);
  static const whiteBottom = Color(0xFFE3E9F7);

  /// The dark band inside a button's bottom edge (black at 18 %).
  static const buttonInnerShade = Color(0x2E000000);

  /// A disabled button.
  static const buttonOffTop = Color(0xFFEEF1F6);
  static const buttonOffBottom = Color(0xFFDDE2EC);
  static const buttonOffEdge = Color(0xFF9AA3B8);
  static const buttonOffText = Color(0xFF5D6275);

  /// The empty part of a progress bar.
  static const track = Color(0xFFE7EAF2);

  /// An unticked option's ring.
  static const tickOff = Color(0xFFC5CBD8);

  /// The small flag on a suggested option ("Usual for age 7").
  static const flag = Color(0xFFFFE7A3);
  static const flagInk = Color(0xFF6B4A00);

  /// Dims the screen behind a lesson sheet (navy at 40 %).
  static const scrim = Color(0x660F2A73);

  /// The inset shade along a bar's base (black at 12 %).
  static const barShade = Color(0x1F000000);

  /// An earned badge: a gold disc with a darker edge and lip (B1, Y4).
  static const badgeGoldLight = Color(0xFFFFE08A);
  static const badgeGold = Color(0xFFFFB800);
  static const badgeGoldEdge = Color(0xFFE59A00);
  static const badgeGoldLip = Color(0xFFB97800);

  /// A badge or new skill shown large: a blue disc (B2, Up).
  static const badgeBlueLight = Color(0xFF9CB8FF);
  static const badgeBlue = Color(0xFF5A86FF);
  static const badgeBlueEdge = Color(0xFF2F55D9);
  static const badgeBlueLip = Color(0xFF1C3A9E);

  /// A text link on the blue play background (Open 644:107).
  static const linkOnBlue = Color(0xFFFFD86B);

  /// The sash board's top-left light (Y4).
  static const sashLight = Color(0xFFFFDE7A);
}

abstract final class AuraRadii {
  static const button = 18.0;
  static const card = 24.0;
  static const panel = 20.0;
  static const bubble = 18.0;
  static const barTop = 14.0;
  static const barBottom = 4.0;
  static const key = 8.0;

  /// Small tiles: the ribbon, the undo key, value boxes, the brace label.
  static const small = 14.0;
}

/// The type scale, from the Figma frames (page 629:2). Each comment gives the
/// Figma spec: weight, size / line height, tracking, colour. Line height
/// "normal" in Figma is the font's own, which is Flutter's default (null).
///
/// Nunito is a variable font: each style sets the weight axis directly so the
/// weight renders the same on every platform. Weights: Regular 400,
/// SemiBold 600, Bold 700, ExtraBold 800, Black 900.
abstract final class AuraText {
  static TextStyle _nunito(
    double weight,
    double size, {
    double? height,
    double? tracking,
    Color color = AuraColors.ink,
  }) => TextStyle(
    fontFamily: 'Nunito',
    fontSize: size,
    height: height,
    letterSpacing: tracking,
    color: color,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontVariations: [FontVariation('wght', weight)],
  );

  // ---- Grown-ups' white screens -------------------------------------------

  /// The big welcome line. Black 34 / 39.1, -0.3, ink (Welcome 643:2).
  static final hero = _nunito(900, 34, height: 1.15, tracking: -0.3);

  /// A grown-up screen's title. Black 30 / 34.5, -0.3, ink.
  static final heading = _nunito(900, 30, height: 1.15, tracking: -0.3);

  /// The line under a title. SemiBold 17 / 23.8, mute.
  static final subtitle = _nunito(600, 17, height: 1.4, color: AuraColors.mute);

  /// A stressed word in a subtitle ("9:59" on JoinCode 644:75). Black 17.
  static final subtitleBold = _nunito(
    900,
    17,
    height: 1.4,
    color: AuraColors.mute,
  );

  /// Running text Figma doesn't draw (errors, "Saving…"). SemiBold 17, ink.
  static final body = _nunito(600, 17);

  /// An option's label, a list row's or a card's title. Black 19, ink.
  static final option = _nunito(900, 19);

  /// The line under an option (Start, Goal, Rights, Plan). SemiBold 14, mute.
  static final optionDetail = _nunito(600, 14, color: AuraColors.mute);

  /// A "Li" row in a card (Data, StartNotSure, Notify): title Bold 17, ink,
  /// and [caption] under it, SemiBold 15, mute.
  static final infoTitle = _nunito(700, 17);
  static final caption = _nunito(600, 15, color: AuraColors.mute);

  /// Small text Figma doesn't draw (a field's error, a list). SemiBold 15.
  static final small = _nunito(600, 15);

  /// A "Kv" row (684:99): label Bold 15, ink; value Black 15, blue ink.
  static final kvLabel = _nunito(700, 15);
  static final kvValue = _nunito(900, 15, color: AuraColors.blueInk);

  /// A card's line under its title (PHome, Book). Bold 16, mute.
  static final cardLine = _nunito(700, 16, color: AuraColors.mute);

  /// A session note's text (Book, Family, R0). SemiBold 16, ink.
  static final note = _nunito(600, 16);

  /// The small title beside back (Book 652:35). Bold 18, ink.
  static final barTitle = _nunito(700, 18);

  /// Book's tabs. ExtraBold 14.
  static final tab = _nunito(800, 14);

  /// A small capitals heading ("GROWN-UPS", "NEXT TO EARN"). Black 11, +0.9.
  static final eyebrow = _nunito(900, 11, tracking: 0.9);

  /// The small flag on a suggested option. Black 12, flag ink.
  static final flag = _nunito(900, 12, color: AuraColors.flagInk);

  /// A text link. Black 18, blue ink.
  static final link = _nunito(900, 18, color: AuraColors.blueInk);

  /// A digit in the code boxes (JoinCode, NewCode). Black 30, ink.
  static final codeDigit = _nunito(900, 30);

  /// The Button component's label (265:25562). Black 22.
  static final button = _nunito(900, 22);

  // ---- The child's blue screens -------------------------------------------

  /// "Auramath" on Open (644:107). Black 44, -0.9, white, a navy shadow
  /// 4 below.
  static final brand = _nunito(900, 44, tracking: -0.9, color: AuraColors.white)
      .copyWith(
        shadows: const [Shadow(color: AuraColors.navy, offset: Offset(0, 4))],
      );

  /// The yellow ribbon's label. Black 24, yellow fg.
  static final ribbon = _nunito(900, 24, color: AuraColors.yellowFg);

  /// The line under a ribbon. ExtraBold 21, white (mute on Sound, NoVoice).
  static final play = _nunito(800, 21, color: AuraColors.white);

  /// A big title on a child's screen (B2, Y3, Sound, NoVoice, R1). Black 30.
  static final playTitle = _nunito(900, 30);

  /// "You solved the Tree Word Problem!" (Y2 647:158). Black 24, white.
  static final cheer = _nunito(900, 24, color: AuraColors.white);

  /// The child's name on IsThisYou (644:205). Black 32, white.
  static final playName = _nunito(900, 32, color: AuraColors.white);

  /// The child's name beside their portrait (Home). Bold 22, white.
  static final kidName = _nunito(700, 22, color: AuraColors.white);

  /// A badge's name under it (B1), Bold 18; [badgeNext] for one not earned
  /// yet, Bold 15. White.
  static final badgeName = _nunito(700, 18, color: AuraColors.white);
  static final badgeNext = _nunito(700, 15, color: AuraColors.white);

  /// A trail stop's name, Bold 16 / 17.6, and the note under it ("Done",
  /// "You are here"), ExtraBold 13 (K2 651:68).
  static final trailStop = _nunito(700, 16, height: 1.1);
  static final trailNote = _nunito(800, 13);

  /// The next case's card (X1 650:166): name Black 22, navy; line Black 17,
  /// mute.
  static final caseTitle = _nunito(900, 22, color: AuraColors.navy);
  static final caseLine = _nunito(900, 17, color: AuraColors.mute);

  // ---- The lesson ---------------------------------------------------------

  /// The story (M0 647:78). ExtraBold 27 / 35.1; [storyName] for an item's
  /// name in it, Black.
  static final story = _nunito(800, 27, height: 1.3);
  static final storyName = _nunito(900, 27, height: 1.3);

  /// The coach's speech bubble. ExtraBold 20 / 24, ink. [bubbleBig] when the
  /// voice is resting (not in Figma).
  static final bubble = _nunito(800, 20, height: 1.2);
  static final bubbleBig = _nunito(800, 26, height: 1.2);

  /// A lesson button ("I know it", "Help me") and a tray piece. Black 21.
  static final standing = _nunito(900, 21);

  /// A lesson sheet's title and line (M1-help 666:2, M1-pause 666:70):
  /// Black 26; Bold 20 / 26, mute.
  static final sheetTitle = _nunito(900, 26);
  static final sheetLine = _nunito(
    700,
    20,
    height: 1.3,
    color: AuraColors.mute,
  );

  /// A title on a lesson card Figma doesn't draw ("Still there?"). Black 28.
  static final title = _nunito(900, 28);

  /// A chip in the question strip. Black 20.
  static final chip = _nunito(900, 20);

  /// On the board (M1 648:2, H2 667:2): a bar's value above it, Black 26; a
  /// value inside a bar, Black 22, white; an item's name under its bar,
  /// Black 20 / 22; an empty slot's label, Black 14 / 16.1, blue ink; the
  /// brace's label, Bold 20, white; the gap's value, Black 19, blue ink.
  static final barValue = _nunito(900, 26);
  static final barInside = _nunito(900, 22, color: AuraColors.white);
  static final barName = _nunito(900, 20, height: 1.1);
  static final slotLabel = _nunito(
    900,
    14,
    height: 1.15,
    color: AuraColors.blueInk,
  );
  static final braceLabel = _nunito(700, 20, color: AuraColors.white);
  static final gap = _nunito(900, 19, color: AuraColors.blueInk);
}
