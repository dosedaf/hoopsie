import 'dart:convert';
import 'package:http/http.dart' as http;

class MLService {
  final String _apiKey = "AIzaSyBS6eie40S3MlEcWUyDPPouVYS-okL_3Oo";
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
}
