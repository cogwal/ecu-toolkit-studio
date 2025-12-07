import 'package:flutter/material.dart';
import '../widgets/about_dialog.dart';
import '../services/log_service.dart';

class SettingsPage extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const SettingsPage({super.key, required this.isDark, required this.onToggleTheme});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final logService = LogService();

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
                    color: widget.isDark ? Theme.of(context).primaryColor : Theme.of(context).iconTheme.color,
                    tooltip: 'Switch to dark theme',
                    onPressed: () {
                      if (!widget.isDark) widget.onToggleTheme();
                    },
                  ),
                  Switch(value: !widget.isDark, onChanged: (v) => widget.onToggleTheme()),
                  IconButton(
                    icon: Icon(Icons.light_mode),
                    color: !widget.isDark ? Theme.of(context).primaryColor : Theme.of(context).iconTheme.color,
                    tooltip: 'Switch to light theme',
                    onPressed: () {
                      if (widget.isDark) widget.onToggleTheme();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Text('Log Level', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 16),
                  Text('Show messages at or above:', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
                  const Spacer(),
                  DropdownButton<LogLevel>(
                    value: logService.minLogLevel,
                    underline: Container(),
                    items: LogLevel.values.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getIconForLevel(level), size: 16, color: _getColorForLevel(level)),
                            const SizedBox(width: 8),
                            Text(_getLabelForLevel(level)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (level) {
                      if (level != null) {
                        setState(() {
                          logService.minLogLevel = level;
                        });
                        LogService().info('Log level changed to ${_getLabelForLevel(level)}');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(leading: const Icon(Icons.info_outline), title: const Text('About'), onTap: () => AboutDialogWidget.show(context)),
          ),
        ],
      ),
    );
  }

  String _getLabelForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'Debug';
      case LogLevel.info:
        return 'Info';
      case LogLevel.warning:
        return 'Warning';
      case LogLevel.error:
        return 'Error';
    }
  }

  IconData _getIconForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Icons.bug_report;
      case LogLevel.info:
        return Icons.info_outline;
      case LogLevel.warning:
        return Icons.warning_amber;
      case LogLevel.error:
        return Icons.error_outline;
    }
  }

  Color _getColorForLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Colors.grey;
      case LogLevel.info:
        return Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }
}
