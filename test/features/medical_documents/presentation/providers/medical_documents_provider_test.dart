import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/features/employees/presentation/providers/users_provider.dart';
import 'package:app_locustaf/features/medical_documents/data/models/medical_document_model.dart';
import 'package:app_locustaf/features/medical_documents/presentation/providers/medical_documents_provider.dart';

void main() {
  group('MedicalDocumentsProvider Tests', () {
    test('Stats providers count correctly', () async {
      final now = DateTime.now();
      
      final mockDocs = [
        MedicalDocumentModel(
          id: '1',
          userId: 'u1',
          companyId: 'c1',
          tipo: MedicalDocumentTipo.accidente,
          fechaInicio: now.subtract(const Duration(days: 10)),
          fechaFin: now.add(const Duration(days: 40)), // > 30 days = vigente
          estado: MedicalDocumentEstado.aprobado,
          motivo: 'Motivo',
          createdAt: now,
        ), // vigente
        MedicalDocumentModel(
          id: '2',
          userId: 'u2',
          companyId: 'c1',
          tipo: MedicalDocumentTipo.enfermedad,
          fechaInicio: now.subtract(const Duration(days: 20)),
          fechaFin: now.subtract(const Duration(days: 5)), // < 0 days = vencido
          estado: MedicalDocumentEstado.aprobado,
          motivo: 'Motivo',
          createdAt: now,
        ), // vencido
        MedicalDocumentModel(
          id: '3',
          userId: 'u1',
          companyId: 'c1',
          tipo: MedicalDocumentTipo.familiar,
          fechaInicio: now.subtract(const Duration(days: 5)),
          fechaFin: now.add(const Duration(days: 10)), // <= 30 days = proximoAVencer
          estado: MedicalDocumentEstado.aprobado,
          motivo: 'Motivo',
          createdAt: now,
        ), // proximoAVencer
      ];

      final container = ProviderContainer(
        overrides: [
          medicalDocumentsStreamProvider.overrideWith((ref) => Stream.value(mockDocs)),
          usersStreamProvider.overrideWith((ref) => Stream.value(<UserModel>[])),
        ],
      );

      container.listen(filteredMedicalDocumentsProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));

      final total = container.read(totalMedicalDocumentsProvider);
      final vigentes = container.read(vigentesCountProvider);
      final proximos = container.read(proximosAVencerCountProvider);
      final vencidos = container.read(vencidosCountProvider);

      expect(total, 3);
      expect(vigentes, 1);
      expect(proximos, 1);
      expect(vencidos, 1);
    });

    test('Filter state correctly filters', () async {
      final now = DateTime.now();
      
      final mockDocs = [
        MedicalDocumentModel(
          id: '1',
          userId: 'u1',
          companyId: 'c1',
          tipo: MedicalDocumentTipo.accidente,
          fechaInicio: now.subtract(const Duration(days: 10)),
          fechaFin: now.add(const Duration(days: 40)),
          estado: MedicalDocumentEstado.aprobado,
          motivo: 'Motivo',
          createdAt: now,
        ), // vigente, u1
        MedicalDocumentModel(
          id: '2',
          userId: 'u2',
          companyId: 'c1',
          tipo: MedicalDocumentTipo.enfermedad,
          fechaInicio: now.subtract(const Duration(days: 20)),
          fechaFin: now.subtract(const Duration(days: 5)),
          estado: MedicalDocumentEstado.aprobado,
          motivo: 'Motivo',
          createdAt: now,
        ), // vencido, u2
      ];

      final List<UserModel> mockUsers = [
        UserModel(
          id: 'u1',
          email: 'u1@test.com',
          rol: UserRole.employee,
          companyId: 'c1',
          nombre: 'Juan',
          apellido: 'Perez',
          dni: '12345678',
          createdAt: now,
        ),
        UserModel(
          id: 'u2',
          email: 'u2@test.com',
          rol: UserRole.employee,
          companyId: 'c1',
          nombre: 'Maria',
          apellido: 'Gomez',
          dni: '87654321',
          createdAt: now,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          medicalDocumentsStreamProvider.overrideWith((ref) => Stream.value(mockDocs)),
          usersStreamProvider.overrideWith((ref) => Stream.value(mockUsers)),
        ],
      );

      container.listen(filteredMedicalDocumentsProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));

      var filtered = container.read(filteredMedicalDocumentsProvider);
      expect(filtered.length, 2);

      // Filter by user ID
      container.read(medicalDocumentsFilterProvider.notifier).setEmployeeId('u1');
      await Future.delayed(const Duration(milliseconds: 10));
      filtered = container.read(filteredMedicalDocumentsProvider);
      expect(filtered.length, 1);
      expect(filtered.first.id, '1');

      // Clear filter
      container.read(medicalDocumentsFilterProvider.notifier).clear();
      await Future.delayed(const Duration(milliseconds: 10));
      filtered = container.read(filteredMedicalDocumentsProvider);
      expect(filtered.length, 2);

      // Filter by type
      container.read(medicalDocumentsFilterProvider.notifier).setTipo(MedicalDocumentTipo.enfermedad);
      await Future.delayed(const Duration(milliseconds: 10));
      filtered = container.read(filteredMedicalDocumentsProvider);
      expect(filtered.length, 1);
      expect(filtered.first.id, '2');
      
      // Filter by text search
      container.read(medicalDocumentsFilterProvider.notifier).clear();
      container.read(medicalDocumentsFilterProvider.notifier).setSearchQuery('juan');
      await Future.delayed(const Duration(milliseconds: 10));
      filtered = container.read(filteredMedicalDocumentsProvider);
      expect(filtered.length, 1);
      expect(filtered.first.id, '1');
    });
  });
}
