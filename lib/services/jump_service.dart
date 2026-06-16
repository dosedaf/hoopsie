import 'database_service.dart';

class JumpScore {
  final String userId;
  final String name;
  final int score;

  const JumpScore({
    required this.userId,
    required this.name,
    required this.score,
  });
}

class JumpService {
  final _db = DatabaseService();

  Future<void> saveScore(String userId, int score) async {
    final best = await _db.getJumpPersonalBest(userId);
    if (best != null && score <= best) return;
    await _db.saveJumpScore(userId, score);
  }

  Future<int?> getPersonalBest(String userId) async {
    return await _db.getJumpPersonalBest(userId);
  }

  Future<List<JumpScore>> getLeaderboard() async {
    final rows = await _db.getJumpLeaderboard();
    return rows.map((r) => JumpScore(
      userId: r['user_id'] as String,
      name: r['name'] as String,
      score: r['score'] as int,
    )).toList();
  }
}