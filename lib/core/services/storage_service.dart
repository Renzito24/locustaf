import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Tamaño máximo permitido por archivo: 10 MB.
const int kMaxFileSize = 10 * 1024 * 1024;

class StorageService {
  final FirebaseStorage _storage;

  StorageService(this._storage);

  /// Sube un archivo a Firebase Storage y retorna la URL de descarga.
  ///
  /// [path] es la ruta dentro del bucket (ej: medical_documents/{userId}/{docId}).
  /// [file] es el archivo seleccionado por el usuario.
  /// [onProgress] callback opcional que recibe el progreso 0.0 → 1.0.
  /// [maxSize] tamaño máximo en bytes (default: [kMaxFileSize]).
  ///
  /// Lanza [StorageServiceException] si el archivo supera [maxSize].
  Future<String> uploadFile({
    required String path,
    required PlatformFile file,
    void Function(double progress)? onProgress,
    int maxSize = kMaxFileSize,
  }) async {
    if (file.size > maxSize) {
      final mb = (maxSize / (1024 * 1024)).toStringAsFixed(0);
      throw StorageServiceException(
        'El archivo supera el límite de $mb MB. Seleccioná un archivo más pequeño.',
      );
    }

    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(
      contentType: _contentTypeFromExtension(file.extension),
    );

    final UploadTask uploadTask;

    if (file.bytes != null) {
      uploadTask = ref.putData(file.bytes!, metadata);
    } else if (file.path != null) {
      uploadTask = ref.putFile(File(file.path!), metadata);
    } else {
      throw StorageServiceException('El archivo no tiene datos ni ruta disponible.');
    }

    final streamSub = uploadTask.snapshotEvents.listen((snapshot) {
      if (snapshot.totalBytes > 0) {
        onProgress?.call(snapshot.bytesTransferred / snapshot.totalBytes);
      }
    });

    try {
      await uploadTask;
      return await ref.getDownloadURL();
    } finally {
      await streamSub.cancel();
    }
  }

  /// Elimina un archivo de Firebase Storage a partir de su URL de descarga.
  /// No lanza error si el archivo no existe (silencio seguro).
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } on FirebaseException catch (_) {
      // Ignorar si el archivo ya no existe
    }
  }

  /// Descarga el contenido de un archivo de Firebase Storage a memoria.
  ///
  /// La descarga se hace con el SDK autenticado en lugar de una petición HTTP
  /// directa a la URL: el bucket no envía cabeceras CORS, así que en web
  /// `Image.network` / `http.get` fallan. Además valida las reglas de Storage
  /// (la URL con token no las atraviesa).
  Future<Uint8List> readFileBytes(String downloadUrl) async {
    final ref = _storage.refFromURL(downloadUrl);
    final bytes = await ref.getData();
    if (bytes == null) {
      throw StorageServiceException('El archivo no se pudo descargar.');
    }
    return bytes;
  }

  String _contentTypeFromExtension(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}

class StorageServiceException implements Exception {
  final String message;
  const StorageServiceException(this.message);

  @override
  String toString() => message;
}
