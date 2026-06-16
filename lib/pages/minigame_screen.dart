import 'package:flutter/material.dart';
import '../models/quiz.dart';
import '../services/quiz_service.dart';
import '../services/database_service.dart';

class MinigameScreen extends StatefulWidget {
  const MinigameScreen({super.key});

  @override
  State<MinigameScreen> createState() => _MinigameScreenState();
}

class _MinigameScreenState extends State<MinigameScreen> {
  final _quizService = QuizService();

  // Changed to String? to allow for the possibility that no user is logged in
  final String? _userId = DatabaseService().currentUserId;

  List<QuizQuestion> _questions = [];
  int _current = 0;
  int? _selected;
  bool _answered = false;
  bool _allDone = false;
  bool _loading = true;

  // Helper to safely get the current question
  QuizQuestion get q => _questions[_current];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    // Check if a user is actually logged in before calling the service
    if (_userId == null) {
      setState(() {
        _allDone = true;
        _loading = false;
      });
      return;
    }

    // Using the ! (bang) operator here is now safe because of the null check above
    final questions = await _quizService.getUnansweredQuestions(_userId!);
    setState(() {
      _questions = questions;
      _allDone = questions.isEmpty;
      _loading = false;
    });
  }

  void _answer(int index) {
    if (_answered || _userId == null) return;

    setState(() {
      _selected = index;
      _answered = true;
    });

    // Mark the question as answered in the database service
    _quizService.markAnswered(userId: _userId!, questionId: q.id);
  }

  void _next() {
    if (_current + 1 >= _questions.length) {
      setState(() => _allDone = true);
      return;
    }
    setState(() {
      _current++;
      _selected = null;
      _answered = false;
    });
  }

  // --- UI Styling Methods ---

  Color _optionBg(int i) {
    if (!_answered) return Colors.white;
    if (i == q.correctIndex) return const Color(0xFF22C55E);
    if (i == _selected) return const Color(0xFFEF4444);
    return Colors.white;
  }

  Color _optionBorder(int i) {
    if (!_answered) return const Color(0xFFCBD5E1);
    if (i == q.correctIndex) return const Color(0xFF16A34A);
    if (i == _selected) return const Color(0xFFDC2626);
    return const Color(0xFFCBD5E1);
  }

  Color _optionTextColor(int i) {
    if (!_answered) return const Color(0xFF1E293B);
    if (i == q.correctIndex || i == _selected) return Colors.white;
    return const Color(0xFF94A3B8);
  }

  Color _labelBg(int i) {
    if (!_answered) return const Color(0xFFEFF6FF);
    if (i == q.correctIndex) return const Color(0xFF16A34A);
    if (i == _selected) return const Color(0xFFDC2626);
    return const Color(0xFFE2E8F0);
  }

  Color _labelTextColor(int i) {
    if (!_answered) return const Color(0xFF2A52BE);
    if (i == q.correctIndex || i == _selected) return Colors.white;
    return const Color(0xFF94A3B8);
  }

  IconData? _trailingIcon(int i) {
    if (!_answered) return null;
    if (i == q.correctIndex) return Icons.check_circle_rounded;
    if (i == _selected) return Icons.cancel_rounded;
    return null;
  }

  static const _labels = ['A', 'B', 'C', 'D', 'E'];

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_allDone) return Scaffold(body: _buildAllDoneScreen());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Minigame'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildQuestionCard(),
                      const SizedBox(height: 20),
                      _buildOptions(),
                      const SizedBox(height: 4),
                      if (_answered) _buildNextButton(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A52BE), Color(0xFF1E3A9F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A52BE).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (q.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: q.imageUrl!.startsWith('http')
                    ? Image.network(q.imageUrl!, fit: BoxFit.cover)
                    : Image.asset(q.imageUrl!, fit: BoxFit.cover),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              q.question,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions() {
    return Column(
      children: List.generate(q.options.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: _optionBg(i),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _optionBorder(i), width: 1.5),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _answer(i),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _labelBg(i),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            _labels[i % _labels.length],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _labelTextColor(i),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          q.options[i],
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _optionTextColor(i),
                          ),
                        ),
                      ),
                      if (_trailingIcon(i) != null)
                        Icon(_trailingIcon(i), color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2A52BE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 15),
      ),
      onPressed: _next,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Lanjut", style: TextStyle(color: Colors.white)),
          SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildAllDoneScreen() {
    return Scaffold(
    appBar: AppBar(
      title: const Text('Minigame'),
      backgroundColor: Colors.white,
      elevation: 0,
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              size: 56,
              color: Color(0xFF2A52BE),
            ),
            const SizedBox(height: 24),
            Text(
              _userId == null
                  ? 'Silakan Login Terlebih Dahulu'
                  : 'Semua soal sudah dijawab!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _userId == null
                  ? 'Anda harus masuk akun untuk bermain.'
                  : 'Belum ada kuis baru saat ini.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    )
    );
  }
}
