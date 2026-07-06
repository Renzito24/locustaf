import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/workplace_model.dart';
import '../../data/repositories/workplace_repository_impl.dart';
import '../../domain/repositories/workplace_repository.dart';
import '../../../../core/services/firestore_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

final workplaceRepositoryProvider = Provider<WorkplaceRepository>((ref) {
  final svc = ref.read(firestoreServiceProvider);
  return WorkplaceRepositoryImpl(svc);
});

final workplacesStreamProvider = StreamProvider<List<WorkplaceModel>>((ref) {
  final repo = ref.read(workplaceRepositoryProvider);
  return repo.getWorkplaces();
});

final activeWorkplacesProvider = Provider<AsyncValue<List<WorkplaceModel>>>((ref) {
  final workplacesAsync = ref.watch(workplacesStreamProvider);
  return workplacesAsync.whenData(
    (list) => list.where((w) => w.isActive).toList(),
  );
});

class WorkplaceCreateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> createWorkplace(WorkplaceModel workplace) async {
    state = const AsyncLoading();
    final repo = ref.read(workplaceRepositoryProvider);
    try {
      await repo.createWorkplace(workplace);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final workplaceCreateProvider =
    AsyncNotifierProvider<WorkplaceCreateNotifier, void>(
  WorkplaceCreateNotifier.new,
);

class WorkplaceUpdateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> updateWorkplace(WorkplaceModel workplace) async {
    state = const AsyncLoading();
    final repo = ref.read(workplaceRepositoryProvider);
    try {
      await repo.updateWorkplace(workplace);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

final workplaceUpdateProvider =
    AsyncNotifierProvider<WorkplaceUpdateNotifier, void>(
  WorkplaceUpdateNotifier.new,
);

class WorkplaceDeleteNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> softDeleteWorkplace(String id) async {
    state = const AsyncLoading();
    final repo = ref.read(workplaceRepositoryProvider);
    try {
      await repo.softDeleteWorkplace(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }

  Future<void> reactivateWorkplace(String id) async {
    state = const AsyncLoading();
    final repo = ref.read(workplaceRepositoryProvider);
    try {
      await repo.reactivateWorkplace(id);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final workplaceDeleteProvider =
    AsyncNotifierProvider<WorkplaceDeleteNotifier, void>(
  WorkplaceDeleteNotifier.new,
);
