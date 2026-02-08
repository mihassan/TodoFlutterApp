import 'package:flutter/material.dart';

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
