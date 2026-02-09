import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:todo_flutter_app/app/routes.dart';
import 'package:todo_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:todo_flutter_app/features/auth/screens/sign_in_screen.dart';
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
      final goingToSignIn = state.matchedLocation == AppRoutes.signIn;

      if (!isAuthenticated && !goingToSignIn) {
        return AppRoutes.signIn;
      }
      if (isAuthenticated && goingToSignIn) {
        return AppRoutes.tasks;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
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
class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
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
