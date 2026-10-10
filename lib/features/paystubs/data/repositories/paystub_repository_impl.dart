import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/repositories/paystub_repository.dart';
import '../../domain/models/paystub_model.dart';

class PaystubRepositoryImpl implements PaystubRepository {
  final FirestoreService _firestoreService;
  final String _companyId;
  final String? _userId;
  final UserRole? _role;

  PaystubRepositoryImpl(
    this._firestoreService, {
    required String companyId,
    String? userId,
    UserRole? role,
  })  : _companyId = companyId,
        _userId = userId,
        _role = role;

  @override
  Stream<List<PaystubModel>> getPaystubs() {
    if (_companyId.isEmpty) {
      return Stream.value(<PaystubModel>[]);
    }
    
    if (_role == UserRole.employee || _role == UserRole.supervisor || (_role == null && _userId != null)) {
      if (_userId == null) return Stream.value(<PaystubModel>[]);
      return _firestoreService.queryStreamWithFilters<PaystubModel>(
        path: 'paystubs',
        filters: {'companyId': _companyId, 'userId': _userId},
        fromJson: PaystubModel.fromJson,
      );
    }
    
    return _firestoreService.queryStreamWithFilters<PaystubModel>(
      path: 'paystubs',
      filters: {'companyId': _companyId},
      fromJson: PaystubModel.fromJson,
    );
  }

  @override
  Future<void> createPaystub(PaystubModel paystub) async {
    final data = paystub.toJson();
    data['companyId'] = _companyId;
    await _firestoreService.addDocument(
      path: 'paystubs',
      data: data,
      // Usamos el mismo ID con el que se nombró el archivo en Storage para que
      // coincidan (ver PaystubCreateNotifier.createPaystub).
      documentId: paystub.id.isEmpty ? null : paystub.id,
    );
  }

  @override
  Future<void> updateEstado(
    String id, {
    required PaystubEstado estado,
    String? observacionRechazo,
  }) async {
    final Map<String, dynamic> data = {
      'estado': estado.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'respondedAt': FieldValue.serverTimestamp(),
    };
    
    if (observacionRechazo != null) {
      data['observacionRechazo'] = observacionRechazo;
    }
    
    await _firestoreService.updateDocument(
      path: 'paystubs',
      documentId: id,
      data: data,
    );
  }

  @override
  Future<void> deletePaystub(String id) async {
    await _firestoreService.deleteDocument(
      path: 'paystubs',
      documentId: id,
    );
  }
}
