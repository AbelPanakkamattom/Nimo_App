import 'package:flutter/material.dart';

/// Helper class for showing error and success messages
/// using SnackBar.
class ChatErrorHelper {
  ChatErrorHelper._();

  // =========================================================
  // SHOW ERROR
  // =========================================================

  static void showError(
      BuildContext context,
      String message,
      ) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
          behavior:
          SnackBarBehavior.floating,
          backgroundColor:
          Colors.redAccent,
          duration:
          const Duration(
            seconds: 3,
          ),
        ),
      );
  }

  // =========================================================
  // SHOW SUCCESS
  // =========================================================

  static void showSuccess(
      BuildContext context,
      String message,
      ) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
          behavior:
          SnackBarBehavior.floating,
          backgroundColor:
          Colors.green,
          duration:
          const Duration(
            seconds: 2,
          ),
        ),
      );
  }

  // =========================================================
  // SHOW INFO
  // =========================================================

  static void showInfo(
      BuildContext context,
      String message,
      ) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
          behavior:
          SnackBarBehavior.floating,
          backgroundColor:
          Colors.blue,
          duration:
          const Duration(
            seconds: 2,
          ),
        ),
      );
  }

  // =========================================================
  // SHOW WARNING
  // =========================================================

  static void showWarning(
      BuildContext context,
      String message,
      ) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
          ),
          behavior:
          SnackBarBehavior.floating,
          backgroundColor:
          Colors.orange,
          duration:
          const Duration(
            seconds: 3,
          ),
        ),
      );
  }
}