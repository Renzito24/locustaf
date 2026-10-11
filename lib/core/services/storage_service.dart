import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import 'file_exists.dart';
import 'web_download.dart';

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
  Future<void> deleteFile(String pathOrUrl) async {
    try {
      final ref = pathOrUrl.startsWith('http') || pathOrUrl.startsWith('gs://')
          ? _storage.refFromURL(pathOrUrl)
          : _storage.ref().child(pathOrUrl);
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
  Future<Uint8List> readFileBytes(String pathOrUrl) async {
    final ref = pathOrUrl.startsWith('http') || pathOrUrl.startsWith('gs://')
        ? _storage.refFromURL(pathOrUrl)
        : _storage.ref().child(pathOrUrl);
    final bytes = await ref.getData();
    if (bytes == null) {
      throw StorageServiceException('El archivo no se pudo descargar.');
    }
    return bytes;
  }

  /// Obtiene la URL de descarga firmada de un archivo de Firebase Storage.
  ///
  /// Es el fallback para Web cuando la descarga de bytes falla (p. ej. por
  /// políticas CORS del bucket): permite abrir el documento en una pestaña
  /// nueva con `url_launcher`.
  Future<String> getDownloadUrl(String pathOrUrl) async {
    final ref = pathOrUrl.startsWith('http') || pathOrUrl.startsWith('gs://')
        ? _storage.refFromURL(pathOrUrl)
        : _storage.ref().child(pathOrUrl);
    return ref.getDownloadURL();
  }

  /// Sentinel que file_saver devuelve en web cuando el guardado del blob
  /// se completó; y la marca de "no guardó nada" en desktop al cancelar el
  /// diálogo nativo (misma convención que ReportExporter).
  static const String _webDownloadSentinel = 'Downloads';
  static const String _noSaveSentinel = 'Something went wrong';

  /// Descarga [pathOrUrl] con la estrategia correcta para cada plataforma:
  ///
  /// - Web con bytes en memoria: descarga del blob con FileSaver.
  /// - Web sin bytes (la lectura falla por CORS del bucket): descarga con la
  ///   URL firmada vía un ancla con atributo `download` — es una navegación
  ///   directa del navegador, no pasa por CORS, por eso funciona.
  /// - Android/iOS: `FilePicker.saveFile` (SAF) para que el archivo quede en la
  ///   ubicación visible que elige el usuario (FileSaver en móvil escribe en
  ///   un directorio privado — ver ReportExporter).
  /// - Desktop: FileSaver con verificación real del archivo en disco.
  ///
  /// Devuelve [DownloadOutcome.cancelled] si el usuario canceló el diálogo del
  /// sistema; [DownloadOutcome.downloaded] si la descarga quedó iniciada.
  /// Lanza error real si la escritura falló.
  Future<DownloadOutcome> downloadFile({
    required String pathOrUrl,
    required String fileName,
    Uint8List? existingBytes,
  }) async {
    Uint8List? bytes = existingBytes;
    if (bytes == null) {
      try {
        bytes = await readFileBytes(pathOrUrl);
      } catch (e) {
        if (!kIsWeb) rethrow;
        // Web: la lectura de bytes puede fallar por CORS del bucket. La
        // descarga se hace igual con la URL firmada vía ancla (sin CORS).
        bytes = null;
      }
    }

    if (kIsWeb) {
      if (bytes != null) {
        final result = await FileSaver.instance.saveFile(
          name: fileName,
          bytes: bytes,
          ext: 'pdf',
          mimeType: MimeType.pdf,
        );
        if (result == _webDownloadSentinel) {
          return DownloadOutcome.downloaded;
        }
        throw StateError('No se pudo completar la descarga del archivo.');
      }
      final url = await getDownloadUrl(pathOrUrl);
      downloadViaAnchor(url, fileName);
      return DownloadOutcome.downloaded;
    }

    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (isMobile) {
      // El usuario elige el destino del sistema; null = canceló.
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar recibo',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );
      return mobileOutcome(path);
    }

    final result = await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes!,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
    if (result.startsWith(_noSaveSentinel)) {
      return DownloadOutcome.cancelled;
    }
    if (!fileExistsOnDisk(result)) {
      throw StateError('No se pudo guardar el archivo en la ubicación elegida.');
    }
    return DownloadOutcome.downloaded;
  }

  /// Semántica del resultado de `FilePicker.saveFile` en móviles: `null`
  /// significa que el usuario canceló; `path != null` significa que el sistema
  /// SAF escribió el archivo (función pura, testeable).
  static DownloadOutcome mobileOutcome(String? path) {
    return path == null
        ? DownloadOutcome.cancelled
        : DownloadOutcome.downloaded;
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

/// Resultado de [StorageService.downloadFile].
enum DownloadOutcome { downloaded, cancelled }

class StorageServiceException implements Exception {
  final String message;
  const StorageServiceException(this.message);

  @override
  String toString() => message;
}
