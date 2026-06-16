import 'package:flutter/material.dart';
import '../services/ml_service.dart';
import '../services/database_service.dart';
import '../services/auth_manager.dart';

class SkillTestScreen extends StatefulWidget {
  const SkillTestScreen({super.key});

  @override
  State<SkillTestScreen> createState() => _SkillTestScreenState();
}

class _SkillTestScreenState extends State<SkillTestScreen> {
  final TextEditingController _answerController = TextEditingController();
  final MLService _ml = MLService();
  final DatabaseService _db = DatabaseService();
  bool _isAnalyzing = false;

  final String _scenario =
      "Game 7 of the NBA Finals, 12 seconds left, your team is down by 1 point, no timeouts, you have the ball in the backcourt after a made free throw, the opposing team has been switching every screen all game and has a strong rim protector waiting in the paint, you are the point guard, what play do you run for your team and explain exactly what all 5 players do on the possession and why you chose that approach.";

  void _submitEvaluation() async {
    if (_answerController.text.length < 10) return;

    setState(() => _isAnalyzing = true);

    final result = await _ml.evaluateBasketballIQ(
      _scenario,
      _answerController.text,
    );
    final int newScore = result['score'];

    final userId = AuthManager().currentUserId;
    if (userId != null) {
      await _db.updateUserSkill(userId, newScore);
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("AI Evaluation: ${result['tier']}"),
        content: Text(
          "Score: ${result['score']}\n\nCoach says: ${result['feedback']}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Awesome"),
          ),
        ],
      ),
    ).then((_) => Navigator.pop(context, true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Skill Assessment")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Scenario:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              _scenario,
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _answerController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "Explain your move in detail...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isAnalyzing
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitEvaluation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                    ),
                    child: const Text(
                      "Submit to AI Coach",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
