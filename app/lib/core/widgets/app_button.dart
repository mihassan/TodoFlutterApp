import 'package:flutter/material.dart';

import 'package:todo_flutter_app/app/spacing.dart';

/// A primary filled button with consistent sizing and accessibility.
///
/// Wraps [FilledButton] with app defaults (48dp height, full width).
/// Pass [isLoading] to show a spinner and disable interaction.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                height: AppSpacing.lg,
                width: AppSpacing.lg,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}
