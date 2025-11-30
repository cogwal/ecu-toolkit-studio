import 'package:flutter/material.dart';
import '../widgets/about_dialog.dart';

class SettingsPage extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SettingsPage({super.key, required this.isDark, required this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Text('Theme', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  // Moon icon -> Switch -> Sun icon
                  IconButton(
                    icon: Icon(Icons.dark_mode),
                    color: isDark ? Theme.of(context).primaryColor : Theme.of(context).iconTheme.color,
                    tooltip: 'Switch to dark theme',
                    onPressed: () {
                      if (isDark) onToggleTheme();
                    },
                  ),
                  Switch(
                    value: !isDark,
                    onChanged: (v) => onToggleTheme(),
                  ),
                  IconButton(
                    icon: Icon(Icons.light_mode),
                    color: !isDark ? Theme.of(context).primaryColor : Theme.of(context).iconTheme.color,
                    tooltip: 'Switch to light theme',
                    onPressed: () {
                      if (!isDark) onToggleTheme();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About'),
              onTap: () => AboutDialogWidget.show(context),
            ),
          ),
        ],
      ),
    );
  }
}
