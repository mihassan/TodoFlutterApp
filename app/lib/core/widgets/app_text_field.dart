import 'package:flutter/material.dart';

/// A styled text field with consistent decoration and accessibility.
///
/// Wraps [TextFormField] with app defaults (outlined, filled).
/// Supports [validator], [obscureText], and [textInputAction].
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    this.controller,
    this.validator,
    this.obscureText = false,
    this.textInputAction,
    this.keyboardType,
    this.maxLines = 1,
    this.autofocus = false,
    this.onFieldSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool autofocus;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: label,
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: validator,
        obscureText: obscureText,
        textInputAction: textInputAction,
        keyboardType: keyboardType,
        maxLines: maxLines,
        autofocus: autofocus,
        onFieldSubmitted: onFieldSubmitted,
      ),
    );
  }
}
