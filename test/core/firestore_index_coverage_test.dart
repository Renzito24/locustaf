import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guard estático del contrato "consultas de la app ↔ índices compuestos".
///
/// Firestore en producción rechaza consultas multiesel campo sin un índice
/// compuesto declarado ("The query requires an index"). El emulador los crea
/// automáticamente, por lo que ninguna suite ejecutada contra el emulador
/// detecta la ausencia de índices: este test declara el contrato explícito y
/// falla si `firestore.indexes.json` deja de cubrir alguna consulta real.
void main() {
  final File indexesFile = File('firestore.indexes.json');
  final List<dynamic> declared =
      jsonDecode(indexesFile.readAsStringSync())['indexes'] as List<dynamic>;

  final List<({String collection, List<(String, String)> fields})> required = [
    // Asistencias — historial del usuario ordenado por hora de entrada.
    (
      collection: 'attendances',
      fields: [('userId', 'ASCENDING'), ('checkInTime', 'DESCENDING')],
    ),
    // Asistencia activa del usuario (filtrar por status sin orden).
    (
      collection: 'attendances',
      fields: [('userId', 'ASCENDING'), ('status', 'ASCENDING')],
    ),
    // Asistencia activa de la empresa (doble filtro sin orden).
    (
      collection: 'attendances',
      fields: [('companyId', 'ASCENDING'), ('status', 'ASCENDING')],
    ),
    // Historial de la empresa ordenado por hora de entrada.
    (
      collection: 'attendances',
      fields: [('companyId', 'ASCENDING'), ('checkInTime', 'DESCENDING')],
    ),
    // Historial del usuario filtrado por empresa + orden por hora de entrada.
    (
      collection: 'attendances',
      fields: [
        ('userId', 'ASCENDING'),
        ('companyId', 'ASCENDING'),
        ('checkInTime', 'DESCENDING'),
      ],
    ),
    // Incidencias del empleado (filtro companyId + userId sin orden).
    (
      collection: 'incidences',
      fields: [('companyId', 'ASCENDING'), ('userId', 'ASCENDING')],
    ),
    // Documentos médicos del empleado (filtro companyId + userId sin orden).
    (
      collection: 'medical_documents',
      fields: [('companyId', 'ASCENDING'), ('userId', 'ASCENDING')],
    ),
  ];

  String fieldsKey(List<(String, String)> fields) =>
      fields.map((f) => '${f.$1}:${f.$2}').join('|');

  for (final query in required) {
    test('Índice requerido: ${query.collection} '
        '<${fieldsKey(query.fields)}> está declarado', () {
      final matches = declared.any((index) {
        if (index['collectionGroup'] != query.collection) return false;
        final fields = (index['fields'] as List<dynamic>)
            .map((f) => (f['fieldPath'] as String, f['order'] as String))
            .toList();
        return fieldsKey(fields) == fieldsKey(query.fields);
      });
      expect(
        matches,
        isTrue,
        reason: 'Falta el índice compuesto '
            '${query.collection}(${fieldsKey(query.fields)}) en '
            'firestore.indexes.json. Sin él, la consulta de producción falla '
            'con "The query requires an index".',
      );
    });
  }
}