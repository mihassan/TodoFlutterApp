import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/app/router.dart';
import 'package:todo_flutter_app/app/routes.dart';

import '../helpers/test_app.dart';

void main() {
  group('AppRouter — auth redirect', () {
    testWidgets('redirects unauthenticated user to sign-in screen', (
      tester,
    ) async {
      final overrides = unauthenticatedOverrides();
      final container = ProviderContainer(overrides: overrides);
      final router = container.read(routerProvider);

      await tester.pumpWidget(
        testRouterApp(router: router, overrides: overrides),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign in to get started'), findsOneWidget);
      expect(find.text('Tasks'), findsNothing);

      container.dispose();
    });

    testWidgets('shows task list when authenticated', (tester) async {
      final overrides = authenticatedOverrides();
      final container = ProviderContainer(overrides: overrides);
      final router = container.read(routerProvider);

      await tester.pumpWidget(
        testRouterApp(router: router, overrides: overrides),
      );
      await tester.pumpAndSettle();

      // Should see the task list, not sign-in.
      expect(find.text('No tasks yet'), findsOneWidget);
      expect(find.text('Sign in to get started'), findsNothing);

      container.dispose();
    });

    testWidgets('redirects authenticated user away from sign-in to tasks', (
      tester,
    ) async {
      final overrides = authenticatedOverrides();
      final container = ProviderContainer(overrides: overrides);
      final router = container.read(routerProvider);

      // Manually navigate to sign-in.
      router.go(AppRoutes.signIn);

      await tester.pumpWidget(
        testRouterApp(router: router, overrides: overrides),
      );
      await tester.pumpAndSettle();

      // Should be redirected to tasks.
      expect(find.text('No tasks yet'), findsOneWidget);
      expect(find.text('Sign in to get started'), findsNothing);

      container.dispose();
    });
  });

  group('AppRouter — navigation', () {
    testWidgets('bottom nav shows Tasks and Settings destinations', (
      tester,
    ) async {
      final overrides = authenticatedOverrides();
      final container = ProviderContainer(overrides: overrides);
      final router = container.read(routerProvider);

      await tester.pumpWidget(
        testRouterApp(router: router, overrides: overrides),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Tasks'), findsWidgets);
      expect(find.text('Settings'), findsOneWidget);

      container.dispose();
    });

    testWidgets('tapping Settings navigates to settings screen', (
      tester,
    ) async {
      final overrides = authenticatedOverrides();
      final container = ProviderContainer(overrides: overrides);
      final router = container.read(routerProvider);

      await tester.pumpWidget(
        testRouterApp(router: router, overrides: overrides),
      );
      await tester.pumpAndSettle();

      // Tap the Settings destination in the bottom nav.
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);

      container.dispose();
    });

    testWidgets('navigating to task detail shows taskId', (tester) async {
      final overrides = authenticatedOverrides();
      final container = ProviderContainer(overrides: overrides);
      final router = container.read(routerProvider);

      await tester.pumpWidget(
        testRouterApp(router: router, overrides: overrides),
      );
      await tester.pumpAndSettle();

      // Navigate programmatically to a task detail.
      router.go(AppRoutes.taskDetailPath('abc-123'));
      await tester.pumpAndSettle();

      expect(find.text('Task abc-123'), findsOneWidget);
      expect(find.text('Detail view coming soon'), findsOneWidget);

      container.dispose();
    });
  });
}
