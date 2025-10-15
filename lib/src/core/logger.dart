import 'dart:developer' as developer;

/// Internal logger for the agentic architecture package.
///
/// This logger is used internally and can be enabled/disabled.
/// It uses dart:developer log instead of print for production compatibility.
class AgenticLogger {
  final String name;
  final bool enabled;

  const AgenticLogger({
    required this.name,
    this.enabled = false,
  });

  /// Logs a message if logging is enabled.
  void log(String message, {String? level}) {
    if (!enabled) return;

    developer.log(
      message,
      name: name,
      level: _levelToInt(level),
    );
  }

  /// Logs an info message.
  void info(String message) {
    log(message, level: 'INFO');
  }

  /// Logs a debug message.
  void debug(String message) {
    log(message, level: 'DEBUG');
  }

  /// Logs a warning message.
  void warning(String message) {
    log(message, level: 'WARNING');
  }

  /// Logs an error message.
  void error(String message) {
    log(message, level: 'ERROR');
  }

  int _levelToInt(String? level) {
    switch (level?.toUpperCase()) {
      case 'ERROR':
        return 1000;
      case 'WARNING':
        return 900;
      case 'INFO':
        return 800;
      case 'DEBUG':
        return 700;
      default:
        return 800;
    }
  }
}

