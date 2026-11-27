import 'package:flutter/material.dart';

/// A reusable widget that renders the Tamil Nadu Government logo as a subtle
/// centred watermark behind any page content.
///
/// Usage — wrap any [Scaffold] body (or any widget) with this:
/// ```dart
/// AppBackground(child: myWidget)
/// ```
///
/// For global injection, the widget is applied once via [MaterialApp.builder]
/// in [app.dart], so individual pages never need to use it directly.
class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  /// Logo size: scales with screen width for responsive support.
  /// Mobile: ~220 px, Tablet: ~260 px, Desktop: ~280 px.
  static double _logoSize(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1024) return 280;
    if (w >= 600)  return 260;
    return 220;
  }

  /// Opacity: 5% in light theme, 7% in dark theme.
  static double _opacity(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? 0.07 : 0.05;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Layer 1: Watermark (behind all content) ─────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Opacity(
                opacity: _opacity(context),
                child: Image.asset(
                  'assets/images/tamilnadu_logo.png',
                  width:  _logoSize(context),
                  fit:    BoxFit.contain,
                  // Suppress errors if the asset is missing in test environments
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),

        // ── Layer 2: Page content ────────────────────────────────────────────
        child,
      ],
    );
  }
}
