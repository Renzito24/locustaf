import '../models/comunicado_model.dart';

abstract class ComunicadoRepository {
  Future<void> createComunicado(ComunicadoModel comunicado);
  Future<void> markAsRead(String comunicadoId, String userId);
  Stream<List<ComunicadoModel>> streamComunicados();
  Stream<List<String>> streamReadComunicadoIds(String userId);
  Stream<List<String>> streamReadersForComunicado(String comunicadoId);
}
