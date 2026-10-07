import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/repositories/comunicado_repository_impl.dart';
import '../../domain/models/comunicado_model.dart';
import '../../domain/repositories/comunicado_repository.dart';
import '../../../../core/providers/async_action_state.dart';


final comunicadoRepositoryProvider = Provider<ComunicadoRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final user = ref.watch(currentUserModelProvider);
  if (user == null || user.companyId == null) {
    throw Exception('User or company not found');
  }
  return ComunicadoRepositoryImpl(
    firestoreService,
    user.companyId!,
    userId: user.id,
    workplaceId: user.lugarDeTrabajoId,
    role: user.rol,
  );
});

final comunicadosStreamProvider = StreamProvider.autoDispose<List<ComunicadoModel>>((ref) {
  final repository = ref.watch(comunicadoRepositoryProvider);
  return repository.streamComunicados();
});

final comunicadosForUserProvider = Provider.autoDispose<AsyncValue<List<ComunicadoModel>>>((ref) {
  return ref.watch(comunicadosStreamProvider);
});

final comunicadosReadIdsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final user = ref.watch(currentUserModelProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(comunicadoRepositoryProvider).streamReadComunicadoIds(user.id);
});

final comunicadoReadersProvider = StreamProvider.autoDispose.family<List<String>, String>((ref, comunicadoId) {
  return ref.watch(comunicadoRepositoryProvider).streamReadersForComunicado(comunicadoId);
});

class ComunicadoActionNotifier extends Notifier<AsyncActionState> {
  @override
  AsyncActionState build() => const AsyncActionState.idle();

  Future<void> createComunicado({
    required String title,
    required String content,
    required TargetType targetType,
    List<String> targetWorkplaceIds = const [],
    List<String> targetUserIds = const [],
  }) async {
    state = const AsyncActionState.loading();
    try {
      final repo = ref.read(comunicadoRepositoryProvider);
      final user = ref.read(currentUserModelProvider)!;
      
      final com = ComunicadoModel(
        id: '',
        companyId: user.companyId!,
        title: title,
        content: content,
        targetType: targetType,
        targetWorkplaceIds: targetWorkplaceIds,
        targetUserIds: targetUserIds,
        createdBy: user.id,
        createdAt: DateTime.now(),
      );
      
      await repo.createComunicado(com);
      state = const AsyncActionState.success();
    } catch (e) {
      state = AsyncActionState.failure(e.toString());
    }
  }

  Future<void> markAsRead(String comunicadoId) async {
    try {
      final repo = ref.read(comunicadoRepositoryProvider);
      final user = ref.read(currentUserModelProvider);
      if (user != null) {
        await repo.markAsRead(comunicadoId, user.id);
      }
    } catch (e) {
      // ignore
    }
  }
  
  void reset() {
    state = const AsyncActionState.idle();
  }
}

final comunicadoActionProvider = NotifierProvider<ComunicadoActionNotifier, AsyncActionState>(
  ComunicadoActionNotifier.new,
);
