abstract class DomainException implements Exception {
  final String message;
  DomainException(this.message);

  @override
  String toString() => message;
}

class LocationOutOfRangeException extends DomainException {
  LocationOutOfRangeException(super.message);
}

class LocationAccuracyException extends DomainException {
  LocationAccuracyException(super.message);
}

class LocationPermissionException extends DomainException {
  LocationPermissionException(super.message);
}

class LocationDisabledException extends DomainException {
  LocationDisabledException(super.message);
}

class FileSizeException extends DomainException {
  FileSizeException(super.message);
}

class FileFormatException extends DomainException {
  FileFormatException(super.message);
}
