import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/main.dart';

void main() {
  testWidgets('TodoApp — smoke test renders without crashing', (tester) async {
    await tester.pumpWidget(const TodoApp());
    expect(find.text('Todo App'), findsOneWidget);
  });
}
