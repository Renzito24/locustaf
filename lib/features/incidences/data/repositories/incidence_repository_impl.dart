import '../../../../core/models/user_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/repositories/incidence_repository.dart';
import '../models/incidence_model.dart';

class IncidenceRepositoryImpl implements IncidenceRepository {
  final FirestoreService _firestoreService;
  final String? _companyId;
  final String? _userId;
  final UserRole? _role;

  IncidenceRepositoryImpl(
    this._firestoreService, {
    String? companyId,
    String? userId,
    UserRole? role,
  })  : _companyId = companyId,
        _userId = userId,
        _role = role;

  @override
  Stream<List<IncidenceModel>> getIncidences() {
    if (_companyId == null) return Stream.value(<IncidenceModel>[]);
    // El empleado solo ve sus propias incidencias (alineado con las reglas).
    if (_role == UserRole.employee) {
      if (_userId == null) return Stream.value(<IncidenceModel>[]);
      return _firestoreService.queryStreamWithFilters<IncidenceModel>(
        path: 'incidences',
        filters: {'companyId': _companyId, 'userId': _userId},
        fromJson: IncidenceModel.fromJson,
      );
    }
    return _firestoreService.queryStreamWithFilters<IncidenceModel>(
      path: 'incidences',
      filters: {'companyId': _companyId},
      fromJson: IncidenceModel.fromJson,
    );
  }

  @override
  Future<void> createIncidence(IncidenceModel incidence) async {
    final data = incidence.toJson();
    if (_companyId != null) data['companyId'] = _companyId;
    await _firestoreService.addDocument(
      path: 'incidences',
      data: data,
    );
  }

  @override
  Future<void> updateIncidence(IncidenceModel incidence) async {
    await _firestoreService.updateDocument(
      path: 'incidences',
      documentId: incidence.id,
      data: incidence.copyWith(updatedAt: DateTime.now()).toJson(),
    );
  }

  @override
  Future<void> updateEstado(
    String id, {
    required IncidenceEstado estado,
    String? observacionRechazo,
  }) async {
    await _firestoreService.updateDocument(
      path: 'incidences',
      documentId: id,
      data: {
        'estado': estado.name,
        'observacionRechazo': observacionRechazo,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Future<void> softDeleteIncidence(String id) async {
    await _firestoreService.updateDocument(
      path: 'incidences',
      documentId: id,
      data: {
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }
}
