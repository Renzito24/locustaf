import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/async_action_state.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/models/medical_document_model.dart';
import 'medical_documents_provider.dart';

// ─── Estados de acción ──────────────────────────────────────────────────────

class MedicalDocumentActionState {
  final bool isLoading;
  final double uploadProgress;
  final String? error;

  const MedicalDocumentActionState({
    this.isLoading = false,
    this.uploadProgress = 0,
    this.error,
  });

  bool get hasError => error != null;

  const MedicalDocumentActionState.idle() : this();
}

// ─── Create Notifier ────────────────────────────────────────────────────────

class MedicalDocumentCreateNotifier extends Notifier<MedicalDocumentActionState> {
  @override
  MedicalDocumentActionState build() => const MedicalDocumentActionState.idle();

  Future<void> createDocument({
    required MedicalDocumentModel document,
    PlatformFile? file,
  }) async {
    state = MedicalDocumentActionState(isLoading: true, uploadProgress: 0);

    final repo = ref.read(medicalDocumentRepositoryProvider);
    final storageService = ref.read(storageServiceProvider);
    final companyId = ref.read(currentCompanyIdProvider);
    String? uploadedUrl;
    String? mimeType;
    String? fileName;

    try {
      if (file != null) {
        final docId = ref.read(firestoreServiceProvider).generateId('medical_documents');
        final safeName = FileUtils.sanitizeFileName(file.name);
        final storagePath = 'companies/$companyId/medical_documents/${document.userId}/${docId}_$safeName';

        uploadedUrl = await storageService.uploadFile(
          path: storagePath,
          file: file,
          onProgress: (progress) {
            state = MedicalDocumentActionState(isLoading: true, uploadProgress: progress);
          },
        );
        mimeType = FileUtils.mimeTypeFromExtension(file.extension);
        fileName = safeName;
      }

      state = MedicalDocumentActionState(isLoading: true, uploadProgress: 1);

      final doc = document.copyWith(
        archivoUrl: uploadedUrl ?? document.archivoUrl,
        archivoNombre: fileName,
        mimeType: mimeType,
      );

      await repo.createDocument(doc);

      state = const MedicalDocumentActionState(isLoading: false, uploadProgress: 1);
    } on StorageServiceException catch (e) {
      // Upload falló — no hay nada que limpiar
      state = MedicalDocumentActionState(error: e.message);
    } catch (e) {
      // Si subió el archivo pero Firestore falló → rollback: eliminar archivo
      if (uploadedUrl != null) {
        try {
          await storageService.deleteFile(uploadedUrl);
        } catch (_) {}
      }
      state = MedicalDocumentActionState(error: ErrorHandler.parse(e).message);
    }
  }

  void reset() {
    state = const MedicalDocumentActionState.idle();
  }
}

final medicalDocumentCreateProvider = NotifierProvider<MedicalDocumentCreateNotifier, MedicalDocumentActionState>(
  MedicalDocumentCreateNotifier.new,
);

// ─── Update Notifier ────────────────────────────────────────────────────────

class MedicalDocumentUpdateNotifier extends Notifier<MedicalDocumentActionState> {
  @override
  MedicalDocumentActionState build() => const MedicalDocumentActionState.idle();

  Future<void> updateDocument({
    required MedicalDocumentModel document,
    PlatformFile? file,
  }) async {
    state = MedicalDocumentActionState(isLoading: true, uploadProgress: 0);

    final repo = ref.read(medicalDocumentRepositoryProvider);
    final storageService = ref.read(storageServiceProvider);
    final companyId = ref.read(currentCompanyIdProvider);
    String? uploadedUrl;
    String? newFileName;
    String? newMimeType;

    try {
      if (file != null) {
        final docId = document.id.isEmpty
            ? ref.read(firestoreServiceProvider).generateId('medical_documents')
            : document.id;
        final safeName = FileUtils.sanitizeFileName(file.name);
        final storagePath = 'companies/$companyId/medical_documents/${document.userId}/${docId}_$safeName';

        // 1. Subir nuevo archivo primero
        uploadedUrl = await storageService.uploadFile(
          path: storagePath,
          file: file,
          onProgress: (progress) {
            state = MedicalDocumentActionState(isLoading: true, uploadProgress: progress);
          },
        );
        newFileName = safeName;
        newMimeType = FileUtils.mimeTypeFromExtension(file.extension);

        // 2. Eliminar archivo anterior (nuevo ya está seguro en Storage)
        if (document.archivoUrl != null) {
          await storageService.deleteFile(document.archivoUrl!);
        }
      }

      state = MedicalDocumentActionState(isLoading: true, uploadProgress: 1);

      final updated = document.copyWith(
        archivoUrl: uploadedUrl ?? document.archivoUrl,
        archivoNombre: newFileName ?? document.archivoNombre,
        mimeType: newMimeType ?? document.mimeType,
        updatedAt: DateTime.now(),
      );

      await repo.updateDocument(updated);

      state = const MedicalDocumentActionState(isLoading: false, uploadProgress: 1);
    } on StorageServiceException catch (e) {
      // Upload falló — no hay nada que limpiar (old file intacto)
      state = MedicalDocumentActionState(error: e.message);
    } catch (e) {
      // Rollback: si el nuevo archivo se subió pero Firestore falló, limpiarlo
      if (uploadedUrl != null) {
        try {
          await storageService.deleteFile(uploadedUrl);
        } catch (_) {}
      }
      state = MedicalDocumentActionState(error: ErrorHandler.parse(e).message);
    }
  }

