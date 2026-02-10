import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:todo_flutter_app/app/theme.dart';
import 'package:todo_flutter_app/data/repositories/fake_auth_repository.dart';
import 'package:todo_flutter_app/features/auth/providers/auth_provider.dart';

/// Wraps [child] in a [MaterialApp] with the app's light theme.
///
/// Use in widget tests to provide theme context:
/// ```dart
/// await tester.pumpWidget(testApp(MyWidget()));
/// ```
Widget testApp(Widget child) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(body: child),
  );
}

/// Wraps a [GoRouter] in a themed [MaterialApp.router] with [ProviderScope].
///
/// Use [overrides] to stub providers (e.g. auth state):
/// ```dart
/// await tester.pumpWidget(testRouterApp(
///   router: myRouter,
///   overrides: [isAuthenticatedProvider.overrideWith((_) => true)],
/// ));
/// ```
Widget testRouterApp({
  required GoRouter router,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(theme: AppTheme.lightTheme, routerConfig: router),
  );
}

/// Standard provider overrides for tests that don't use Firebase.
///
/// Overrides the [authRepositoryProvider] with a [FakeAuthRepository],
/// breaking the dependency chain to Firebase SDK.
/// Pass [currentUser] to simulate an authenticated user.
List<Override> fakeAuthOverrides({FakeAuthRepository? repository}) {
  final repo = repository ?? FakeAuthRepository();
  return [authRepositoryProvider.overrideWithValue(repo)];
}

/// Provider overrides to simulate an authenticated state without Firebase.
///
/// Uses [isAuthenticatedProvider] override (for the router) plus
/// [authRepositoryProvider] override (to prevent Firebase SDK calls
/// from screens that watch [authControllerProvider]).
List<Override> authenticatedOverrides() {
  return [
    ...fakeAuthOverrides(),
    isAuthenticatedProvider.overrideWith((_) => true),
  ];
}

/// Provider overrides to simulate an unauthenticated state without Firebase.
List<Override> unauthenticatedOverrides() {
  return [
    ...fakeAuthOverrides(),
    isAuthenticatedProvider.overrideWith((_) => false),
  ];
}
