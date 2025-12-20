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
  final StreamController<LogLevel> _minLogLevelController = StreamController<LogLevel>.broadcast();

  /// Minimum log level to display (default: info)
  LogLevel _minLogLevel = LogLevel.info;

  /// Get the current minimum log level
  LogLevel get minLogLevel => _minLogLevel;

  /// Set the minimum log level and notify listeners
  set minLogLevel(LogLevel level) {
    _minLogLevel = level;
    _minLogLevelController.add(level);
  }

  /// Stream of log level changes for real-time updates
  Stream<LogLevel> get minLogLevelStream => _minLogLevelController.stream;

  /// All stored log entries
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// Filtered log entries based on minimum log level
  List<LogEntry> get filteredLogs => _logs.where((e) => e.level.index >= _minLogLevel.index).toList();

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
