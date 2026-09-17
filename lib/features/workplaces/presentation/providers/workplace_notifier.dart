import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/workplace_model.dart';
import '../../data/repositories/workplace_repository_impl.dart';
import '../../domain/repositories/workplace_repository.dart';
import '../../../../core/providers/async_action_state.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/providers/firebase_providers.dart';

final workplaceRepositoryProvider = Provider<WorkplaceRepository>((ref) {
  final svc = ref.read(firestoreServiceProvider);
  final companyId = ref.watch(currentCompanyIdProvider);
  return WorkplaceRepositoryImpl(svc, companyId: companyId);
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

class WorkplaceCreateNotifier extends Notifier<AsyncActionState> {
  @override
  AsyncActionState build() => const AsyncActionState.idle();

  Future<void> createWorkplace(WorkplaceModel workplace) async {
    state = const AsyncActionState.loading();
    final repo = ref.read(workplaceRepositoryProvider);
    try {
      await repo.createWorkplace(workplace);
      state = const AsyncActionState.success();
    } catch (e) {
      state = AsyncActionState.failure(e);
    }
  }

  void reset() {
    state = const AsyncActionState.idle();
  }
}

final workplaceCreateProvider = NotifierProvider<WorkplaceCreateNotifier, AsyncActionState>(
  WorkplaceCreateNotifier.new,
);

class WorkplaceUpdateNotifier extends Notifier<AsyncActionState> {
  @override
  AsyncActionState build() => const AsyncActionState.idle();

  Future<void> updateWorkplace(WorkplaceModel workplace) async {
    state = const AsyncActionState.loading();
    final repo = ref.read(workplaceRepositoryProvider);
    try {
      await repo.updateWorkplace(workplace);
      state = const AsyncActionState.success();
    } catch (e) {
      state = AsyncActionState.failure(e);
    }
  }

  void reset() {
    state = const AsyncActionState.idle();
  }
}

final workplaceUpdateProvider = NotifierProvider<WorkplaceUpdateNotifier, AsyncActionState>(
  WorkplaceUpdateNotifier.new,
);

class WorkplaceDeleteNotifier extends Notifier<AsyncActionState> {
  @override
  AsyncActionState build() => const AsyncActionState.idle();

  Future<void> softDeleteWorkplace(String id) async {
    state = const AsyncActionState.loading();
    final repo = ref.read(workplaceRepositoryProvider);
    try {
      await repo.softDeleteWorkplace(id);
      state = const AsyncActionState.success();
    } catch (e) {
      state = AsyncActionState.failure(e);
    }
  }

  void reset() {
    state = const AsyncActionState.idle();
  }

  Future<void> reactivateWorkplace(String id) async {
    state = const AsyncActionState.loading();
    final repo = ref.read(workplaceRepositoryProvider);
    try {
      await repo.reactivateWorkplace(id);
      state = const AsyncActionState.success();
    } catch (e) {
      state = AsyncActionState.failure(e);
    }
  }
}

final workplaceDeleteProvider = NotifierProvider<WorkplaceDeleteNotifier, AsyncActionState>(
  WorkplaceDeleteNotifier.new,
);
