import '../../../../core/services/firestore_service.dart';
import '../../domain/repositories/workplace_repository.dart';
import '../models/workplace_model.dart';

class WorkplaceRepositoryImpl implements WorkplaceRepository {
  final FirestoreService _firestoreService;

  WorkplaceRepositoryImpl(this._firestoreService);

  @override
  Stream<List<WorkplaceModel>> getWorkplaces() {
    return _firestoreService.collectionStream<WorkplaceModel>(
      path: 'workplaces',
      fromJson: WorkplaceModel.fromJson,
    );
  }

  @override
  Future<void> createWorkplace(WorkplaceModel workplace) async {
    final uid = await _firestoreService.addDocument(
      path: 'workplaces',
      data: workplace.toJson(),
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
}
