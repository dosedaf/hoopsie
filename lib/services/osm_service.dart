import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geodesy/geodesy.dart';

class OSMService {
  static Future<List<LatLng>> fetchNearbyBasketballCourts(
    double lat,
    double lng,
  ) async {
    final query =
        '''
      [out:json];
      (
        node["leisure"="pitch"]["sport"="basketball"](around:5000, $lat, $lng);
        way["leisure"="pitch"]["sport"="basketball"](around:5000, $lat, $lng);
      );
      out center;
    ''';

    final response = await http.post(
      Uri.parse('https://overpass-api.de/api/interpreter'),
      body: query,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<LatLng> coords = [];
      for (var element in data['elements']) {
        coords.add(
          LatLng(
            element['lat'] ?? element['center']['lat'],
            element['lon'] ?? element['center']['lon'],
          ),
        );
      }
      return coords;
    }
    return [];
  }
}
