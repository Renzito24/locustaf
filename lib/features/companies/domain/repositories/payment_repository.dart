import '../../../../core/models/payment_model.dart';

/// Historial de pagos registrados por el superadmin (TASK-017).
abstract class PaymentRepository {
  /// Últimos pagos registrados en la plataforma, ordenados de más reciente a
  /// más antiguo. Solo el superadmin puede leer esta colección.
  Stream<List<PaymentModel>> getRecentPayments({int limit = 50});

  /// Pagos de una empresa específica, ordenados de más reciente a más antiguo.
  /// Requiere el índice compuesto (companyId ASC, createdAt DESC) en Firestore.
  Stream<List<PaymentModel>> getPaymentsByCompany(String companyId,
      {int limit = 100});
}
