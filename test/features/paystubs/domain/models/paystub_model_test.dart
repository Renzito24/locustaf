
import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/features/paystubs/domain/models/paystub_model.dart';

void main() {
  group('PaystubModel', () {
    final now = DateTime(2026, 10, 1);
    final mockModel = PaystubModel(
      id: 'stub-123',
      companyId: 'comp-1',
      userId: 'user-1',
      periodo: 'Octubre 2026',
      documentUrl: 'https://example.com/doc.pdf',
      estado: PaystubEstado.pendiente,
      observacionRechazo: null,
      createdAt: now,
      updatedAt: now,
      isActive: true,
    );

    test('toJson and fromJson work correctly', () {
      final json = mockModel.toJson();
      
      // We overwrite id in fromJson manually since it's not stored in the body usually
      // but fromJson supports it if passed.
      json['id'] = 'stub-123';
      
      final parsed = PaystubModel.fromJson(json);

      expect(parsed.id, mockModel.id);
      expect(parsed.companyId, mockModel.companyId);
      expect(parsed.userId, mockModel.userId);
      expect(parsed.periodo, mockModel.periodo);
      expect(parsed.documentUrl, mockModel.documentUrl);
      expect(parsed.estado, mockModel.estado);
      expect(parsed.isActive, mockModel.isActive);
    });

    test('copyWith works correctly', () {
      final updated = mockModel.copyWith(
        estado: PaystubEstado.rechazado,
        observacionRechazo: 'No es mi sueldo',
      );

      expect(updated.estado, PaystubEstado.rechazado);
      expect(updated.observacionRechazo, 'No es mi sueldo');
      expect(updated.id, mockModel.id); // Should remain same
    });
  });
}
