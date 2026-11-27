import 'package:flutter/material.dart';

/// Full-width filled button with a built-in loading state.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String   label;
  final VoidCallback? onPressed;
  final bool     isLoading;
  final Widget?  icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [icon!, const SizedBox(width: 8), Text(label)],
              )
            : Text(label);

    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: child,
    );
  }
}

/// Full-width outlined button with a built-in loading state.
class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String        label;
  final VoidCallback? onPressed;
  final bool          isLoading;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Text(label),
      );
}
