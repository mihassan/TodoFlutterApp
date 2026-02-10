import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:todo_flutter_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('App launches successfully', (WidgetTester tester) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(
        find.byType(MaterialApp),
        findsOneWidget,
        reason: 'MaterialApp should be rendered when app starts',
      );
    });

    testWidgets('Sign-in screen renders fields and actions', (
      WidgetTester tester,
    ) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('Sign in to get started'), findsOneWidget);
      expect(find.bySemanticsLabel('Email'), findsOneWidget);
      expect(find.bySemanticsLabel('Password'), findsOneWidget);
      expect(find.text('Sign in'), findsWidgets);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('Sign-up screen renders and navigates back', (
      WidgetTester tester,
    ) async {
      await app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Create account'), findsOneWidget);
      expect(find.bySemanticsLabel('Email'), findsOneWidget);
      expect(find.bySemanticsLabel('Password'), findsOneWidget);
      expect(find.bySemanticsLabel('Confirm password'), findsOneWidget);
      expect(find.text('Sign up'), findsWidgets);

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Sign in to get started'), findsOneWidget);
    });
  });
}
