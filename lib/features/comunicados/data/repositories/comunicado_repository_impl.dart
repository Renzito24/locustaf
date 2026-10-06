import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/services/firestore_service.dart';
import '../../domain/models/comunicado_model.dart';
import '../../domain/repositories/comunicado_repository.dart';

class ComunicadoRepositoryImpl implements ComunicadoRepository {
  final FirestoreService _firestoreService;
  final String _companyId;

  ComunicadoRepositoryImpl(this._firestoreService, this._companyId);

  @override
  Future<void> createComunicado(ComunicadoModel comunicado) async {
    final docRef = FirebaseFirestore.instance.collection('comunicados').doc();
    final newComunicado = comunicado.copyWith(id: docRef.id);
    await _firestoreService.setDocument(
      path: 'comunicados',
      documentId: newComunicado.id,
      data: newComunicado.toJson(),
    );
  }

  @override
  Future<void> markAsRead(String comunicadoId, String userId) async {
    await FirebaseFirestore.instance.collection('comunicados').doc(comunicadoId).update({
      'readBy': FieldValue.arrayUnion([userId])
    });
  }

  @override
  Stream<List<ComunicadoModel>> streamComunicados() {
    return _firestoreService.queryStreamWithFilters(
      path: 'comunicados',
      fromJson: (data) {
        return ComunicadoModel.fromJson(data);
      },
      filters: {'companyId': _companyId},
      orderField: 'createdAt',
      descending: true,
    );
  }
}
