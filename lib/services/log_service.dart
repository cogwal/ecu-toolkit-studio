import 'dart:async';

/// Log severity levels
enum LogLevel { debug, info, warning, error }

/// A single log entry with timestamp, level, and message
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;

  LogEntry({required this.timestamp, required this.level, required this.message});

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }
}

/// Singleton service to manage application logs
class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  static const int _maxLogs = 1000;

  final List<LogEntry> _logs = [];
  final StreamController<LogEntry> _logController = StreamController<LogEntry>.broadcast();

  /// All stored log entries
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// Stream of new log entries for real-time updates
  Stream<LogEntry> get logStream => _logController.stream;

  /// Add a log entry with the specified level and message
  void log(LogLevel level, String message) {
    final entry = LogEntry(timestamp: DateTime.now(), level: level, message: message);

    _logs.add(entry);

    // Limit stored logs to prevent memory issues
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    _logController.add(entry);
  }

  /// Log an info message
  void info(String message) => log(LogLevel.info, message);

  /// Log a warning message
  void warning(String message) => log(LogLevel.warning, message);

  /// Log an error message
  void error(String message) => log(LogLevel.error, message);

  /// Log a debug message
  void debug(String message) => log(LogLevel.debug, message);

  /// Clear all stored logs
  void clear() {
    _logs.clear();
  }
}
