import '../../../../core/models/payment_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final FirestoreService _firestoreService;

  PaymentRepositoryImpl(this._firestoreService);

  @override
  Stream<List<PaymentModel>> getRecentPayments({int limit = 50}) {
    // createdAt se guarda como ISO-8601 UTC, que ordena lexicográficamente
    // igual que cronológicamente (índice de campo único generado por Firebase).
    return _firestoreService
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
      (snapshot) => snapshot.docs.map((doc) {
        return PaymentModel.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList(),
    );
  }
}