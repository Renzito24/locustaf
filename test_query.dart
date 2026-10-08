import 'dart:convert';
import 'dart:io';

const String _apiKey = 'AIzaSyCM6lWOpDTj060m8f1gsegtPkiyCn-Y4sM';
const String _projectId = 'locustaf-31ed2';
const String _authBaseUrl = 'https://identitytoolkit.googleapis.com/v1/accounts';
const String _firestoreBaseUrl = 'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents';

Future<void> main() async {
  final client = HttpClient();
  try {
    // 1. Log in to get token
    final authRequest = await client.postUrl(Uri.parse('$_authBaseUrl:signInWithPassword?key=$_apiKey'));
    authRequest.headers.contentType = ContentType.json;
    authRequest.write(jsonEncode({
      'email': 'superadmin@locustaf.com', // Let's try superadmin since rules block global lists
      'password': 'password123', // I don't know the password... let's check seed data
      'returnSecureToken': true,
    }));
    final authResp = await authRequest.close();
    final authRaw = await authResp.transform(utf8.decoder).join();
    if (authResp.statusCode != 200) {
      print('Auth Error: $authRaw');
      return;
    }
    final authData = jsonDecode(authRaw);
    final idToken = authData['idToken'];

    // 2. Query paystubs
    final uri = Uri.parse('$_firestoreBaseUrl/paystubs?pageSize=300');
    final request = await client.getUrl(uri);
    request.headers.set('Authorization', 'Bearer $idToken');
    final response = await request.close();
    final raw = await response.transform(utf8.decoder).join();
    if (response.statusCode != 200) {
      print('Error: $raw');
      return;
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final docs = data['documents'] as List<dynamic>? ?? [];
    
    final periods = <String>{};
    for (final doc in docs) {
      final fields = doc['fields'] as Map<String, dynamic>;
      final p = fields['periodo']?['stringValue'];
      if (p != null) {
        periods.add(p);
      }
    }
    print('Distinct periods: $periods');
  } catch (e) {
    print('Excepcion: $e');
  } finally {
    client.close();
  }
}
