import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../employees/presentation/providers/users_provider.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/models/incidence_model.dart';
import '../../data/repositories/incidence_repository_impl.dart';
import '../../domain/repositories/incidence_repository.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/providers/firebase_providers.dart';

final incidenceRepositoryProvider = Provider<IncidenceRepository>((ref) {
  final firestoreService = ref.read(firestoreServiceProvider);
  final companyId = ref.watch(currentCompanyIdProvider);
  final role = ref.watch(userRoleProvider);
  final userId = ref.watch(currentUserProvider)?.uid;
  return IncidenceRepositoryImpl(
    firestoreService,
    companyId: companyId,
    userId: userId,
    role: role,
  );
});

final incidencesStreamProvider = StreamProvider<List<IncidenceModel>>((ref) {
  final repo = ref.read(incidenceRepositoryProvider);
  return repo.getIncidences();
});

class IncidencesFilterState {
  final String searchQuery;
  final String? employeeId;
  final IncidenceType? type;
  final IncidenceEstado? state;

  const IncidencesFilterState({
    this.searchQuery = '',
    this.employeeId,
    this.type,
    this.state,
  });

  IncidencesFilterState copyWith({
    String? searchQuery,
    String? employeeId,
    IncidenceType? type,
    IncidenceEstado? state,
    bool clearType = false,
    bool clearState = false,
  }) {
    return IncidencesFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      employeeId: employeeId ?? this.employeeId,
      type: clearType ? null : (type ?? this.type),
      state: clearState ? null : (state ?? this.state),
    );
  }
}

class IncidencesFilterNotifier extends Notifier<IncidencesFilterState> {
  @override
  IncidencesFilterState build() => const IncidencesFilterState();

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value.trim().toLowerCase());
  }

  void setEmployeeId(String? id) {
    state = state.copyWith(employeeId: id);
  }

  void setType(IncidenceType? type) {
    state = state.copyWith(type: type, clearType: type == null);
  }

  void setState(IncidenceEstado? stateValue) {
    state = state.copyWith(state: stateValue, clearState: stateValue == null);
  }

  void clear() {
    state = const IncidencesFilterState();
  }
}

final incidencesFilterProvider = NotifierProvider<IncidencesFilterNotifier, IncidencesFilterState>(
  IncidencesFilterNotifier.new,
);

final filteredIncidencesProvider = Provider<List<IncidenceModel>>((ref) {
  final incidencesAsync = ref.watch(incidencesStreamProvider);
  final usersAsync = ref.watch(usersStreamProvider);
  final filter = ref.watch(incidencesFilterProvider);

  final incidences = incidencesAsync.value ?? [];
  final users = usersAsync.value ?? [];

  final userMap = {for (final u in users) u.id: u};

  List<IncidenceModel> filtered = incidences.where((i) => i.isActive).toList();

  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery;
    filtered = filtered.where((i) {
      final user = userMap[i.userId];
      if (user == null) return false;
      return user.nombre.toLowerCase().contains(q) ||
          user.apellido.toLowerCase().contains(q) ||
          i.type.label.toLowerCase().contains(q);
    }).toList();
  }

  if (filter.employeeId != null) {
    filtered = filtered.where((i) => i.userId == filter.employeeId).toList();
  }

  if (filter.type != null) {
    filtered = filtered.where((i) => i.type == filter.type).toList();
  }

  if (filter.state != null) {
    filtered = filtered.where((i) => i.estado == filter.state).toList();
  }

  filtered.sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));

  return filtered;
});

final totalIncidencesProvider = Provider<int>((ref) {
  return ref.watch(filteredIncidencesProvider).length;
});

final programadasCountProvider = Provider<int>((ref) {
  return ref.watch(filteredIncidencesProvider).where((i) => i.state == IncidenceState.programada).length;
});

final enCursoCountProvider = Provider<int>((ref) {
  return ref.watch(filteredIncidencesProvider).where((i) => i.state == IncidenceState.enCurso).length;
});

final finalizadasCountProvider = Provider<int>((ref) {
  return ref.watch(filteredIncidencesProvider).where((i) => i.state == IncidenceState.finalizada).length;
});

class IncidenceCreateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> createIncidence(IncidenceModel incidence) async {
    state = const AsyncLoading();
    final repo = ref.read(incidenceRepositoryProvider);
    try {
      await repo.createIncidence(incidence);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final incidenceCreateProvider = AsyncNotifierProvider<IncidenceCreateNotifier, void>(
  IncidenceCreateNotifier.new,
);

class IncidenceUpdateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> updateIncidence(IncidenceModel incidence) async {
    state = const AsyncLoading();
    final repo = ref.read(incidenceRepositoryProvider);
    try {
      await repo.updateIncidence(incidence);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final incidenceUpdateProvider = AsyncNotifierProvider<IncidenceUpdateNotifier, void>(
  IncidenceUpdateNotifier.new,
);

class IncidenceDeleteNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> softDelete(String id) async {
    state = const AsyncLoading();
    final repo = ref.read(incidenceRepositoryProvider);
    try {
      await repo.softDeleteIncidence(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final incidenceDeleteProvider = AsyncNotifierProvider<IncidenceDeleteNotifier, void>(
  IncidenceDeleteNotifier.new,
);

class IncidenceApprovalNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> approve(String id) async {
    state = const AsyncLoading();
    final repo = ref.read(incidenceRepositoryProvider);
    try {
      await repo.updateEstado(id, estado: IncidenceEstado.aprobado);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> reject(String id, {required String observacion}) async {
    state = const AsyncLoading();
    final repo = ref.read(incidenceRepositoryProvider);
    try {
      await repo.updateEstado(
        id,
        estado: IncidenceEstado.rechazado,
        observacionRechazo: observacion,
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

final incidenceApprovalProvider = AsyncNotifierProvider<IncidenceApprovalNotifier, void>(
  IncidenceApprovalNotifier.new,
);
