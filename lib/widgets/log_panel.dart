import 'dart:async';
import 'package:flutter/material.dart';
import '../services/log_service.dart';

/// A panel that displays log output with a header bar and scrollable list
class LogPanel extends StatefulWidget {
  final VoidCallback onClose;
  final double height;

  const LogPanel({super.key, required this.onClose, this.height = 200});

  @override
  State<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<LogPanel> {
  final LogService _logService = LogService();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<LogEntry>? _subscription;
  List<LogEntry> _logs = [];

  @override
  void initState() {
    super.initState();
    _logs = List.from(_logService.logs);
    _subscription = _logService.logStream.listen((entry) {
      setState(() {
        _logs = List.from(_logService.logs);
      });
      // Auto-scroll to bottom on new entry
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
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

  Color _getColorForLevel(LogLevel level, Brightness brightness) {
    switch (level) {
      case LogLevel.debug:
        return brightness == Brightness.dark ? Colors.grey : Colors.grey.shade600;
      case LogLevel.info:
        return brightness == Brightness.dark ? Colors.lightBlue : Colors.blue;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bgColor = brightness == Brightness.dark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final headerColor = brightness == Brightness.dark ? const Color(0xFF2D2D2D) : const Color(0xFFE0E0E0);
    final textColor = brightness == Brightness.dark ? const Color(0xFFCCCCCC) : const Color(0xFF333333);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          // Header bar
          Container(
            height: 28,
            color: headerColor,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.terminal, size: 14),
                const SizedBox(width: 8),
                Text(
                  'Output',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor),
                ),
                const Spacer(),
                // Clear button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.delete_outline, size: 16, color: textColor),
                  tooltip: 'Clear Output',
                  onPressed: () {
                    _logService.clear();
                    setState(() {
                      _logs = [];
                    });
                  },
                ),
                const SizedBox(width: 8),
                // Close button
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(Icons.close, size: 16, color: textColor),
                  tooltip: 'Close Panel',
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          // Log list
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Text('No output yet', style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12)),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final entry = _logs[index];
                      final levelColor = _getColorForLevel(entry.level, brightness);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(_getIconForLevel(entry.level), size: 14, color: levelColor),
                            const SizedBox(width: 8),
                            Text(
                              '[${entry.formattedTime}]',
                              style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: textColor.withOpacity(0.6)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                entry.message,
                                style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: textColor),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
