import 'package:flutter/material.dart';

/// A utility class for showing standardized modal dialogs across the app.
class CustomDialogs {
  /// Shows a confirmation dialog with "Cancel" and a custom confirm button.
  ///
  /// Returns `true` if the user clicks the confirm button, `false` otherwise.
  ///
  /// [title]: The bold header text of the dialog.
  /// [content]: The body text explaining the action.
  /// [confirmText]: Label for the action button (default: "Yes").
  /// [confirmColor]: Background color for the action button (default: Red).
  static Future<bool> showConfirmDialog(
      BuildContext context, {
        required String title,
        required String content,
        String confirmText = "Yes",
        Color confirmColor = Colors.red,
      }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Shows a simple information/success dialog with a single dismissal button.
  ///
  /// [title]: The header text.
  /// [content]: The body message.
  static Future<void> showSuccessDialog(
      BuildContext context, {
        required String title,
        required String content,
      }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Awesome"),
          )
        ],
      ),
    );
  }
}