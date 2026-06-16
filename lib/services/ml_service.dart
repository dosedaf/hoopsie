import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/game.dart';

class MLService {
  final String _apiKey = "AIzaSyCCXDjrhbjMrOc44uVkIKOKmpZJGORhKpc";
  final String _apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

  Future<Map<String, dynamic>> evaluateBasketballIQ(
    String question,
    String userAnswer,
  ) async {
    final prompt =
        """
      Act as a professional basketball coach. Evaluate the following strategic answer.
      Question: $question
      User Answer: $userAnswer
      
      Based on the basketball logic, terminology, and tactical depth, assign a skill score from 1-100.
      Return ONLY a JSON object: {"score": int, "feedback": "string", "tier": "string"}
    """;

    try {
      final response = await http.post(
        Uri.parse("$_apiUrl?key=$_apiKey"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        }),
      );

      final data = jsonDecode(response.body);
      String rawText = data['candidates'][0]['content']['parts'][0]['text'];

      String cleanJson = rawText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      return jsonDecode(cleanJson);
    } catch (e) {
      return {
        "score": 50,
        "feedback": "Error analyzing answer.",
        "tier": "Rotation",
      };
    }
  }

  Future<Map<String, int>> calculateMatchScores({
    required User user,
    required List<Game> games,
  }) async {
    if (games.isEmpty) return {};

    final gamesJson = games.map((g) => {
      "id": g.id,
      "name": g.name,
      "type": g.type.displayName,
      "courtName": g.courtName ?? "",
      "hostName": g.hostName ?? "",
      "startTime": g.startTime.toIso8601String(),
    }).toList();

    final userJson = {
      "name": user.name,
      "position": user.position.fullName,
      "skillLevel": user.skillLevel,
      "skillTier": user.skillTier,
      "rating": user.visualRating,
    };

    final prompt = """
      You are a basketball matchmaking ML model.
      Evaluate the match compatibility score (0 to 100) between the user and each available game.
      
      User Profile:
      ${jsonEncode(userJson)}

      Available Games:
      ${jsonEncode(gamesJson)}

      Calculate a matching percentage (0-100) for each game based on:
      1. Position compatibility (e.g. Center, Guard, Forward match with game types and sizes).
      2. Skill tier alignment.
      3. Game name and context (e.g. competitive vs casual match names vs user skill level).
      
      Return ONLY a JSON map of game ID to score integer. Example:
      {"game_id_1": 85, "game_id_2": 60}
    """;

    try {
      final response = await http.post(
        Uri.parse("$_apiUrl?key=$_apiKey"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rawText = data['candidates'][0]['content']['parts'][0]['text'];
        String cleanJson = rawText
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        
        final Map<String, dynamic> rawMap = jsonDecode(cleanJson);
        return rawMap.map((key, value) => MapEntry(key, value as int));
      }
    } catch (e) {
      // Fallback
    }

    final Map<String, int> fallback = {};
    for (var g in games) {
      int score = 65; 
      if (user.position.fullName.contains("Guard") && g.type.displayName.contains("1v1")) {
        score += 20;
      } else if (user.position.fullName.contains("Center") && g.type.displayName.contains("5v5")) {
        score += 20;
      }
      fallback[g.id] = score.clamp(0, 100);
    }
    return fallback;
  }
}
