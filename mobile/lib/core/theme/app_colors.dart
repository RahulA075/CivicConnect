import 'package:flutter/material.dart';

/// CivicConnect brand colour palette.
///
/// Seed colour: civic blue #1565C0.
/// Generated with Material 3 colour scheme utilities.
abstract final class AppColors {
  // ── Brand ─────────────────────────────────────────────────────────
  static const Color primarySeed = Color(0xFF1565C0);

  // ── Light theme tokens ────────────────────────────────────────────
  static const Color primary            = Color(0xFF1565C0);
  static const Color onPrimary          = Color(0xFFFFFFFF);
  static const Color primaryContainer   = Color(0xFFD6E4FF);
  static const Color onPrimaryContainer = Color(0xFF001848);

  static const Color secondary            = Color(0xFF5B6B8A);
  static const Color onSecondary          = Color(0xFFFFFFFF);
  static const Color secondaryContainer   = Color(0xFFDFE6F5);
  static const Color onSecondaryContainer = Color(0xFF18223B);

  static const Color tertiary            = Color(0xFFF59E0B);
  static const Color onTertiary          = Color(0xFFFFFFFF);
  static const Color tertiaryContainer   = Color(0xFFFEF3C7);
  static const Color onTertiaryContainer = Color(0xFF451A03);

  static const Color error            = Color(0xFFBA1A1A);
  static const Color onError          = Color(0xFFFFFFFF);
  static const Color errorContainer   = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  static const Color surface            = Color(0xFFF8F9FE);
  static const Color onSurface         = Color(0xFF191C20);
  static const Color surfaceVariant    = Color(0xFFE1E5EE);
  static const Color onSurfaceVariant  = Color(0xFF44474F);

  static const Color outline         = Color(0xFF74777F);
  static const Color outlineVariant  = Color(0xFFC4C6CF);
  static const Color inverseSurface  = Color(0xFF2E3135);
  static const Color inverseOnSurface = Color(0xFFEEF0F8);
  static const Color inversePrimary  = Color(0xFFA8C7FF);

  // ── Dark theme tokens ─────────────────────────────────────────────
  static const Color darkPrimary            = Color(0xFFA8C7FF);
  static const Color darkOnPrimary          = Color(0xFF002F6D);
  static const Color darkPrimaryContainer   = Color(0xFF00429B);
  static const Color darkOnPrimaryContainer = Color(0xFFD6E4FF);

  static const Color darkSecondary            = Color(0xFFBFC8DC);
  static const Color darkOnSecondary          = Color(0xFF293040);
  static const Color darkSecondaryContainer   = Color(0xFF3F4757);
  static const Color darkOnSecondaryContainer = Color(0xFFDFE6F5);

  static const Color darkTertiary            = Color(0xFFFFD77A);
  static const Color darkOnTertiary          = Color(0xFF3D2C00);
  static const Color darkTertiaryContainer   = Color(0xFF583F00);
  static const Color darkOnTertiaryContainer = Color(0xFFFEF3C7);

  static const Color darkError            = Color(0xFFFFB4AB);
  static const Color darkOnError          = Color(0xFF690005);
  static const Color darkErrorContainer   = Color(0xFF93000A);
  static const Color darkOnErrorContainer = Color(0xFFFFDAD6);

  static const Color darkSurface           = Color(0xFF111318);
  static const Color darkOnSurface        = Color(0xFFE2E2E9);
  static const Color darkSurfaceVariant   = Color(0xFF44474F);
  static const Color darkOnSurfaceVariant = Color(0xFFC4C6CF);

  static const Color darkOutline        = Color(0xFF8E9099);
  static const Color darkOutlineVariant = Color(0xFF44474F);

  // ── Semantic status colours ────────────────────────────────────────
  static const Color statusSubmitted   = Color(0xFF0D47A1);
  static const Color statusAssigned    = Color(0xFF4527A0);
  static const Color statusInProgress  = Color(0xFFE65100);
  static const Color statusResolved    = Color(0xFF1B5E20);
  static const Color statusOverdue     = Color(0xFFB71C1C);
  static const Color statusClosed      = Color(0xFF424242);

  static const Color priorityLow      = Color(0xFF2E7D32);
  static const Color priorityMedium   = Color(0xFFF59E0B);
  static const Color priorityHigh     = Color(0xFFE65100);
  static const Color priorityCritical = Color(0xFFB71C1C);
}
