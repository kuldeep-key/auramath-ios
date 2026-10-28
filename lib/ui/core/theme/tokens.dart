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

  /// Dims the screen behind a lesson sheet (navy at 40 %).
  static const scrim = Color(0x660F2A73);

  /// The inset shade along a bar's base (black at 12 %).
  static const barShade = Color(0x1F000000);
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

/// Nunito is a variable font: each style sets the weight axis directly so the
/// weight renders the same on every platform.
abstract final class AuraText {
  static TextStyle _nunito(double weight, double size, {double? height}) =>
      TextStyle(
        fontFamily: 'Nunito',
        fontSize: size,
        height: height,
        color: AuraColors.ink,
        fontWeight: FontWeight.values[(weight ~/ 100) - 1],
        fontVariations: [FontVariation('wght', weight)],
      );

  static final story = _nunito(800, 26, height: 1.3);
  static final button = _nunito(900, 22);
  static final standing = _nunito(900, 21);
  static final bubble = _nunito(800, 20, height: 1.2);
  static final chip = _nunito(900, 20);
  static final title = _nunito(900, 28);
  static final body = _nunito(600, 17);
}
