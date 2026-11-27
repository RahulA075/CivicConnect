import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Google sign-in button following Material 3 branding guidelines.
class GoogleLoginButton extends StatelessWidget {
  const GoogleLoginButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool          isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: isLoading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Google "G" logo using text as placeholder
                // Replace with flutter_svg + Google G SVG in production
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(colors: [
                      Color(0xFF4285F4),
                      Color(0xFFEA4335),
                      Color(0xFFFBBC05),
                      Color(0xFF34A853),
                      Color(0xFF4285F4),
                    ]),
                  ),
                  child: const Center(
                    child: Text('G',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const Gap(12),
                const Text('Continue with Google'),
              ],
            ),
    );
  }
}
