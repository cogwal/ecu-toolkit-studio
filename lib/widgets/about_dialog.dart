import 'package:flutter/material.dart';
import '../native/ecu_models.dart';

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
            Text('TTC Toolkit Version: ${getTtctkVersionFromNative()}'),
            const SizedBox(height: 8),
            const Text('A ECU tooling studio.'),
            const SizedBox(height: 8),
            const Text('Author: Sander Walstock'),
            // TTCTK Version from native library
            FutureBuilder<String>(
              future: Future.value(getTtctkVersionFromNative()),
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
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }
}
