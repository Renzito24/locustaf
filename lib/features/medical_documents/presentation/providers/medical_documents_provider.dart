import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../employees/presentation/providers/users_provider.dart';
import '../../data/models/medical_document_model.dart';
import '../../data/repositories/medical_document_repository_impl.dart';
import '../../domain/repositories/medical_document_repository.dart';
import '../../../../core/services/firestore_service.dart';

final _firestoreService = FirestoreService(FirebaseFirestore.instance);

final medicalDocumentRepositoryProvider = Provider<MedicalDocumentRepository>((ref) {
  return MedicalDocumentRepositoryImpl(_firestoreService);
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

class MedicalDocumentCreateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> createDocument(MedicalDocumentModel document) async {
    state = const AsyncLoading();
    final repo = ref.read(medicalDocumentRepositoryProvider);
    try {
      await repo.createDocument(document);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final medicalDocumentCreateProvider = AsyncNotifierProvider<MedicalDocumentCreateNotifier, void>(
  MedicalDocumentCreateNotifier.new,
);

class MedicalDocumentUpdateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> updateDocument(MedicalDocumentModel document) async {
    state = const AsyncLoading();
    final repo = ref.read(medicalDocumentRepositoryProvider);
    try {
      await repo.updateDocument(document);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final medicalDocumentUpdateProvider = AsyncNotifierProvider<MedicalDocumentUpdateNotifier, void>(
  MedicalDocumentUpdateNotifier.new,
);

class MedicalDocumentDeleteNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> softDelete(String id) async {
    state = const AsyncLoading();
    final repo = ref.read(medicalDocumentRepositoryProvider);
    try {
      await repo.softDeleteDocument(id);
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
