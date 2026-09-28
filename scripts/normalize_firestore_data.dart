// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

/// LOCUSTAF — Script de Mantenimiento y Normalización de Datos
///
/// Corrige tipos de datos heterogéneos en colecciones "companies" y "workplaces":
/// - companies: toleranciaCheckIn (String -> int), diasLaborables (`List<dynamic>` / String -> `List<int>`)
/// - workplaces: toleranciaMinutos (String -> int), radio, latitud, longitud (String -> double)
///
/// MODOS:
/// - Por defecto corre en DRY-RUN (solo inspecciona y lista cambios sin escribir).
/// - Para aplicar cambios reales en Firestore, debe pasarse explícitamente `--apply`.
///
/// REQUISITO OBLIGATORIO ANTES DE --apply:
/// Realizar un backup/export completo de Firestore desde Firebase Console o con gcloud:
/// `gcloud firestore export gs://<tu-bucket-backup>`

const String _defaultApiKey = 'AIzaSyCM6lWOpDTj060m8f1gsegtPkiyCn-Y4sM';
const String _defaultProjectId = 'locustaf-31ed2';

/// Normalizador puro de campos de una empresa.
/// Retorna un mapa con los campos normalizados si hubo cambios, o null si ya estaba normalizada.
Map<String, dynamic>? normalizeCompanyFields(Map<String, dynamic> rawFields) {
  final updates = <String, dynamic>{};
  bool changed = false;

  // 1. toleranciaCheckIn -> int
  if (rawFields.containsKey('toleranciaCheckIn')) {
    final val = rawFields['toleranciaCheckIn'];
    if (val is String) {
      updates['toleranciaCheckIn'] = int.tryParse(val) ?? 15;
      changed = true;
    } else if (val is num) {
      if (val is! int) {
        updates['toleranciaCheckIn'] = val.toInt();
        changed = true;
      }
    }
  }

  // 2. diasLaborables -> List<int>
  if (rawFields.containsKey('diasLaborables')) {
    final val = rawFields['diasLaborables'];
    if (val is List) {
      final hasString = val.any((e) => e is! int);
      if (hasString) {
        updates['diasLaborables'] = val.map((e) {
          if (e is int) return e;
          if (e is num) return e.toInt();
          return int.tryParse(e.toString()) ?? 1;
        }).toList();
        changed = true;
      }
    } else if (val is String) {
      // Si fue guardado como string "1,2,3,4,5"
      final parts = val.split(',').map((e) => int.tryParse(e.trim()) ?? 1).toList();
      updates['diasLaborables'] = parts;
      changed = true;
    }
  }

  return changed ? updates : null;
}

/// Normalizador puro de campos de un lugar de trabajo (workplace).
/// Retorna un mapa con los campos normalizados si hubo cambios, o null si ya estaba normalizado.
Map<String, dynamic>? normalizeWorkplaceFields(Map<String, dynamic> rawFields) {
  final updates = <String, dynamic>{};
  bool changed = false;

  // 1. toleranciaMinutos -> int
  if (rawFields.containsKey('toleranciaMinutos')) {
    final val = rawFields['toleranciaMinutos'];
    if (val is String) {
      updates['toleranciaMinutos'] = int.tryParse(val) ?? 15;
      changed = true;
    } else if (val is num && val is! int) {
      updates['toleranciaMinutos'] = val.toInt();
      changed = true;
    }
  }

  // 2. radio -> double
  if (rawFields.containsKey('radio')) {
    final val = rawFields['radio'];
    if (val is String) {
      updates['radio'] = double.tryParse(val) ?? 100.0;
      changed = true;
    } else if (val is int) {
      updates['radio'] = val.toDouble();
      changed = true;
    }
  }

  // 3. latitud -> double
  if (rawFields.containsKey('latitud')) {
    final val = rawFields['latitud'];
    if (val is String) {
      final parsed = double.tryParse(val);
      if (parsed != null) {
        updates['latitud'] = parsed;
        changed = true;
      }
    }
  }

  // 4. longitud -> double
  if (rawFields.containsKey('longitud')) {
    final val = rawFields['longitud'];
    if (val is String) {
      final parsed = double.tryParse(val);
      if (parsed != null) {
        updates['longitud'] = parsed;
        changed = true;
      }
    }
  }

  return changed ? updates : null;
}

