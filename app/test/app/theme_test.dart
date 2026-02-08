import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/app/theme.dart';

void main() {
  group('AppTheme', () {
    test('lightTheme uses Material 3', () {
      expect(AppTheme.lightTheme.useMaterial3, isTrue);
    });

    test('darkTheme uses Material 3', () {
      expect(AppTheme.darkTheme.useMaterial3, isTrue);
    });

    test('lightTheme has light brightness', () {
      expect(AppTheme.lightTheme.colorScheme.brightness, Brightness.light);
    });

    test('darkTheme has dark brightness', () {
      expect(AppTheme.darkTheme.colorScheme.brightness, Brightness.dark);
    });

    test('buttons have 48dp minimum height', () {
      final filledStyle = AppTheme.lightTheme.filledButtonTheme.style;
      final resolved = filledStyle!.minimumSize!.resolve({});
      expect(resolved!.height, 48);
    });
  });
}
