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
      "Down 2, Game 7, NBA Finals. 8 seconds left, no timeouts, you have the ball at the top of the key. Your best shooter (48% from three) is on the left wing but his defender is chest-to-chest — he got locked up when the defense got the scouting report. Your center is open on the right block, 68% near the rim, but zero three-point range. There's a small forward in the left corner at 38% from three whose defender has gone to sleep. And you — the point guard, 45% from three, 38 minutes in your legs — have a defender giving you a step of space, daring you to shoot. You have one dribble before the defense resets. The shot clock is off. Your team is in the bonus.  **What do you do, and why?** Three things your answer needs to cover: who gets the ball, whether you're going for the win or overtime, and what happens to your plan the moment the defense rotates.";

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
                      backgroundColor: const Color(0xFF2A52BE),
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
