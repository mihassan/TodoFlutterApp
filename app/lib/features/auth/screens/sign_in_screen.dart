import 'package:flutter/material.dart';

import 'package:todo_flutter_app/app/spacing.dart';

/// Placeholder sign-in screen.
///
/// Will be replaced with a real form (email/password + Google) in Phase 7.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Todo', style: textTheme.headlineLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Sign in to get started',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
