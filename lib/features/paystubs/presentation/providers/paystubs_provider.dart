import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../domain/models/paystub_model.dart';
import '../../data/repositories/paystub_repository_impl.dart';
import '../../domain/repositories/paystub_repository.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/providers/async_action_state.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../core/services/stream_retry.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/file_utils.dart';

final paystubRepositoryProvider = Provider<PaystubRepository>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider) ?? '';
  final firestoreService = ref.read(firestoreServiceProvider);
  final role = ref.watch(userRoleProvider);
  final userId = ref.watch(currentUserIdProvider);
  return PaystubRepositoryImpl(
    firestoreService,
    companyId: companyId,
    userId: userId,
    role: role,
  );
});

final paystubsStreamProvider = StreamProvider<List<PaystubModel>>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) {
    return Stream.value(<PaystubModel>[]);
  }
  final repo = ref.watch(paystubRepositoryProvider);
  return retryOnError(repo.getPaystubs);
});

class PaystubsFilterState {
  final String searchQuery;
  final String? employeeId;
  final PaystubEstado? state;
  final String? periodo;

  const PaystubsFilterState({
    this.searchQuery = '',
    this.employeeId,
    this.state,
    this.periodo,
  });

  PaystubsFilterState copyWith({
    String? searchQuery,
    String? employeeId,
    PaystubEstado? state,
    String? periodo,
    bool clearState = false,
  }) {
    return PaystubsFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      employeeId: employeeId ?? this.employeeId,
      state: clearState ? null : (state ?? this.state),
      periodo: periodo ?? this.periodo,
    );
  }
}

class PaystubsFilterNotifier extends Notifier<PaystubsFilterState> {
  @override
  PaystubsFilterState build() {
    final now = DateTime.now();
    return PaystubsFilterState(
      periodo: '${now.year}-${now.month.toString().padLeft(2, '0')}',
    );
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value.trim().toLowerCase());
  }

  void setEmployeeId(String? id) {
    state = state.copyWith(employeeId: id);
  }

  void setState(PaystubEstado? stateValue) {
    state = state.copyWith(state: stateValue, clearState: stateValue == null);
  }

  void setPeriodo(String? periodo) {
    state = state.copyWith(periodo: periodo);
  }

  void clear() {
    final now = DateTime.now();
    state = PaystubsFilterState(
      periodo: '${now.year}-${now.month.toString().padLeft(2, '0')}',
    );
  }
}

final paystubsFilterProvider = NotifierProvider<PaystubsFilterNotifier, PaystubsFilterState>(
  PaystubsFilterNotifier.new,
);

final filteredPaystubsProvider = Provider<AsyncValue<List<PaystubModel>>>((ref) {
  final paystubsAsync = ref.watch(paystubsStreamProvider);
  final filter = ref.watch(paystubsFilterProvider);

  if (paystubsAsync.isLoading) return const AsyncValue.loading();
  if (paystubsAsync.hasError) return AsyncValue.error(paystubsAsync.error!, paystubsAsync.stackTrace!);

  final paystubs = paystubsAsync.value ?? [];

  List<PaystubModel> filtered = List.from(paystubs);

  if (filter.periodo != null && filter.periodo!.isNotEmpty) {
    filtered = filtered.where((p) => p.periodo == filter.periodo).toList();
  }

  if (filter.employeeId != null) {
    filtered = filtered.where((p) => p.userId == filter.employeeId).toList();
  }

  if (filter.state != null) {
    filtered = filtered.where((p) => p.estado == filter.state).toList();
  }

  filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return AsyncValue.data(filtered);
});

final totalPaystubsProvider = Provider<int>((ref) {
  final paystubsAsync = ref.watch(filteredPaystubsProvider);
  return paystubsAsync.value?.length ?? 0;
});

class PaystubActionState {
  final bool isLoading;
  final double uploadProgress;
  final String? error;
  final bool isSuccess;

  const PaystubActionState({
    this.isLoading = false,
    this.uploadProgress = 0,
    this.error,
    this.isSuccess = false,
  });

  bool get hasError => error != null;

  AsyncActionStatus get status {
    if (isLoading) return AsyncActionStatus.loading;
    if (isSuccess) return AsyncActionStatus.success;
    if (error != null) return AsyncActionStatus.failure;
    return AsyncActionStatus.idle;
  }

  const PaystubActionState.idle() : this();
}