Future<void> main(List<String> args) async {
  print('================================================================');
  print('    LOCUSTAF — Script de Normalización de Datos en Firestore    ');
  print('================================================================\n');

  final isApply = args.contains('--apply');
  final isDryRun = !isApply || args.contains('--dry-run');

  if (isDryRun) {
    print('ℹ️  MODO DRY-RUN ACTIVO (No se modificará ningún documento).');
    print('   Para aplicar los cambios reales, debes pasar el flag --apply.');
  } else {
    print('⚠️  MODO APLICACIÓN DIRECTA (--apply) ACTIVO.');
    print('   ¡ATENCIÓN! Asegúrate de haber realizado un backup de Firestore:');
    print('   gcloud firestore export gs://<tu-bucket-de-backup>\n');
  }

  String? token;
  for (final arg in args) {
    if (arg.startsWith('--token=')) {
      token = arg.substring('--token='.length);
    }
  }

  String email = 'admin@locustaf.com';
  String? password;
  for (final arg in args) {
    if (arg.startsWith('--email=')) email = arg.substring('--email='.length);
    if (arg.startsWith('--password=')) password = arg.substring('--password='.length);
  }

  final client = HttpClient();

  try {
    if (token == null && password != null) {
      print('Autenticando usuario $email para obtener token...');
      final authUrl = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_defaultApiKey',
      );
      final req = await client.postUrl(authUrl);
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'email': email, 'password': password, 'returnSecureToken': true}));
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      if (resp.statusCode != 200) {
        stderr.writeln('ERROR de autenticación: ${json['error']?['message'] ?? body}');
        exitCode = 1;
        return;
      }
      token = json['idToken'] as String;
      print('Autenticado exitosamente.\n');
    }

    if (token == null) {
      print('Para conectar a Firestore en vivo, provee:');
      print('  --token=<firebase-id-token>');
      print('o:');
      print('  --email=<admin-email> --password=<admin-password>');
      print('\nEjecución finalizada (sin credenciales proporcionadas).');
      return;
    }

    // Listar y procesar companies
    await _processCollection(
      client: client,
      projectId: _defaultProjectId,
      token: token,
      collection: 'companies',
      normalizer: normalizeCompanyFields,
      isDryRun: isDryRun,
    );

    // Listar y procesar workplaces
    await _processCollection(
      client: client,
      projectId: _defaultProjectId,
      token: token,
      collection: 'workplaces',
      normalizer: normalizeWorkplaceFields,
      isDryRun: isDryRun,
    );

    print('\nProceso de normalización finalizado.');
  } finally {
    client.close();
  }
}

Future<void> _processCollection({
  required HttpClient client,
  required String projectId,
  required String token,
  required String collection,
  required Map<String, dynamic>? Function(Map<String, dynamic>) normalizer,
  required bool isDryRun,
}) async {
  print('\n--- Analizando colección: $collection ---');
  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collection?pageSize=300',
  );

  final req = await client.getUrl(url);
  req.headers.set('Authorization', 'Bearer $token');
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();

  if (resp.statusCode != 200) {
    stderr.writeln('Error al listar $collection: ${resp.statusCode} $body');
    return;
  }

  final json = jsonDecode(body) as Map<String, dynamic>;
  final docs = json['documents'] as List<dynamic>? ?? [];
  print('Documentos encontrados en $collection: ${docs.length}');

  int modifiedCount = 0;

  for (final doc in docs) {
    final docMap = doc as Map<String, dynamic>;
    final docName = docMap['name'] as String;
    final docId = docName.split('/').last;
    final rawFields = _fromFirestoreFields(docMap['fields'] as Map<String, dynamic>? ?? {});

    final updates = normalizer(rawFields);
    if (updates != null && updates.isNotEmpty) {
      modifiedCount++;
      print('\n[$docId] Cambios requeridos:');
      for (final entry in updates.entries) {
        print('   • ${entry.key}: ${rawFields[entry.key]} (${rawFields[entry.key].runtimeType}) ➔ ${entry.value} (${entry.value.runtimeType})');
      }

      if (!isDryRun) {
        await _patchDocument(
          client: client,
          projectId: projectId,
          token: token,
          collection: collection,
          docId: docId,
          updates: updates,
        );
        print('   ✅ Actualizado en Firestore.');
      } else {
        print('   🔍 [DRY-RUN] No se escribió en la base de datos.');
      }
    }
  }

  if (modifiedCount == 0) {
    print('Todos los documentos en $collection ya están normalizados.');
  } else {
    print('\nTotal en $collection que requieren cambios: $modifiedCount / ${docs.length}');
  }
}

