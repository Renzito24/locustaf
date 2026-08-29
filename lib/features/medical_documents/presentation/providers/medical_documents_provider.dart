import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/data_providers.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../../data/models/medical_document_model.dart';
import '../../data/repositories/medical_document_repository_impl.dart';
import '../../domain/repositories/medical_document_repository.dart';

final medicalDocumentRepositoryProvider = Provider<MedicalDocumentRepository>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  final companyId = ref.watch(currentCompanyIdProvider);
  final role = ref.watch(userRoleProvider);
  final userId = ref.watch(currentUserProvider)?.uid;
  return MedicalDocumentRepositoryImpl(
    firestoreService,
    companyId: companyId,
    userId: userId,
    role: role,
  );
});

final medicalDocumentsStreamProvider = StreamProvider<List<MedicalDocumentModel>>((ref) {
  final repo = ref.read(medicalDocumentRepositoryProvider);
  return repo.getDocuments();
});

class MedicalDocumentsFilterState {
  final String searchQuery;
  final String? employeeId;
  final MedicalDocumentTipo? tipo;
  final VigenciaEstado? vigencia;

  const MedicalDocumentsFilterState({
    this.searchQuery = '',
    this.employeeId,
    this.tipo,
    this.vigencia,
  });

  MedicalDocumentsFilterState copyWith({
    String? searchQuery,
    String? employeeId,
    MedicalDocumentTipo? tipo,
    VigenciaEstado? vigencia,
    bool clearTipo = false,
    bool clearVigencia = false,
  }) {
    return MedicalDocumentsFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      employeeId: employeeId ?? this.employeeId,
      tipo: clearTipo ? null : (tipo ?? this.tipo),
      vigencia: clearVigencia ? null : (vigencia ?? this.vigencia),
    );
  }
}

class MedicalDocumentsFilterNotifier extends Notifier<MedicalDocumentsFilterState> {
  @override
  MedicalDocumentsFilterState build() => const MedicalDocumentsFilterState();

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value.trim().toLowerCase());
  }

  void setEmployeeId(String? id) {
    state = state.copyWith(employeeId: id);
  }

  void setTipo(MedicalDocumentTipo? tipo) {
    state = state.copyWith(tipo: tipo, clearTipo: tipo == null);
  }

  void setVigencia(VigenciaEstado? vigencia) {
    state = state.copyWith(vigencia: vigencia, clearVigencia: vigencia == null);
  }

  void clear() {
    state = const MedicalDocumentsFilterState();
  }
}

final medicalDocumentsFilterProvider = NotifierProvider<MedicalDocumentsFilterNotifier, MedicalDocumentsFilterState>(
  MedicalDocumentsFilterNotifier.new,
);

final filteredMedicalDocumentsProvider = Provider<List<MedicalDocumentModel>>((ref) {
  final docsAsync = ref.watch(medicalDocumentsStreamProvider);
  final usersAsync = ref.watch(usersStreamProvider);
  final filter = ref.watch(medicalDocumentsFilterProvider);

  final docs = docsAsync.value ?? [];
  final users = usersAsync.value ?? [];

  final userMap = {for (final u in users) u.id: u};

  List<MedicalDocumentModel> filtered = docs.where((d) => d.isActive).toList();

  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery;
    filtered = filtered.where((d) {
      final user = userMap[d.userId];
      if (user == null) return false;
      return user.nombre.toLowerCase().contains(q) ||
          user.apellido.toLowerCase().contains(q) ||
          d.tipo.label.toLowerCase().contains(q);
    }).toList();
  }

  if (filter.employeeId != null) {
    filtered = filtered.where((d) => d.userId == filter.employeeId).toList();
  }

  if (filter.tipo != null) {
    filtered = filtered.where((d) => d.tipo == filter.tipo).toList();
  }

  if (filter.vigencia != null) {
    filtered = filtered.where((d) => d.vigencia == filter.vigencia).toList();
  }

  filtered.sort((a, b) => a.fechaFin.compareTo(b.fechaFin));

  return filtered;
});

final totalMedicalDocumentsProvider = Provider<int>((ref) {
  return ref.watch(filteredMedicalDocumentsProvider).length;
});

final vigentesCountProvider = Provider<int>((ref) {
  return ref.watch(filteredMedicalDocumentsProvider).where((d) => d.vigencia == VigenciaEstado.vigente).length;
});

final proximosAVencerCountProvider = Provider<int>((ref) {
  return ref.watch(filteredMedicalDocumentsProvider).where((d) => d.vigencia == VigenciaEstado.proximoAVencer).length;
});

final vencidosCountProvider = Provider<int>((ref) {
  return ref.watch(filteredMedicalDocumentsProvider).where((d) => d.vigencia == VigenciaEstado.vencido).length;
});

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
      state = MedicalDocumentActionState(error: e.toString());
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
      state = MedicalDocumentActionState(error: e.toString());
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

class MedicalDocumentDeleteNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> softDelete(String id, {String? archivoUrl}) async {
    state = const AsyncLoading();
    final repo = ref.read(medicalDocumentRepositoryProvider);

    try {
      // 1. Firestore primero (soft-delete es reversible)
      await repo.softDeleteDocument(id);

      // 2. Storage después (deleteFile ya es tolerante a fallos)
      if (archivoUrl != null) {
        final storageService = ref.read(storageServiceProvider);
        await storageService.deleteFile(archivoUrl);
      }

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final medicalDocumentDeleteProvider = AsyncNotifierProvider<MedicalDocumentDeleteNotifier, void>(
  MedicalDocumentDeleteNotifier.new,
);

// ─── Approval Notifier ──────────────────────────────────────────────────────

class MedicalDocumentApprovalNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> approve(String id) async {
    state = const AsyncLoading();
    final repo = ref.read(medicalDocumentRepositoryProvider);
    final reviewerId = ref.read(currentUserProvider)?.uid;
    try {
      await repo.updateEstado(
        id,
        estado: MedicalDocumentEstado.aprobado,
        reviewedBy: reviewerId,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> reject(String id, {required String observacion}) async {
    state = const AsyncLoading();
    final repo = ref.read(medicalDocumentRepositoryProvider);
    final reviewerId = ref.read(currentUserProvider)?.uid;
    try {
      await repo.updateEstado(
        id,
        estado: MedicalDocumentEstado.rechazado,
        observacionRechazo: observacion,
        reviewedBy: reviewerId,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final medicalDocumentApprovalProvider = AsyncNotifierProvider<MedicalDocumentApprovalNotifier, void>(
  MedicalDocumentApprovalNotifier.new,
);
