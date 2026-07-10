import 'dart:convert';
import 'dart:io';

const String _apiKey = 'AIzaSyCM6lWOpDTj060m8f1gsegtPkiyCn-Y4sM';
const String _projectId = 'locustaf-31ed2';

const String _authBaseUrl =
    'https://identitytoolkit.googleapis.com/v1/accounts';
const String _firestoreBaseUrl =
    'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

Future<void> main(List<String> args) async {
  print('=== LOCUSTAF Seed Script ===\n');

  final seedFile = File('${Directory.current.path}/seed/seed_data.json');
  if (!seedFile.existsSync()) {
    stderr.writeln('ERROR: seed/seed_data.json not found');
    exitCode = 1;
    return;
  }

  final seedData = jsonDecode(seedFile.readAsStringSync()) as Map<String, dynamic>;
  final workplaces = seedData['workplaces'] as List<dynamic>;
  final users = seedData['users'] as List<dynamic>;

  // Step 1: Ensure admin user exists in Auth -> get idToken for Firestore writes
  final adminEmail = 'admin@locustaf.com';
  final adminPassword = 'Admin123!';
  final adminAuth = await _ensureUserExists(adminEmail, adminPassword);
  if (adminAuth == null) {
    stderr.writeln('FATAL: Could not create or sign in admin user');
    exitCode = 1;
    return;
  }
  print('Admin authenticated: $adminEmail (uid: ${adminAuth['uid']})');
  final adminIdToken = adminAuth['idToken'] as String;

  // Step 2: Create workplaces
  String? workplaceId;
  print('\n--- Creating workplaces ---');
  for (final w in workplaces) {
    final data = (w as Map<String, dynamic>);
    final now = DateTime.now().toIso8601String();
    data['createdAt'] = now;
    data['updatedAt'] = now;
    workplaceId = await _createFirestoreDocument('workplaces', data, adminIdToken);
    if (workplaceId != null) {
      print('  Created workplace: ${data['nombre']} (id: $workplaceId)');
    }
  }

  // Step 3: Create users
  String? employeeId;
  print('\n--- Creating users ---');
  for (final u in users) {
    final data = (u as Map<String, dynamic>);
    final email = data['email'] as String;
    final password = data['password'] as String;

    final auth = await _ensureUserExists(email, password);
    if (auth == null) {
      print('  SKIPPING user: $email (could not create Auth user)');
      continue;
    }
    final uid = auth['uid'] as String;

    data.remove('password');
    if (data['lugarDeTrabajoId'] == '__WORKPLACE_ID__') {
      data['lugarDeTrabajoId'] = workplaceId;
    }
    final now = DateTime.now().toIso8601String();
    data['createdAt'] = now;
    data['updatedAt'] = now;
    final docId = await _createFirestoreDocument('users', data, adminIdToken, documentId: uid);
    if (docId != null) {
      print('  Created user: $email (id: $docId)');
    }

    if (data['rol'] == 'employee') {
      employeeId = uid;
    }
  }

  // Step 4: Create medical documents
  final medicalDocs = seedData['medical_documents'] as List<dynamic>?;
  if (medicalDocs != null && employeeId != null) {
    print('\n--- Creating medical documents ---');
    for (final doc in medicalDocs) {
      final data = (doc as Map<String, dynamic>);
      if (data['userId'] == '__EMPLOYEE_ID__') {
        data['userId'] = employeeId;
      }
      final now = DateTime.now().toIso8601String();
      data['createdAt'] = now;
      final docId = await _createFirestoreDocument('medical_documents', data, adminIdToken);
      if (docId != null) {
        print('  Created medical document: ${data['tipo']} (id: $docId)');
      }
    }
  }

  print('\n=== Seed complete ===\n');
  print('Users created:');
  for (final u in users) {
    final data = u as Map<String, dynamic>;
    print('  ${data['email']} / ${data['password']}');
  }
}

/// Returns {uid, idToken} for [email], creating the Auth user if needed.
Future<Map<String, String>?> _ensureUserExists(
    String email, String password) async {
  // Try signing in first (handles re-runs)
  final signInResult = await _authRequest('signInWithPassword', {
    'email': email,
    'password': password,
    'returnSecureToken': true,
  });
  if (signInResult != null && signInResult['localId'] != null) {
    return {
      'uid': signInResult['localId'] as String,
      'idToken': signInResult['idToken'] as String,
    };
  }

  // Sign up new user
  final signUpResult = await _authRequest('signUp', {
    'email': email,
    'password': password,
    'returnSecureToken': true,
  });
  if (signUpResult != null && signUpResult['localId'] != null) {
    return {
      'uid': signUpResult['localId'] as String,
      'idToken': signUpResult['idToken'] as String,
    };
  }

  return null;
}

/// Calls a Firebase Auth REST API endpoint.
Future<Map<String, dynamic>?> _authRequest(
    String endpoint, Map<String, dynamic> body) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(
      Uri.parse('$_authBaseUrl:$endpoint?key=$_apiKey'),
    );
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
    final response = await request.close();
    final raw = await response.transform(utf8.decoder).join();
    final data = jsonDecode(raw) as Map<String, dynamic>;

    if (response.statusCode == 200) return data;

    final errorMsg =
        (data['error'] as Map<String, dynamic>?)?['message'] as String? ?? raw;
    stderr.writeln('  Auth $endpoint error for ${body['email']}: $errorMsg');
    return null;
  } finally {
    client.close();
  }
}

/// Creates a Firestore document using the Firestore REST API.
Future<String?> _createFirestoreDocument(
  String collection,
  Map<String, dynamic> data,
  String idToken, {
  String? documentId,
}) async {
  final client = HttpClient();
  try {
    final fields = _toFirestoreFields(data);
    final body = {'fields': fields};

    final uri = documentId != null
        ? Uri.parse(
            '$_firestoreBaseUrl/$collection?documentId=$documentId')
        : Uri.parse(_firestoreBaseUrl);
    final request = await client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.headers.set('Authorization', 'Bearer $idToken');
    request.write(jsonEncode(body));
    final response = await request.close();
    final raw = await response.transform(utf8.decoder).join();

    if (response.statusCode == 200) {
      final result = jsonDecode(raw) as Map<String, dynamic>;
      final name = result['name'] as String? ?? '';
      return name.split('/').last;
    }

    stderr.writeln(
        '  Firestore error ($collection): ${response.statusCode} $raw');
    return null;
  } finally {
    client.close();
  }
}

/// Converts a Dart Map to Firestore REST API fields format.
Map<String, dynamic> _toFirestoreFields(Map<String, dynamic> data) {
  final fields = <String, dynamic>{};
  for (final entry in data.entries) {
    final key = entry.key;
    final value = entry.value;
    if (value == null) {
      fields[key] = {'nullValue': null};
    } else if (value is String) {
      fields[key] = {'stringValue': value};
    } else if (value is bool) {
      fields[key] = {'booleanValue': value};
    } else if (value is num) {
      fields[key] = {'doubleValue': value.toDouble()};
    } else if (value is List) {
      fields[key] = {
        'arrayValue': {
          'values': value.map((e) {
            if (e is String) return {'stringValue': e};
            if (e is bool) return {'booleanValue': e};
            if (e is num) return {'doubleValue': e.toDouble()};
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
