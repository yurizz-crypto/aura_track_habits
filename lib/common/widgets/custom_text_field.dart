import 'package:flutter/material.dart';

/// A wrapper around [TextField] to provide consistent styling (borders, colors)
/// and reduce boilerplate code in forms.
class CustomTextField extends StatelessWidget {
  /// Controls the text being edited.
  final TextEditingController controller;

  /// The text displayed inside the field's border.
  final String label;

  /// If `true`, obfuscates the text (e.g., for passwords).
  final bool isPassword;

  /// Determines the keyboard type (email, number, text, etc.).
  final TextInputType inputType;

  /// The action button on the keyboard (Next, Done, etc.).
  final TextInputAction action;

  /// Callback triggered when the user presses the keyboard action button.
  final ValueChanged<String>? onSubmitted;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.isPassword = false,
    this.inputType = TextInputType.text,
    this.action = TextInputAction.done,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      textInputAction: action,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.teal, width: 2),
        ),
      ),
    );
  }
}