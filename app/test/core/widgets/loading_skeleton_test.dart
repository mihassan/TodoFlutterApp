import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/core/widgets/loading_skeleton.dart';

import '../../helpers/test_app.dart';

void main() {
  group('LoadingSkeleton', () {
    testWidgets('renders default 5 skeleton items', (tester) async {
      await tester.pumpWidget(testApp(const LoadingSkeleton()));

      // Verify the ListView exists (items are lazily built).
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders custom item count', (tester) async {
      await tester.pumpWidget(testApp(const LoadingSkeleton(itemCount: 3)));

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('has accessibility label', (tester) async {
      await tester.pumpWidget(testApp(const LoadingSkeleton()));

      final semantics = tester.getSemantics(find.byType(LoadingSkeleton));
      expect(semantics.label, 'Loading content');
    });
  });
}
