import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildAuraTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'Nunito',
  scaffoldBackgroundColor: AuraColors.white,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AuraColors.blue,
    primary: AuraColors.blue,
    secondary: AuraColors.yellow,
    surface: AuraColors.white,
    onSurface: AuraColors.ink,
  ),
  textTheme: TextTheme(
    headlineMedium: AuraText.title,
    bodyLarge: AuraText.body,
    bodyMedium: AuraText.body,
  ),
);
