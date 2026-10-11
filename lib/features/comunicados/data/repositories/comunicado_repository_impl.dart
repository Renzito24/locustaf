import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../core/models/user_model.dart';
import '../../domain/models/comunicado_model.dart';
import '../../domain/repositories/comunicado_repository.dart';

class ComunicadoRepositoryImpl implements ComunicadoRepository {
  final FirestoreService _firestoreService;
  final String _companyId;
  final String? _userId;
  final String? _workplaceId;
  final UserRole? _role;

  ComunicadoRepositoryImpl(
    this._firestoreService, 
    this._companyId, {
    String? userId,
    String? workplaceId,
    UserRole? role,
  }) : _userId = userId,
       _workplaceId = workplaceId,
       _role = role;

  @override
  Future<void> createComunicado(ComunicadoModel comunicado) async {
    // Reusar el ID pre-generado por el provider (el mismo usado para nombrar el
    // archivo en Storage) para que el doc y el PDF compartan identificador.
    final documentId = comunicado.id.isNotEmpty
        ? comunicado.id
        : _firestoreService.generateId('comunicados');
    await _firestoreService.setDocument(
      path: 'comunicados',
      documentId: documentId,
      data: comunicado.copyWith(id: documentId).toJson(),
    );
  }

  @override
  Future<void> markAsRead(String comunicadoId, String userId) async {
    final docId = '${comunicadoId}_$userId';
    await _firestoreService.setDocument(
      path: 'communicationReads',
      documentId: docId,
      data: {
        'comunicadoId': comunicadoId,
        'userId': userId,
        'companyId': _companyId,
        'readAt': FieldValue.serverTimestamp(),
      },
    );
  }

  @override
  Future<void> deleteComunicado(String comunicadoId) async {
    await _firestoreService.deleteDocument(
      path: 'comunicados',
      documentId: comunicadoId,
    );
  }

  @override
  Stream<List<ComunicadoModel>> streamComunicados() {
    if (_companyId.isEmpty) {
      return Stream.value(<ComunicadoModel>[]);
    }
    if (_role == UserRole.admin || _role == UserRole.superadmin) {
      return _firestoreService.queryStreamWithFilters(
        path: 'comunicados',
        fromJson: ComunicadoModel.fromJson,
        filters: {'companyId': _companyId},
        orderField: 'createdAt',
        descending: true,
      );
    } else {
      if (_userId == null) return Stream.value([]);
      
      final streamAll = _firestoreService.queryStreamWithFilters(
        path: 'comunicados',
        fromJson: ComunicadoModel.fromJson,
        filters: {'companyId': _companyId, 'targetType': 'all'},
        orderField: 'createdAt',
        descending: true,
      );

      final streamUsers = _firestoreService.queryStreamWithFilters(
        path: 'comunicados',
        fromJson: ComunicadoModel.fromJson,
        filters: {'companyId': _companyId, 'arrayContains': {'targetUserIds': _userId}},
        orderField: 'createdAt',
        descending: true,
      );
      
      Stream<List<ComunicadoModel>>? streamWorkplaces;
      if (_workplaceId != null) {
        streamWorkplaces = _firestoreService.queryStreamWithFilters(
          path: 'comunicados',
          fromJson: ComunicadoModel.fromJson,
          filters: {'companyId': _companyId, 'arrayContains': {'targetWorkplaceIds': _workplaceId}},
          orderField: 'createdAt',
          descending: true,
        );
      }

      final streams = <Stream<List<ComunicadoModel>>>[
        streamAll,
        streamUsers,
        ?streamWorkplaces,
      ];

      return Stream.multi((controller) {
        final currentLists = List<List<ComunicadoModel>>.filled(streams.length, []);
        final hasData = List<bool>.filled(streams.length, false);
        final subscriptions = <dynamic>[];

        void emitCombined() {
          if (hasData.every((e) => e)) {
            final allComs = <ComunicadoModel>{};
            for (var list in currentLists) {
              allComs.addAll(list);
            }
            final sorted = allComs.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            controller.add(sorted);
          }
        }

        for (var i = 0; i < streams.length; i++) {
          subscriptions.add(streams[i].listen(
            (data) {
              currentLists[i] = data;
              hasData[i] = true;
              emitCombined();
            },
            onError: controller.addError,
          ));
        }

        controller.onCancel = () {
          for (var sub in subscriptions) {
            sub.cancel();
          }
        };
      });
    }
  }

  @override
  Stream<List<String>> streamReadComunicadoIds(String userId) {
    return _firestoreService.queryStreamWithoutOrder(
      path: 'communicationReads',
      field: 'userId',
      value: userId,
      fromJson: (json) => json['comunicadoId'] as String,
    );
  }

  @override
  Stream<List<String>> streamReadersForComunicado(String comunicadoId) {
    if (_companyId.isEmpty) {
      return Stream.value(<String>[]);
    }
    // Filtra por companyId además de comunicadoId: la regla de lectura de
    // communicationReads para admin exige `inCompany(resource.data.companyId)`,
    // y Firestore no aplica reglas como filtros, así que la query debe
    // restringir explícitamente por ese campo (equality-only → index merge).
    return _firestoreService.queryStreamWithFilters(
      path: 'communicationReads',
      filters: {'companyId': _companyId, 'comunicadoId': comunicadoId},
      fromJson: (json) => json['userId'] as String,
    );
  }
}
