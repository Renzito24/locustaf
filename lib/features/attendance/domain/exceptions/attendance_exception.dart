class AttendanceException implements Exception {
  final String message;
  const AttendanceException(this.message);

  @override
  String toString() => message;
}
