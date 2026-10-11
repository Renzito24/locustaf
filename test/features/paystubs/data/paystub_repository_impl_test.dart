import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/services/firestore_service.dart';
import 'package:app_locustaf/features/paystubs/data/repositories/paystub_repository_impl.dart';
import 'package:app_locustaf/features/paystubs/domain/models/paystub_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

PaystubModel _paystub({
  required String id,
  required String userId,
  required String periodo,
  String companyId = 'c1',
}) {
  return PaystubModel(
    id: id,
    companyId: companyId,
    userId: userId,
    periodo: periodo,
    documentUrl: 'https://storage.example/$id.pdf',
    storagePath: 'paystubs/$id.pdf',
    fileName: '$id.pdf',
    estado: PaystubEstado.pendiente,
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );
}

/// Tests del repositorio de recibos contra Firestore fake en memoria
/// (fake_cloud_firestore). Cubren la consulta de duplicados (REC-02) y el
/// aislamiento por empresa/empleado.
void main() {
  late FakeFirebaseFirestore fake;
  late FirestoreService service;
  late PaystubRepositoryImpl repo;

  setUp(() {
    fake = FakeFirebaseFirestore();
    service = FirestoreService(fake);
    repo = PaystubRepositoryImpl(
      service,
      companyId: 'c1',
      userId: 'admin1',
      role: UserRole.admin,
    );
  });

  test('getPaystubsForUser devuelve solo los recibos del empleado en la empresa',
      () async {
    await repo.createPaystub(_paystub(id: 'p1', userId: 'u1', periodo: '2026-10'));
    await repo.createPaystub(_paystub(id: 'p2', userId: 'u2', periodo: '2026-10'));
    await service.setDocument(
      path: 'paystubs',
      documentId: 'p3',
      data: _paystub(id: 'p3', userId: 'u1', periodo: '2026-09', companyId: 'otra').toJson(),
    );

    final result = await repo.getPaystubsForUser('u1');

    expect(result.map((p) => p.id).toList(), ['p1']);
  });

  test('getPaystubsForUser devuelve lista vacía si no hay recibos', () async {
    final result = await repo.getPaystubsForUser('u1');
    expect(result, isEmpty);
  });

  test('permite detectar duplicado por período normalizado (REC-02)', () async {
    await repo.createPaystub(_paystub(id: 'p1', userId: 'u1', periodo: '2026-10'));

    final existentes = await repo.getPaystubsForUser('u1');

    expect(
      existentes.any((p) => p.normalizedPeriod == '2026-10'),
      isTrue,
      reason: 'Debe encontrarse el recibo ya cargado para ese período',
    );
    expect(
      existentes.any((p) => p.normalizedPeriod == '2026-11'),
      isFalse,
    );
  });

  test('con companyId vacío las consultas no rompen y devuelven vacío', () async {
    final sinEmpresa = PaystubRepositoryImpl(service, companyId: '');

    expect(await sinEmpresa.getPaystubsForUser('u1'), isEmpty);
    expect(await sinEmpresa.getPaystubs().first, isEmpty);
  });

  test('createPaystub reutiliza el id provisto (coincide con Storage)', () async {
    await repo.createPaystub(_paystub(id: 'doc-fijo', userId: 'u1', periodo: '2026-10'));

    final doc = await fake.collection('paystubs').doc('doc-fijo').get();

    expect(doc.exists, isTrue);
    expect(doc.data()!['companyId'], 'c1');
  });
}
