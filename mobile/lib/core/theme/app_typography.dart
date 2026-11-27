import 'package:flutter/material.dart';

/// CivicConnect typography — Outfit typeface, full Material 3 type scale.
abstract final class AppTypography {
  // Set to 'Outfit' once the font files are added to assets/fonts/ and
  // the fonts section in pubspec.yaml is uncommented.
  static const String _fontFamily = 'Outfit';

  static const TextTheme textTheme = TextTheme(
    // Display
    displayLarge:  TextStyle(fontFamily: _fontFamily, fontSize: 57, fontWeight: FontWeight.w300, letterSpacing: -0.25),
    displayMedium: TextStyle(fontFamily: _fontFamily, fontSize: 45, fontWeight: FontWeight.w300),
    displaySmall:  TextStyle(fontFamily: _fontFamily, fontSize: 36, fontWeight: FontWeight.w400),

    // Headline
    headlineLarge:  TextStyle(fontFamily: _fontFamily, fontSize: 32, fontWeight: FontWeight.w400),
    headlineMedium: TextStyle(fontFamily: _fontFamily, fontSize: 28, fontWeight: FontWeight.w400),
    headlineSmall:  TextStyle(fontFamily: _fontFamily, fontSize: 24, fontWeight: FontWeight.w400),

    // Title
    titleLarge:  TextStyle(fontFamily: _fontFamily, fontSize: 22, fontWeight: FontWeight.w500),
    titleMedium: TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: 0.15),
    titleSmall:  TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),

    // Body
    bodyLarge:  TextStyle(fontFamily: _fontFamily, fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5),
    bodyMedium: TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25),
    bodySmall:  TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4),

    // Label
    labelLarge:  TextStyle(fontFamily: _fontFamily, fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.1),
    labelMedium: TextStyle(fontFamily: _fontFamily, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
    labelSmall:  TextStyle(fontFamily: _fontFamily, fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
  );
}
