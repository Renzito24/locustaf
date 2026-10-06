import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/repositories/comunicado_repository_impl.dart';
import '../../domain/models/comunicado_model.dart';
import '../../domain/repositories/comunicado_repository.dart';
import '../../../../core/providers/async_action_state.dart';
import '../../../../core/models/user_model.dart';

final comunicadoRepositoryProvider = Provider<ComunicadoRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final user = ref.watch(currentUserModelProvider);
  if (user == null || user.companyId == null) {
    throw Exception('User or company not found');
  }
  return ComunicadoRepositoryImpl(firestoreService, user.companyId!);
});

final comunicadosStreamProvider = StreamProvider.autoDispose<List<ComunicadoModel>>((ref) {
  final repository = ref.watch(comunicadoRepositoryProvider);
  return repository.streamComunicados();
});

final comunicadosForUserProvider = Provider.autoDispose<AsyncValue<List<ComunicadoModel>>>((ref) {
  final comunicadosAsync = ref.watch(comunicadosStreamProvider);
  final user = ref.watch(currentUserModelProvider);
  
  return comunicadosAsync.whenData((comunicados) {
    if (user == null) return [];
    
    // Admin / Superadmin / Supervisor can see all comunicados (created by them or others maybe?)
    // Wait, the requirement says "que el empleador pueda mandar a sus empleados" 
    // And employees only see the ones meant for them.
    // If Admin/Superadmin, they see ALL so they can track read receipts.
    if (user.rol == UserRole.admin || user.rol == UserRole.superadmin || user.rol == UserRole.supervisor) {
      return comunicados;
    }
    
    return comunicados.where((com) {
      if (com.targetType == TargetType.all) return true;
      if (com.targetType == TargetType.workplace && user.lugarDeTrabajoId != null) {
        return com.targetWorkplaceIds.contains(user.lugarDeTrabajoId);
      }
      if (com.targetType == TargetType.users) {
        return com.targetUserIds.contains(user.id);
      }
      return false;
    }).toList();
  });
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
