import 'package:flutter/material.dart';

enum SnackBarType { error, success, info, warning }

class CustomSnackBar {
  static void show(BuildContext context, {
    required String message, 
    String? title, 
    bool isError = true, // Kept for backward compatibility, but 'type' is preferred
    SnackBarType? type,
  }) {
    // Determine type: specific type overrides legacy isError
    final effectiveType = type ?? (isError ? SnackBarType.error : SnackBarType.success);

    Color backgroundColor;
    IconData icon;
    String defaultTitle;

    switch (effectiveType) {
      case SnackBarType.success:
        backgroundColor = Colors.green.shade600;
        icon = Icons.check_circle_outline;
        defaultTitle = "Success";
        break;
      case SnackBarType.info:
        backgroundColor = const Color(0xFF2196F3); // Blue
        icon = Icons.info_outline;
        defaultTitle = "Info";
        break;
      case SnackBarType.warning:
        backgroundColor = const Color(0xFFFF9800); // Amber/Orange
        icon = Icons.warning_amber_rounded;
        defaultTitle = "Warning";
        break;
      case SnackBarType.error:
        backgroundColor = Colors.redAccent.shade700;
        icon = Icons.error_outline;
        defaultTitle = "Error";
    }

    // Clear any existing SnackBars to show the new one immediately
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(
                    title ?? defaultTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        margin: const EdgeInsets.all(20),
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}








