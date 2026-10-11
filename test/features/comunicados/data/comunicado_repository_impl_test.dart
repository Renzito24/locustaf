import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/services/firestore_service.dart';
import 'package:app_locustaf/features/comunicados/data/repositories/comunicado_repository_impl.dart';
import 'package:app_locustaf/features/comunicados/domain/models/comunicado_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

ComunicadoModel _comunicado({
  required String id,
  String companyId = 'c1',
  String? content = 'Hola',
  String? storagePath,
}) {
  return ComunicadoModel(
    id: id,
    companyId: companyId,
    title: 'Comunicado $id',
    content: content,
    targetType: TargetType.all,
    storagePath: storagePath,
    createdBy: 'admin1',
    createdAt: DateTime(2026, 10, 1),
  );
}

/// Tests del repositorio de comunicados contra Firestore fake en memoria.
/// Cubren la reutilización del id provisto (NOT-07), el borrado (NOT-08) y el
/// aislamiento por empresa en la consulta de lectores (NOT-02).
void main() {
  late FakeFirebaseFirestore fake;
  late FirestoreService service;
  late ComunicadoRepositoryImpl repo;

  setUp(() {
    fake = FakeFirebaseFirestore();
    service = FirestoreService(fake);
    repo = ComunicadoRepositoryImpl(
      service,
      'c1',
      userId: 'admin1',
      role: UserRole.admin,
    );
  });

  test('createComunicado reutiliza el id provisto (doc id == storagePath)',
      () async {
    await repo.createComunicado(
      _comunicado(
        id: 'doc123',
        storagePath: 'companies/c1/comunicados/doc123/doc123.pdf',
      ),
    );

    final doc = await fake.collection('comunicados').doc('doc123').get();

    expect(doc.exists, isTrue);
    expect(doc.data()!['title'], 'Comunicado doc123');
    expect(doc.data()!['storagePath'],
        'companies/c1/comunicados/doc123/doc123.pdf');
  });

  test('createComunicado genera un id cuando el modelo no lo trae', () async {
    await repo.createComunicado(_comunicado(id: ''));

    final docs = await fake.collection('comunicados').get();
    expect(docs.docs, hasLength(1));
    expect(docs.docs.single.id, isNotEmpty);
    expect(docs.docs.single.data()['id'], docs.docs.single.id);
  });

  test('deleteComunicado elimina el documento', () async {
    await service.setDocument(
      path: 'comunicados',
      documentId: 'c9',
      data: _comunicado(id: 'c9').toJson(),
    );

    await repo.deleteComunicado('c9');

    final doc = await fake.collection('comunicados').doc('c9').get();
    expect(doc.exists, isFalse);
  });

  test('streamReadersForComunicado devuelve vacío si no hay empresa', () async {
    final sinEmpresa = ComunicadoRepositoryImpl(service, '');

    expect(await sinEmpresa.streamReadersForComunicado('c1').first, isEmpty);
    expect(await sinEmpresa.streamComunicados().first, isEmpty);
  });

  test('streamReadersForComunicado devuelve los userIds lectores de la empresa',
      () async {
    await service.setDocument(
      path: 'communicationReads',
      documentId: 'c1_u1',
      data: {
        'comunicadoId': 'c1',
        'userId': 'u1',
        'companyId': 'c1',
      },
    );
    await service.setDocument(
      path: 'communicationReads',
      documentId: 'c2_u2',
      data: {
        'comunicadoId': 'c2',
        'userId': 'u2',
        'companyId': 'c1',
      },
    );

    final readers = await repo.streamReadersForComunicado('c1').first;

    expect(readers, ['u1']);
  });
}
