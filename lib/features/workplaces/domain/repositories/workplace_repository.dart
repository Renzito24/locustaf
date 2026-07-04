import '../../data/models/workplace_model.dart';

abstract class WorkplaceRepository {
  Stream<List<WorkplaceModel>> getWorkplaces();
  Future<void> createWorkplace(WorkplaceModel workplace);
  Future<void> updateWorkplace(WorkplaceModel workplace);
  Future<void> softDeleteWorkplace(String id);
}
