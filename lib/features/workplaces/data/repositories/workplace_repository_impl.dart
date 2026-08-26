import '../../../../core/services/firestore_service.dart';
import '../../domain/repositories/workplace_repository.dart';
import '../models/workplace_model.dart';

class WorkplaceRepositoryImpl implements WorkplaceRepository {
  final FirestoreService _firestoreService;
  final String? _companyId;

  WorkplaceRepositoryImpl(this._firestoreService, {String? companyId})
      : _companyId = companyId;

  @override
  Stream<List<WorkplaceModel>> getWorkplaces() {
    if (_companyId == null) return Stream.value(<WorkplaceModel>[]);
    return _firestoreService.queryStreamWithFilters<WorkplaceModel>(
      path: 'workplaces',
      filters: {'companyId': _companyId},
      fromJson: WorkplaceModel.fromJson,
    );
  }

  @override
  Future<void> createWorkplace(WorkplaceModel workplace) async {
    final data = workplace.toJson();
    if (_companyId != null) data['companyId'] = _companyId;
    final uid = await _firestoreService.addDocument(
      path: 'workplaces',
      data: data,
    );
    await _firestoreService.updateDocument(
      path: 'workplaces',
      documentId: uid,
      data: {'id': uid},
    );
  }

  @override
  Future<void> updateWorkplace(WorkplaceModel workplace) async {
    await _firestoreService.updateDocument(
      path: 'workplaces',
      documentId: workplace.id,
      data: workplace.copyWith(updatedAt: DateTime.now()).toJson(),
    );
  }

  @override
  Future<void> softDeleteWorkplace(String id) async {
    await _firestoreService.updateDocument(
      path: 'workplaces',
      documentId: id,
      data: {
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Future<void> reactivateWorkplace(String id) async {
    await _firestoreService.updateDocument(
      path: 'workplaces',
      documentId: id,
      data: {
        'isActive': true,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }
}
