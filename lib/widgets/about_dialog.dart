import 'package:flutter/material.dart';

class AboutDialogWidget {
  static Future<void> show(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About ECU Toolkit Studio'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Version: 0.1.0'),
            const SizedBox(height: 8),
            const Text('A simple ECU tooling studio for diagnostics, live data and flashing.'),
            const SizedBox(height: 8),
            const Text('Author: cogwal'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}