  void reset() {
    state = const MedicalDocumentActionState.idle();
  }
}

final medicalDocumentUpdateProvider = NotifierProvider<MedicalDocumentUpdateNotifier, MedicalDocumentActionState>(
  MedicalDocumentUpdateNotifier.new,
);

// ─── Delete Notifier ────────────────────────────────────────────────────────

class MedicalDocumentDeleteNotifier extends Notifier<AsyncActionState> {
  @override
  AsyncActionState build() => const AsyncActionState.idle();

  Future<void> softDelete(String id, {String? archivoUrl}) async {
    state = const AsyncActionState.loading();
    final repo = ref.read(medicalDocumentRepositoryProvider);

    try {
      // 1. Firestore primero (soft-delete es reversible)
      await repo.softDeleteDocument(id);

      // 2. Storage después (deleteFile ya es tolerante a fallos)
      if (archivoUrl != null) {
        final storageService = ref.read(storageServiceProvider);
        await storageService.deleteFile(archivoUrl);
      }

      state = const AsyncActionState.success();
    } catch (e) {
      state = AsyncActionState.failure(ErrorHandler.parse(e).message);
    }
  }

  void reset() {
    state = const AsyncActionState.idle();
  }
}

final medicalDocumentDeleteProvider = NotifierProvider<MedicalDocumentDeleteNotifier, AsyncActionState>(
  MedicalDocumentDeleteNotifier.new,
);

// ─── Approval Notifier ──────────────────────────────────────────────────────

class MedicalDocumentApprovalNotifier extends Notifier<AsyncActionState> {
  @override
  AsyncActionState build() => const AsyncActionState.idle();

  Future<void> approve(String id) async {
    state = const AsyncActionState.loading();
    final repo = ref.read(medicalDocumentRepositoryProvider);
    final reviewerId = ref.read(currentUserIdProvider);
    try {
      await repo.updateEstado(
        id,
        estado: MedicalDocumentEstado.aprobado,
        reviewedBy: reviewerId,
      );
      LoggingService.instance.info(
        'Documento médico aprobado: $id',
        tag: 'medical_documents',
      );
      state = const AsyncActionState.success();
    } catch (e, st) {
      LoggingService.instance.error(
        'Error al aprobar documento médico: $id',
        tag: 'medical_documents',
        error: e,
        stackTrace: st,
      );
      state = AsyncActionState.failure(ErrorHandler.parse(e).message);
    }
  }

  Future<void> reject(String id, {required String observacion}) async {
    state = const AsyncActionState.loading();
    final repo = ref.read(medicalDocumentRepositoryProvider);
    final reviewerId = ref.read(currentUserIdProvider);
    try {
      await repo.updateEstado(
        id,
        estado: MedicalDocumentEstado.rechazado,
        observacionRechazo: observacion,
        reviewedBy: reviewerId,
      );
      LoggingService.instance.info(
        'Documento médico rechazado: $id',
        tag: 'medical_documents',
      );
      state = const AsyncActionState.success();
    } catch (e, st) {
      LoggingService.instance.error(
        'Error al rechazar documento médico: $id',
        tag: 'medical_documents',
        error: e,
        stackTrace: st,
      );
      state = AsyncActionState.failure(ErrorHandler.parse(e).message);
    }
  }

  void reset() {
    state = const AsyncActionState.idle();
  }
}

final medicalDocumentApprovalProvider = NotifierProvider<MedicalDocumentApprovalNotifier, AsyncActionState>(
  MedicalDocumentApprovalNotifier.new,
);
