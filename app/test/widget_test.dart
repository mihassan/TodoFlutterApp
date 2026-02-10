import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/main.dart';

import 'helpers/test_app.dart';

void main() {
  testWidgets('TodoApp — smoke test renders without crashing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: unauthenticatedOverrides(),
        child: const TodoApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Unauthenticated by default → redirected to sign-in screen.
    expect(find.text('Sign in to get started'), findsOneWidget);
  });
}
