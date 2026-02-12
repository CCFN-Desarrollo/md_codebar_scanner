import 'package:flutter/material.dart';
import 'package:md_codebar_scanner/utils/colors.dart';

class MessageUtils {
  static void showSuccessMessage(BuildContext context, String message) {
    _showMessage(context, message, AppColors.success, Icons.check_circle, 2);
  }

  static void showErrorMessage(BuildContext context, String message) {
    _showMessage(context, message, AppColors.error, Icons.error_outline, 4);
  }

  static void _showMessage(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
    int durationInSeconds,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: durationInSeconds),
      ),
    );
  }
}
