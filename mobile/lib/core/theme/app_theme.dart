import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// Material 3 theme factory for CivicConnect.
/// Provides [light()] and [dark()] theme data built from the brand colour seed.
abstract final class AppTheme {

  static ThemeData light() {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.primarySeed,
      brightness: Brightness.light,
    ).copyWith(
      primary:            AppColors.primary,
      onPrimary:          AppColors.onPrimary,
      primaryContainer:   AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary:            AppColors.secondary,
      onSecondary:          AppColors.onSecondary,
      secondaryContainer:   AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary:            AppColors.tertiary,
      onTertiary:          AppColors.onTertiary,
      tertiaryContainer:   AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      error:            AppColors.error,
      onError:          AppColors.onError,
      errorContainer:   AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface:          AppColors.surface,
      onSurface:        AppColors.onSurface,
      surfaceContainerHighest: AppColors.surfaceVariant,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline:        AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface:   AppColors.inverseSurface,
      onInverseSurface: AppColors.inverseOnSurface,
      inversePrimary:   AppColors.inversePrimary,
    );
    return _buildTheme(cs);
  }

  static ThemeData dark() {
    final cs = ColorScheme.fromSeed(
      seedColor: AppColors.primarySeed,
      brightness: Brightness.dark,
    ).copyWith(
      primary:            AppColors.darkPrimary,
      onPrimary:          AppColors.darkOnPrimary,
      primaryContainer:   AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.darkOnPrimaryContainer,
      secondary:            AppColors.darkSecondary,
      onSecondary:          AppColors.darkOnSecondary,
      secondaryContainer:   AppColors.darkSecondaryContainer,
      onSecondaryContainer: AppColors.darkOnSecondaryContainer,
      tertiary:            AppColors.darkTertiary,
      onTertiary:          AppColors.darkOnTertiary,
      tertiaryContainer:   AppColors.darkTertiaryContainer,
      onTertiaryContainer: AppColors.darkOnTertiaryContainer,
      error:            AppColors.darkError,
      onError:          AppColors.darkOnError,
      errorContainer:   AppColors.darkErrorContainer,
      onErrorContainer: AppColors.darkOnErrorContainer,
      surface:          AppColors.darkSurface,
      onSurface:        AppColors.darkOnSurface,
      surfaceContainerHighest: AppColors.darkSurfaceVariant,
      onSurfaceVariant: AppColors.darkOnSurfaceVariant,
      outline:        AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
    );
    return _buildTheme(cs);
  }

  static ThemeData _buildTheme(ColorScheme cs) => ThemeData(
    useMaterial3: true,
    colorScheme:  cs,
    textTheme:    AppTypography.textTheme.apply(
      bodyColor:    cs.onSurface,
      displayColor: cs.onSurface,
    ),
    scaffoldBackgroundColor: cs.surface,

    appBarTheme: AppBarTheme(
      centerTitle:     true,
      elevation:       0,
      scrolledUnderElevation: 2,
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(color: cs.onSurface),
    ),

    navigationBarTheme: NavigationBarThemeData(
      elevation:            3,
      labelBehavior:        NavigationDestinationLabelBehavior.alwaysShow,
      backgroundColor:      cs.surface,
      indicatorColor:       cs.primaryContainer,
      iconTheme:            WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: cs.onPrimaryContainer, size: 24);
        }
        return IconThemeData(color: cs.onSurfaceVariant, size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final style = AppTypography.textTheme.labelMedium!;
        if (states.contains(WidgetState.selected)) {
          return style.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600);
        }
        return style.copyWith(color: cs.onSurfaceVariant);
      }),
    ),

    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cs.surface,
      surfaceTintColor: cs.primary,
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: AppTypography.textTheme.labelLarge,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: AppTypography.textTheme.labelLarge,
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: AppTypography.textTheme.labelLarge,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled:          true,
      fillColor:       cs.surfaceContainerHighest,
      border:          OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder:   OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder:   OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
      errorBorder:     OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: cs.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      hintStyle:  AppTypography.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: cs.primaryContainer,
      foregroundColor: cs.onPrimaryContainer,
      elevation:       3,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),

    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      labelStyle: AppTypography.textTheme.labelMedium,
    ),

    dividerTheme: DividerThemeData(
      color:     cs.outlineVariant,
      thickness: 1,
      space:     1,
    ),

    snackBarTheme: SnackBarThemeData(
      behavior:        SnackBarBehavior.floating,
      shape:           RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      backgroundColor: cs.inverseSurface,
      contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: cs.onInverseSurface),
      actionTextColor:  cs.inversePrimary,
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),

    dialogTheme: DialogThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: AppTypography.textTheme.headlineSmall,
      contentTextStyle: AppTypography.textTheme.bodyMedium,
    ),

    pageTransitionsTheme: PageTransitionsTheme(
      builders: {
        TargetPlatform.android: const PredictiveBackPageTransitionsBuilder(),
        TargetPlatform.iOS:     const CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
