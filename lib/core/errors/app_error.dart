enum AppErrorType { functional, recoverable, permission, unexpected }

class AppError {
  final String title;
  final String message;
  final AppErrorType type;

  const AppError({
    required this.title,
    required this.message,
    required this.type,
  });
}
