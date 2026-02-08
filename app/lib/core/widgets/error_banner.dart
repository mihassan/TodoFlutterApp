import 'package:flutter/material.dart';

import 'package:todo_flutter_app/app/spacing.dart';

/// A dismissible error banner shown at the top of a screen or form.
///
/// Displays a [message] with an error color scheme and an optional
/// [onDismiss] callback for the close button.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({required this.message, this.onDismiss, super.key});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      liveRegion: true,
      label: 'Error: $message',
      child: MaterialBanner(
        content: Text(
          message,
          style: TextStyle(color: colorScheme.onErrorContainer),
        ),
        backgroundColor: colorScheme.errorContainer,
        leading: Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
        padding: const EdgeInsets.all(AppSpacing.sm),
        actions: [
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: colorScheme.onErrorContainer),
              tooltip: 'Dismiss error',
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
