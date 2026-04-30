import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static Future<List<Map<String, dynamic>>> searchAddress(String query) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1',
    );

    final response = await http.get(url, headers: {'User-Agent': 'HoopsieApp'});

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    return [];
  }
}
