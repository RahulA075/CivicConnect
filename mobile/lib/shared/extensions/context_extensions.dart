import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';

extension BuildContextX on BuildContext {
  // ── Theming ──────────────────────────────────────────────────────────
  ThemeData  get theme      => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme  get textTheme  => Theme.of(this).textTheme;

  // ── Localisation ──────────────────────────────────────────────────────
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  // ── Media query helpers ───────────────────────────────────────────────
  Size   get screenSize   => MediaQuery.sizeOf(this);
  double get screenWidth  => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get padding  => MediaQuery.paddingOf(this);

  // ── Snack bar shortcuts ───────────────────────────────────────────────
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? colorScheme.error : null,
        ),
      );
  }

  // ── Navigation ────────────────────────────────────────────────────────
  void pop<T>([T? result]) => Navigator.of(this).pop(result);
}
