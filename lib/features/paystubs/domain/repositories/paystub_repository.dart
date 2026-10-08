import '../models/paystub_model.dart';

abstract class PaystubRepository {
  Stream<List<PaystubModel>> getPaystubs();
  Future<void> createPaystub(PaystubModel paystub);
  Future<void> updateEstado(
    String id, {
    required PaystubEstado estado,
    String? observacionRechazo,
  });
  Future<void> deletePaystub(String id);
}
