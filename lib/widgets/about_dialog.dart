import 'package:flutter/material.dart';
import '../native/ecu_models.dart';
import '../native/ttctk.dart';

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
            // TTCTK Version from native library
            FutureBuilder<String>(
              future: Future.value(TTCTK.instance.getVersionString()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('TTC Toolkit Version: Loading...');
                } else if (snapshot.hasError) {
                  return Text('TTC Toolkit Version: Error - ${snapshot.error}');
                } else {
                  return Text('TTC Toolkit Version: ${snapshot.data}');
                }
              },
            ),
            const SizedBox(height: 8),
            const Text('Author: Sander Walstock'),

          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}
