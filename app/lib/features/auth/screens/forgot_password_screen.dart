import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:todo_flutter_app/app/spacing.dart';
import 'package:todo_flutter_app/core/widgets/app_button.dart';
import 'package:todo_flutter_app/core/widgets/app_text_field.dart';
import 'package:todo_flutter_app/core/widgets/error_banner.dart';
import 'package:todo_flutter_app/features/auth/controllers/auth_controller.dart';

/// Forgot-password screen that sends a reset email.
///
/// Shows a success message after the email is sent.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(_emailController.text.trim());

    if (success && mounted) {
      setState(() => _emailSent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _emailSent
                ? _buildSuccessContent(textTheme, colorScheme)
                : _buildFormContent(authState, textTheme, colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessContent(TextTheme textTheme, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 64,
          color: colorScheme.primary,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Check your email',
          style: textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'We sent a password reset link to '
          '${_emailController.text.trim()}',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(onPressed: () => context.pop(), label: 'Back to sign in'),
      ],
    );
  }

  Widget _buildFormContent(
    AuthFormState authState,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            'Reset password',
            style: textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Enter your email and we'll send you a link to "
            'reset your password.',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Error banner
          if (authState.failure != null) ...[
            ErrorBanner(
              message: authState.failure!.message,
              onDismiss: () {
                ref.read(authControllerProvider.notifier).clearError();
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Email field
          AppTextField(
            label: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofocus: true,
            onFieldSubmitted: (_) => _sendResetEmail(),
            validator: _validateEmail,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Send button
          AppButton(
            onPressed: _sendResetEmail,
            label: 'Send reset link',
            isLoading: authState.isLoading,
          ),
        ],
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Enter a valid email';
    }
    return null;
  }
}
