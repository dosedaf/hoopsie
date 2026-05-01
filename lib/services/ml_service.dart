import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class MLService {
  final String _baseUrl = "http://10.0.2.2:8080/api";

  Future<int?> getMatchQuality(
    User currentUser,
    List<User> participants,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/match-quality"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user": {
            "position": currentUser.position.name,
            "skill_level": currentUser.skillLevel.toDouble(),
          },
          "players": participants
              .map(
                (p) => {
                  "position": p.position.name,
                  "skill_level": p.skillLevel.toDouble(),
                },
              )
              .toList(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['match_score'];
      }
    } catch (e) {
      print("AI Service Error: $e");
    }
    return null;
  }
}
