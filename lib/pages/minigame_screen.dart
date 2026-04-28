import 'package:flutter/material.dart';
import '../models/quiz.dart';

class MinigameScreen extends StatefulWidget {
  const MinigameScreen({super.key});

  @override
  State<MinigameScreen> createState() => _MinigameScreenState();
}

class _MinigameScreenState extends State<MinigameScreen> {
  int _current = 0;
  int? _selected;
  bool _answered = false;
  bool _allDone = false;

  QuizQuestion get q => quizQuestions[_current];

  void _answer(int index) {
    if (_answered) return;
    setState(() {
      _selected = index;
      _answered = true;
    });
  }

  void _next() {
    if (_current + 1 >= quizQuestions.length) {
      setState(() => _allDone = true);
      return;
    }
    setState(() {
      _current++;
      _selected = null;
      _answered = false;
    });
  }

  // ── Option styling ─────────────────────────────────────────────────────────

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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_allDone) return _buildAllDoneScreen();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Minigame',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
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
    );
  }

  // ── Sub-widgets ────────────────────────────────────────────────────────────

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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                q.imageUrl!,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 180,
                  child: Center(
                    child: Icon(Icons.person, size: 60, color: Colors.white38),
                  ),
                ),
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
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: _optionBg(i),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _optionBorder(i), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _answer(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
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
                              fontSize: 14,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _optionTextColor(i),
                          ),
                        ),
                      ),
                      if (_trailingIcon(i) != null) ...[
                        const SizedBox(width: 8),
                        Icon(_trailingIcon(i), color: Colors.white, size: 22),
                      ],
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF2A52BE), Color(0xFF1E3A9F)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A52BE).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _next,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lanjut',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllDoneScreen() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2A52BE).withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 56,
                  color: Color(0xFF2A52BE),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Semua soal sudah dijawab!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Belum ada kuis baru saat ini.\nKembali lagi nanti ya!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}