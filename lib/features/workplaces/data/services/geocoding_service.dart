import 'dart:convert';
import 'dart:io';

class GeocodingResult {
  final double lat;
  final double lng;
  final String displayName;

  const GeocodingResult({
    required this.lat,
    required this.lng,
    required this.displayName,
  });
}

class GeocodingService {
  final HttpClient _client;

  GeocodingService() : _client = HttpClient();

  static const _baseUrl = 'https://nominatim.openstreetmap.org';

  Future<List<GeocodingResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      '$_baseUrl/search?q=${Uri.encodeComponent(query.trim())}&format=json&limit=5&addressdetails=0',
    );

    try {
      final request = await _client.getUrl(uri);
      request.headers.set('User-Agent', 'LocustafApp/1.0');
      final response = await request.close();

      if (response.statusCode != 200) return [];

      final body = await response.transform(utf8.decoder).join();
      final List<dynamic> data = json.decode(body) as List<dynamic>;

      return data.map((item) {
        return GeocodingResult(
          lat: double.parse(item['lat'] as String),
          lng: double.parse(item['lon'] as String),
          displayName: item['display_name'] as String,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<String?> reverse(double lat, double lng) async {
    final uri = Uri.parse(
      '$_baseUrl/reverse?lat=$lat&lon=$lng&format=json',
    );

    try {
      final request = await _client.getUrl(uri);
      request.headers.set('User-Agent', 'LocustafApp/1.0');
      final response = await request.close();

      if (response.statusCode != 200) return null;

      final body = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> data = json.decode(body) as Map<String, dynamic>;

      return data['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
