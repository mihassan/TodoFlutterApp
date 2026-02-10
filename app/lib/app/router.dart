import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:todo_flutter_app/app/routes.dart';
import 'package:todo_flutter_app/app/providers/task_providers.dart';
import 'package:todo_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:todo_flutter_app/features/auth/screens/forgot_password_screen.dart';
import 'package:todo_flutter_app/features/auth/screens/sign_in_screen.dart';
import 'package:todo_flutter_app/features/auth/screens/sign_up_screen.dart';
import 'package:todo_flutter_app/features/settings/screens/settings_screen.dart';
import 'package:todo_flutter_app/features/tasks/screens/task_detail_screen.dart';
import 'package:todo_flutter_app/features/tasks/screens/task_list_screen.dart';

/// App-level [GoRouter] provider.
///
/// Uses [isAuthenticatedProvider] to redirect unauthenticated users to the
/// sign-in screen, and authenticated users away from it.
///
/// Route tree:
/// ```
/// /sign-in          → SignInScreen   (no shell)
/// /tasks            → TaskListScreen (inside shell)
/// /tasks/:taskId    → TaskDetailScreen (inside shell)
/// /settings         → SettingsScreen (inside shell)
/// ```
final routerProvider = Provider<GoRouter>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    initialLocation: AppRoutes.tasks,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthRoute =
          location == AppRoutes.signIn ||
          location == AppRoutes.signUp ||
          location == AppRoutes.forgotPassword;

      if (!isAuthenticated && !isAuthRoute) {
        return AppRoutes.signIn;
      }
      if (isAuthenticated && isAuthRoute) {
        return AppRoutes.tasks;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.tasks,
            builder: (context, state) => const TaskListScreen(),
            routes: [
              GoRoute(
                path: ':taskId',
                builder: (context, state) =>
                    TaskDetailScreen(taskId: state.pathParameters['taskId']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});

/// The app shell wrapping authenticated screens.
///
/// Provides a bottom navigation bar for switching between tasks and settings.
class _AppShell extends ConsumerWidget {
  const _AppShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncControllerProvider);
    final theme = Theme.of(context);
    final showIndicator = syncStatus.isSyncing || syncStatus.hasError;

    return Scaffold(
      body: Stack(
        children: [
          child,
          if (showIndicator)
            Positioned(
              top: 12,
              right: 12,
              child: IgnorePointer(
                child: _SyncStatusPill(
                  color: syncStatus.isSyncing
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                  icon: syncStatus.isSyncing ? Icons.sync : Icons.cloud_off,
                  label: syncStatus.isSyncing ? 'Syncing' : 'Sync error',
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (index) => _onTap(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(AppRoutes.settings)) return 1;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.tasks);
      case 1:
        context.go(AppRoutes.settings);
    }
  }
}

class _SyncStatusPill extends StatelessWidget {
  const _SyncStatusPill({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
