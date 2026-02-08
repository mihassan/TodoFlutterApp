import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/core/widgets/app_button.dart';

import '../../helpers/test_app.dart';

void main() {
  group('AppButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        testApp(AppButton(onPressed: () {}, label: 'Save')),
      );

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        testApp(AppButton(onPressed: () => tapped = true, label: 'Save')),
      );

      await tester.tap(find.text('Save'));
      expect(tapped, isTrue);
    });

    testWidgets('shows spinner and disables tap when isLoading is true', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        testApp(
          AppButton(
            onPressed: () => tapped = true,
            label: 'Save',
            isLoading: true,
          ),
        ),
      );

      // Label should not be visible when loading.
      expect(find.text('Save'), findsNothing);
      // Spinner should be visible.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Tapping should not trigger onPressed.
      await tester.tap(find.byType(FilledButton));
      expect(tapped, isFalse);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        testApp(const AppButton(onPressed: null, label: 'Save')),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('has Semantics button label', (tester) async {
      await tester.pumpWidget(
        testApp(AppButton(onPressed: () {}, label: 'Save')),
      );

      final semantics = tester.getSemantics(find.byType(AppButton));
      expect(semantics.label, 'Save');
    });
  });
}