class PaystubCreateNotifier extends Notifier<PaystubActionState> {
  @override
  PaystubActionState build() => const PaystubActionState.idle();

  Future<void> createPaystub({
    required String userId,
    required String periodo,
    required PlatformFile file,
  }) async {
    state = const PaystubActionState(isLoading: true, uploadProgress: 0);

    final repo = ref.read(paystubRepositoryProvider);
    final storageService = ref.read(storageServiceProvider);
    final companyId = ref.read(currentCompanyIdProvider);
    String? uploadedUrl;

    try {
      final docId = ref.read(firestoreServiceProvider).generateId('paystubs');
      final safeName = FileUtils.sanitizeFileName(file.name);
      final storagePath = 'companies/$companyId/paystubs/$userId/${docId}_$safeName';

      uploadedUrl = await storageService.uploadFile(
        path: storagePath,
        file: file,
        onProgress: (progress) {
          state = PaystubActionState(isLoading: true, uploadProgress: progress);
        },
      );

      state = const PaystubActionState(isLoading: true, uploadProgress: 1);

      final paystub = PaystubModel(
        id: docId,
        companyId: companyId ?? '',
        userId: userId,
        periodo: periodo,
        documentUrl: uploadedUrl,
        storagePath: storagePath,
        fileName: safeName,
        estado: PaystubEstado.pendiente,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      await repo.createPaystub(paystub);
      state = const PaystubActionState(isSuccess: true, uploadProgress: 1);
    } on StorageServiceException catch (e) {
      state = PaystubActionState(error: e.message);
    } catch (e) {
      if (uploadedUrl != null) {
        try {
          await storageService.deleteFile(uploadedUrl);
        } catch (_) {}
      }
      state = PaystubActionState(error: ErrorHandler.parse(e).message);
    }
  }

  void reset() {
    state = const PaystubActionState.idle();
  }
}

final paystubCreateProvider = NotifierProvider<PaystubCreateNotifier, PaystubActionState>(
  PaystubCreateNotifier.new,
);

class PaystubDeleteNotifier extends Notifier<AsyncActionState> {
  @override
  AsyncActionState build() => const AsyncActionState.idle();

  Future<void> deletePaystub(PaystubModel paystub) async {
    state = const AsyncActionState.loading();
    final repo = ref.read(paystubRepositoryProvider);
    final storageService = ref.read(storageServiceProvider);
    try {
      await repo.deletePaystub(paystub.id);
      
      // Also delete the file from Storage to free up space
      final pathToDelete = paystub.storagePath ?? paystub.documentUrl;
      if (pathToDelete.isNotEmpty) {
        try {
          await storageService.deleteFile(pathToDelete);
        } catch (e) {
          LoggingService.instance.error('No se pudo borrar el archivo de Storage', error: e);
        }
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

final paystubDeleteProvider = NotifierProvider<PaystubDeleteNotifier, AsyncActionState>(
  PaystubDeleteNotifier.new,
);

class PaystubApprovalNotifier extends Notifier<AsyncActionState> {
  @override
  AsyncActionState build() => const AsyncActionState.idle();

  Future<void> approve(String id) async {
    state = const AsyncActionState.loading();
    final repo = ref.read(paystubRepositoryProvider);
    try {
      await repo.updateEstado(
        id,
        estado: PaystubEstado.aceptado,
      );
      LoggingService.instance.info(
        'Paystub aprobado: $id',
        tag: 'paystubs',
      );
      state = const AsyncActionState.success();
    } catch (e, st) {
      LoggingService.instance.error(
        'Error al aprobar paystub: $id',
        tag: 'paystubs',
        error: e,
        stackTrace: st,
      );
      state = AsyncActionState.failure(ErrorHandler.parse(e).message);
    }
  }

  Future<void> reject(String id, {required String observacion}) async {
    state = const AsyncActionState.loading();
    final repo = ref.read(paystubRepositoryProvider);
    try {
      await repo.updateEstado(
        id,
        estado: PaystubEstado.rechazado,
        observacionRechazo: observacion,
      );
      LoggingService.instance.info(
        'Paystub rechazado: $id',
        tag: 'paystubs',
      );
      state = const AsyncActionState.success();
    } catch (e, st) {
      LoggingService.instance.error(
        'Error al rechazar paystub: $id',
        tag: 'paystubs',
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

final paystubApprovalProvider = NotifierProvider<PaystubApprovalNotifier, AsyncActionState>(
  PaystubApprovalNotifier.new,
);
