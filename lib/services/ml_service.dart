import 'dart:convert';
import 'dart:math' as math;
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

  static const List<_KNNTrainingSample> _trainingSamples = [
    // 1. Ideal Matches (Scores 90-100)
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 1.0,
        positionFit: 1.0,
        gameSizePreference: 1.0,
        keywordMatch: 1.0,
      ),
      98.0,
    ),
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 0.95,
        positionFit: 0.95,
        gameSizePreference: 0.95,
        keywordMatch: 0.90,
      ),
      95.0,
    ),
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 0.90,
        positionFit: 1.0,
        gameSizePreference: 0.90,
        keywordMatch: 0.85,
      ),
      92.0,
    ),

    // 2. Strong Matches (Scores 80-89)
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 0.85,
        positionFit: 0.95,
        gameSizePreference: 0.90,
        keywordMatch: 0.80,
      ),
      86.0,
    ),
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 0.90,
        positionFit: 0.80,
        gameSizePreference: 0.95,
        keywordMatch: 0.75,
      ),
      84.0,
    ),
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 0.80,
        positionFit: 0.90,
        gameSizePreference: 0.85,
        keywordMatch: 0.85,
      ),
      82.0,
    ),

    // 3. Moderate Matches (Scores 65-79)
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 0.75,
        positionFit: 0.85,
        gameSizePreference: 0.70,
        keywordMatch: 0.65,
      ),
      76.0,
    ),
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 0.70,
        positionFit: 0.80,
        gameSizePreference: 0.75,
        keywordMatch: 0.60,
      ),
      72.0,
    ),
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 0.65,
        positionFit: 0.75,
        gameSizePreference: 0.80,
        keywordMatch: 0.50,
      ),
      68.0,
    ),

    // 4. Mediocre Matches (Scores 50-64)
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 0.60,
        positionFit: 0.70,
        gameSizePreference: 0.60,
        keywordMatch: 0.50,
      ),
      62.0,
    ),
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 0.55,
        positionFit: 0.60,
        gameSizePreference: 0.65,
        keywordMatch: 0.40,
      ),
      55.0,
    ),
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 0.50,
        positionFit: 0.55,
        gameSizePreference: 0.50,
        keywordMatch: 0.50,
      ),
      50.0,
    ),

    // 5. Weak Matches (Scores 30-49)
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 0.45,
        positionFit: 0.50,
        gameSizePreference: 0.40,
        keywordMatch: 0.30,
      ),
      42.0,
    ),
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 0.40,
        positionFit: 0.60,
        gameSizePreference: 0.30,
        keywordMatch: 0.20,
      ),
      36.0,
    ),
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 0.35,
        positionFit: 0.40,
        gameSizePreference: 0.45,
        keywordMatch: 0.35,
      ),
      32.0,
    ),

    // 6. Terrible Matches / Clear Mismatches (Scores < 30)
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 0.20,
        positionFit: 0.30,
        gameSizePreference: 0.20,
        keywordMatch: 0.10,
      ),
      18.0,
    ),
    _KNNTrainingSample(
      _GameMatchFeatureVector(
        skillAlignment: 0.10,
        positionFit: 0.20,
        gameSizePreference: 0.10,
        keywordMatch: 0.05,
      ),
      10.0,
    ),
  ];

  _GameMatchFeatureVector _extractFeatures(User user, Game game) {
    final String gameNameLower = game.name.toLowerCase();

    double targetSkill = 70.0;
    final compKeywords = [
      "comp",
      "competitive",
      "pro",
      "sweaty",
      "advanced",
      "elite",
      "all-star",
      "division 1",
      "d1",
      "high-level",
      "ranked",
      "expert",
      "serious",
      "tryhard",
    ];
    final casualKeywords = [
      "casual",
      "chill",
      "beginner",
      "rookie",
      "fun",
      "friendly",
      "easy",
      "just for fun",
      "pickup",
      "open run",
      "open gym",
      "noob",
      "recreational",
      "rec",
    ];
    bool isComp = compKeywords.any((kw) => gameNameLower.contains(kw));
    bool isCasual = casualKeywords.any((kw) => gameNameLower.contains(kw));

    if (isComp && !isCasual) {
      targetSkill = 85.0;
    } else if (isCasual && !isComp) {
      targetSkill = 55.0;
    }

    final double skillDiff = (user.skillLevel - targetSkill).abs();
    final double skillAlignment = (1.0 - (skillDiff / 100.0)).clamp(0.0, 1.0);

    double positionFit = 0.8;
    switch (game.type) {
      case GameType.oneOnOne:
        if (user.position == Position.pg || user.position == Position.sg) {
          positionFit = 1.0;
        } else if (user.position == Position.sf) {
          positionFit = 0.8;
        } else {
          positionFit = 0.5;
        }
        break;
      case GameType.threeOnThree:
        if (user.position == Position.sf || user.position == Position.pf) {
          positionFit = 1.0;
        } else {
          positionFit = 0.9;
        }
        break;
      case GameType.fiveOnFive:
        if (user.position == Position.c || user.position == Position.pg) {
          positionFit = 1.0;
        } else {
          positionFit = 0.95;
        }
        break;
    }

    double gameSizePreference = 0.8;
    switch (game.type) {
      case GameType.oneOnOne:
        if (user.skillLevel >= 80) {
          gameSizePreference = 0.9;
        } else if (user.skillLevel >= 60) {
          gameSizePreference = 0.7;
        } else {
          gameSizePreference = 0.4;
        }
        break;
      case GameType.threeOnThree:
        if (user.skillLevel >= 80) {
          gameSizePreference = 0.85;
        } else if (user.skillLevel >= 60) {
          gameSizePreference = 1.0;
        } else {
          gameSizePreference = 0.85;
        }
        break;
      case GameType.fiveOnFive:
        if (user.skillLevel >= 80) {
          gameSizePreference = 1.0;
        } else if (user.skillLevel >= 60) {
          gameSizePreference = 0.9;
        } else {
          gameSizePreference = 0.75;
        }
        break;
    }

    double keywordMatch = 0.5;
    final isGuard =
        user.position == Position.pg || user.position == Position.sg;
    final isBig = user.position == Position.c || user.position == Position.pf;

    final guardKeywords = [
      "guard",
      "shoot",
      "shooter",
      "point",
      "handle",
      "perimeter",
      "iso",
    ];
    final bigKeywords = [
      "big",
      "center",
      "paint",
      "post",
      "rebound",
      "board",
      "size",
      "tall",
    ];

    if (isGuard && guardKeywords.any((kw) => gameNameLower.contains(kw))) {
      keywordMatch += 0.25;
    }
    if (isBig && bigKeywords.any((kw) => gameNameLower.contains(kw))) {
      keywordMatch += 0.25;
    }

    final posName = user.position.name.toLowerCase();
    final regExp = RegExp('\\b$posName\\b');
    if (regExp.hasMatch(gameNameLower)) {
      keywordMatch += 0.20;
    }

    final userTierLower = user.skillTier.toLowerCase();
    if (gameNameLower.contains(userTierLower)) {
      keywordMatch += 0.25;
    }

    keywordMatch = keywordMatch.clamp(0.0, 1.0);

    return _GameMatchFeatureVector(
      skillAlignment: skillAlignment,
      positionFit: positionFit,
      gameSizePreference: gameSizePreference,
      keywordMatch: keywordMatch,
    );
  }

  int _predictKNN(User user, Game game, {int k = 3}) {
    final query = _extractFeatures(user, game);
    List<MapEntry<_KNNTrainingSample, double>> distances = [];

    for (var sample in _trainingSamples) {
      double dist = query.distanceTo(sample.features);
      distances.add(MapEntry(sample, dist));
    }

    distances.sort((a, b) => a.value.compareTo(b.value));

    double weightedSum = 0.0;
    double sumOfWeights = 0.0;

    for (int i = 0; i < math.min(k, distances.length); i++) {
      final sample = distances[i].key;
      final dist = distances[i].value;

      final weight = 1.0 / (dist + 0.0001);
      weightedSum += sample.score * weight;
      sumOfWeights += weight;
    }

    final double predictedScore = weightedSum / sumOfWeights;
    return predictedScore.round().clamp(0, 100);
  }

  Future<Map<String, int>> calculateMatchScores({
    required User user,
    required List<Game> games,
  }) async {
    if (games.isEmpty) return {};

    final Map<String, int> scores = {};
    for (var game in games) {
      scores[game.id] = _predictKNN(user, game);
    }
    return scores;
  }
}

class _GameMatchFeatureVector {
  final double skillAlignment;
  final double positionFit;
  final double gameSizePreference;
  final double keywordMatch;

  const _GameMatchFeatureVector({
    required this.skillAlignment,
    required this.positionFit,
    required this.gameSizePreference,
    required this.keywordMatch,
  });

  double distanceTo(_GameMatchFeatureVector other) {
    final dSkill = skillAlignment - other.skillAlignment;
    final dPos = positionFit - other.positionFit;
    final dSize = gameSizePreference - other.gameSizePreference;
    final dKw = keywordMatch - other.keywordMatch;
    return math.sqrt(dSkill * dSkill + dPos * dPos + dSize * dSize + dKw * dKw);
  }
}

class _KNNTrainingSample {
  final _GameMatchFeatureVector features;
  final double score;

  const _KNNTrainingSample(this.features, this.score);
}
