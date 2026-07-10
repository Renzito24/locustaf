class MedicalDocumentException implements Exception {
  final String message;
  const MedicalDocumentException(this.message);

  @override
  String toString() => message;
}
