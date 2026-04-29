import 'dart:convert';
import '../models/quiz.dart';
import 'database_service.dart';

class QuizService {
  final _db = DatabaseService();

  Future<List<QuizQuestion>> getUnansweredQuestions(String userId) async {
    final rows = await _db.getUnansweredQuestions(userId);
    return rows.map((row) {
      final options = List<String>.from(jsonDecode(row['options'] as String) as List);
      return QuizQuestion(
        id: row['id'] as int,
        question: row['question'] as String,
        options: options,
        correctIndex: row['correct_index'] as int,
        imageUrl: row['image_url'] as String?,
      );
    }).toList();
  }

  Future<void> markAnswered({
    required String userId,
    required int questionId,
  }) =>
      _db.markQuizAnswered(userId: userId, questionId: questionId);
}