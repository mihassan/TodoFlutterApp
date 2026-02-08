import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/core/widgets/app_text_field.dart';

import '../../helpers/test_app.dart';

void main() {
  group('AppTextField', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(testApp(const AppTextField(label: 'Email')));

      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('accepts user input', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        testApp(AppTextField(label: 'Email', controller: controller)),
      );

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      expect(controller.text, 'test@example.com');
    });

    testWidgets('shows validation error', (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        testApp(
          Form(
            key: formKey,
            child: AppTextField(
              label: 'Email',
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
          ),
        ),
      );

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('obscures text when obscureText is true', (tester) async {
      await tester.pumpWidget(
        testApp(const AppTextField(label: 'Password', obscureText: true)),
      );

      final editableText = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(editableText.obscureText, isTrue);
    });

    testWidgets('has Semantics textField label', (tester) async {
      await tester.pumpWidget(testApp(const AppTextField(label: 'Email')));

      final semantics = tester.getSemantics(find.byType(AppTextField));
      expect(semantics.label, 'Email');
    });
  });
}