Future<void> _patchDocument({
  required HttpClient client,
  required String projectId,
  required String token,
  required String collection,
  required String docId,
  required Map<String, dynamic> updates,
}) async {
  final mask = updates.keys.map((k) => 'updateMask.fieldPaths=$k').join('&');
  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/$collection/$docId?$mask',
  );

  final req = await client.patchUrl(url);
  req.headers.contentType = ContentType.json;
  req.headers.set('Authorization', 'Bearer $token');
  req.write(jsonEncode({'fields': _toFirestoreFields(updates)}));
  final resp = await req.close();
  final body = await resp.transform(utf8.decoder).join();

  if (resp.statusCode != 200) {
    stderr.writeln('Error al actualizar $collection/$docId: ${resp.statusCode} $body');
  }
}

Map<String, dynamic> _fromFirestoreFields(Map<String, dynamic> fields) {
  final result = <String, dynamic>{};
  for (final entry in fields.entries) {
    final v = entry.value as Map<String, dynamic>;
    if (v.containsKey('stringValue')) {
      result[entry.key] = v['stringValue'];
    } else if (v.containsKey('integerValue')) {
      result[entry.key] = int.tryParse(v['integerValue'] as String) ?? v['integerValue'];
    } else if (v.containsKey('doubleValue')) {
      result[entry.key] = (v['doubleValue'] as num).toDouble();
    } else if (v.containsKey('booleanValue')) {
      result[entry.key] = v['booleanValue'];
    } else if (v.containsKey('arrayValue')) {
      final values = v['arrayValue']['values'] as List<dynamic>? ?? [];
      result[entry.key] = values.map((val) {
        final m = val as Map<String, dynamic>;
        if (m.containsKey('stringValue')) return m['stringValue'];
        if (m.containsKey('integerValue')) return int.tryParse(m['integerValue'] as String) ?? m['integerValue'];
        if (m.containsKey('doubleValue')) return (m['doubleValue'] as num).toDouble();
        if (m.containsKey('booleanValue')) return m['booleanValue'];
        return m.values.first;
      }).toList();
    } else if (v.containsKey('nullValue')) {
      result[entry.key] = null;
    }
  }
  return result;
}

Map<String, dynamic> _toFirestoreFields(Map<String, dynamic> data) {
  final fields = <String, dynamic>{};
  for (final entry in data.entries) {
    final key = entry.key;
    final value = entry.value;
    if (value == null) {
      fields[key] = {'nullValue': null};
    } else if (value is int) {
      fields[key] = {'integerValue': value.toString()};
    } else if (value is double) {
      fields[key] = {'doubleValue': value};
    } else if (value is bool) {
      fields[key] = {'booleanValue': value};
    } else if (value is List) {
      fields[key] = {
        'arrayValue': {
          'values': value.map((e) {
            if (e is int) return {'integerValue': e.toString()};
            if (e is double) return {'doubleValue': e};
            if (e is bool) return {'booleanValue': e};
            return {'stringValue': e.toString()};
          }).toList()
        }
      };
    } else {
      fields[key] = {'stringValue': value.toString()};
    }
  }
  return fields;
}
