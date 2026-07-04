import '../../data/models/incidence_model.dart';

abstract class IncidenceRepository {
  Stream<List<IncidenceModel>> getIncidences();
  Future<void> createIncidence(IncidenceModel incidence);
  Future<void> updateIncidence(IncidenceModel incidence);
  Future<void> softDeleteIncidence(String id);
}
