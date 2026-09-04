import 'dart:convert';

import 'package:http/http.dart' as http;

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
  static const _baseUrl = 'https://nominatim.openstreetmap.org';

  Future<List<GeocodingResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      '$_baseUrl/search?q=${Uri.encodeComponent(query.trim())}&format=json&limit=5&addressdetails=0',
    );

    try {
      final response = await http
          .get(uri, headers: const {'User-Agent': 'LocustafApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final List<dynamic> data = json.decode(response.body) as List<dynamic>;

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
    final uri = Uri.parse('$_baseUrl/reverse?lat=$lat&lon=$lng&format=json');

    try {
      final response = await http
          .get(uri, headers: const {'User-Agent': 'LocustafApp/1.0'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;

      return data['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
