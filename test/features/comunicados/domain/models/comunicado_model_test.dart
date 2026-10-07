
import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/features/comunicados/domain/models/comunicado_model.dart';

void main() {
  group('ComunicadoModel', () {
    final now = DateTime(2026, 10, 1);
    final mockModel = ComunicadoModel(
      id: 'com-123',
      companyId: 'comp-1',
      title: 'Cambio de horario',
      content: 'A partir de mañana el horario cambia.',
      targetType: TargetType.workplace,
      targetWorkplaceIds: const ['work-1'],
      targetUserIds: const [],
      readBy: const ['user-1'],
      createdBy: 'admin-1',
      createdAt: now,
    );

    test('toJson and fromJson work correctly', () {
      final json = mockModel.toJson();
      json['id'] = 'com-123';
      
      final parsed = ComunicadoModel.fromJson(json);

      expect(parsed.id, mockModel.id);
      expect(parsed.companyId, mockModel.companyId);
      expect(parsed.title, mockModel.title);
      expect(parsed.content, mockModel.content);
      expect(parsed.targetType, mockModel.targetType);
      expect(parsed.targetWorkplaceIds, mockModel.targetWorkplaceIds);
      expect(parsed.readBy, mockModel.readBy);
    });

    test('copyWith works correctly', () {
      final updated = mockModel.copyWith(
        readBy: ['user-1', 'user-2'],
      );

      expect(updated.readBy.length, 2);
      expect(updated.readBy.contains('user-2'), isTrue);
      expect(updated.title, mockModel.title); // Should remain same
    });
  });
}
