enum LogLevel {
  debug,
  info,
  warning,
  error,
  success,
  start,
  file,
  normal,
}

class LogInfo {
  final String message;
  final String timestamp;
  final LogLevel level;

  LogInfo({
    required this.message,
    String? timestamp, 
    LogLevel? level,   
  })  : timestamp = timestamp ?? DateTime.now().toString(), 
        level = level ?? LogLevel.normal; 

  @override
  String toString() {
    return '[${level.name}] $timestamp: $message';
  }
}