import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/core/widgets/error_banner.dart';

import '../../helpers/test_app.dart';

void main() {
  group('ErrorBanner', () {
    testWidgets('renders error message', (tester) async {
      await tester.pumpWidget(
        testApp(const ErrorBanner(message: 'Something went wrong')),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows error icon', (tester) async {
      await tester.pumpWidget(testApp(const ErrorBanner(message: 'Oops')));

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('calls onDismiss when close button is tapped', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        testApp(
          ErrorBanner(message: 'Oops', onDismiss: () => dismissed = true),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, isTrue);
    });

    testWidgets('does not show close button when onDismiss is null', (
      tester,
    ) async {
      await tester.pumpWidget(testApp(const ErrorBanner(message: 'Oops')));

      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}
