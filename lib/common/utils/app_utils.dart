import 'package:flutter/material.dart';

/// Utility class containing shared helper functions for validation and UI feedback.
class AppUtils {
  /// Validates if the provided [email] string matches standard email format.
  /// Returns `true` if valid, `false` otherwise.
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Displays a global SnackBar at the bottom of the screen.
  ///
  /// [context]: The build context to find the Scaffold.
  /// [message]: The text content to display.
  /// [isError]: If `true`, sets the background color to red; otherwise, teal.
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.teal,
      ),
    );
  }
}