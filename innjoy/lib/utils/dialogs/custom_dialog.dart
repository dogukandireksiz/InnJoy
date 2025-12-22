import 'package:flutter/material.dart';

class CustomDialog {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDanger = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDanger ? Colors.red.shade50 : Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDanger ? Icons.warning_amber_rounded : Icons.info_outline,
                color: isDanger ? Colors.red : Colors.blue,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(cancelText, style: const TextStyle(fontSize: 15)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? Colors.red : const Color(0xFF1677FF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(confirmText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}








