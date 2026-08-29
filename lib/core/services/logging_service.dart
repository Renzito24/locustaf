import 'package:flutter/foundation.dart';

/// Niveles de severidad para el logging.
enum LogLevel { debug, info, warning, error }

/// Servicio de logging centralizado.
///
/// En desarrollo imprime en consola con `debugPrint`. En producción puede
/// conectarse a un servicio externo (Sentry, etc.) sin cambiar los call sites.
class LoggingService {
  LoggingService._();

  static final LoggingService instance = LoggingService._();

  /// Nivel mínimo que se registra. En producción se puede subir a `warning`
  /// para reducir ruido.
  LogLevel minLevel = kDebugMode ? LogLevel.debug : LogLevel.warning;

  void debug(String message, {String? tag}) =>
      _log(LogLevel.debug, message, tag: tag);

  void info(String message, {String? tag}) =>
      _log(LogLevel.info, message, tag: tag);

  void warning(String message, {String? tag, Object? error}) =>
      _log(LogLevel.warning, message, tag: tag, error: error);

  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) =>
      _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < minLevel.index) return;

    final prefix = _prefixFor(level);
    final tagPart = tag != null ? '[$tag] ' : '';
    final errorPart = error != null ? ' | error: $error' : '';

    // En producción, aquí se enviaría a un servicio externo (Sentry, etc.).
    debugPrint('$prefix $tagPart$message$errorPart');

    if (level == LogLevel.error && stackTrace != null) {
      debugPrint('$prefix StackTrace: $stackTrace');
    }
  }

  String _prefixFor(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '[DEBUG]';
      case LogLevel.info:
        return '[INFO]';
      case LogLevel.warning:
        return '[WARN]';
      case LogLevel.error:
        return '[ERROR]';
    }
  }
}
