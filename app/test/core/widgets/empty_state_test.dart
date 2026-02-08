import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/core/widgets/empty_state.dart';

import '../../helpers/test_app.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders icon and title', (tester) async {
      await tester.pumpWidget(
        testApp(const EmptyState(icon: Icons.inbox, title: 'No tasks yet')),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No tasks yet'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        testApp(
          const EmptyState(
            icon: Icons.inbox,
            title: 'No tasks yet',
            subtitle: 'Tap + to create one',
          ),
        ),
      );

      expect(find.text('Tap + to create one'), findsOneWidget);
    });

    testWidgets('does not render subtitle when not provided', (tester) async {
      await tester.pumpWidget(
        testApp(const EmptyState(icon: Icons.inbox, title: 'No tasks yet')),
      );

      // Only icon + title — no extra Text widget beyond them.
      expect(find.byType(Text), findsOneWidget);
    });
  });
}
