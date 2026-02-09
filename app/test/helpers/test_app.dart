import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:todo_flutter_app/app/theme.dart';

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
