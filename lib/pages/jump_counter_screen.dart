import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/jump_service.dart';
import '../services/database_service.dart';
import '../services/auth_manager.dart';

class JumpCounterScreen extends StatefulWidget {
  const JumpCounterScreen({super.key});

  @override
  State<JumpCounterScreen> createState() => _JumpCounterScreenState();
}

class _JumpCounterScreenState extends State<JumpCounterScreen>
    with SingleTickerProviderStateMixin {
  static const _duration = 30;
  static const _deltaThreshold = 4.0;
  static const _cooldown = Duration(milliseconds: 800);

  final _jumpService = JumpService();
  final _db = DatabaseService();

  late TabController _tabController;

  int _jumpCount = 0;
  int _timeLeft = _duration;
  bool _running = false;
  bool _finished = false;

  Timer? _timer;
  StreamSubscription? _accelSub;
  DateTime? _lastJump;
  double _prevY = 0;
  bool _firstFrame = true;
  int? _personalBest;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userId = AuthManager().currentUserId;
    if (userId == null) return;
    final user = await _db.getCurrentUser();
    final best = await _jumpService.getPersonalBest(userId);
    setState(() {
      _userName = user?.name;
      _personalBest = best;
    });
  }

  void _start() {
    setState(() {
      _jumpCount = 0;
      _timeLeft = _duration;
      _running = true;
      _finished = false;
      _prevY = 0;
      _firstFrame = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) _stop();
    });

    _accelSub = accelerometerEventStream().listen((event) {
      if (_firstFrame) {
        _prevY = event.y;
        _firstFrame = false;
        return;
      }
      final deltaY = event.y - _prevY;
      _prevY = event.y;

      if (deltaY > _deltaThreshold) {
        final now = DateTime.now();
        if (_lastJump == null || now.difference(_lastJump!) > _cooldown) {
          _lastJump = now;
          setState(() => _jumpCount++);
        }
      }
    });
  }

  Future<void> _stop() async {
    _timer?.cancel();
    _accelSub?.cancel();

    final userId = AuthManager().currentUserId;
    final name = _userName ?? 'User';

    if (userId != null && _jumpCount > 0) {
      await _jumpService.saveScore(userId, _jumpCount);
      final best = await _jumpService.getPersonalBest(userId);
      setState(() => _personalBest = best);
    }

    setState(() {
      _running = false;
      _finished = true;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accelSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Jump Counter'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2A52BE),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2A52BE),
          tabs: const [
            Tab(text: 'Game'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGameTab(),
          _buildLeaderboardTab(),
        ],
      ),
    );
  }

  Widget _buildGameTab() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildTimerRing(),
                const SizedBox(height: 32),
                _buildCountDisplay(),
                const SizedBox(height: 24),
                if (_personalBest != null)
                  Text(
                    'Personal Best: $_personalBest jumps',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                if (_finished) ...[
                  const SizedBox(height: 16),
                  _buildResultCard(),
                ],
              ],
            ),
          ),
        ),
        _buildActionButton(),
      ],
    );
  }

  Widget _buildTimerRing() {
    final progress = _timeLeft / _duration;
    final color = _timeLeft > 10
        ? const Color(0xFF2A52BE)
        : _timeLeft > 5
            ? Colors.orange
            : Colors.red;

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: _running || _finished ? progress : 1.0,
              strokeWidth: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _running || _finished ? '$_timeLeft' : '$_duration',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Text(
                'seconds',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
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
        children: [
          Text(
            '$_jumpCount',
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'JUMPS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final isNewBest = _personalBest != null && _jumpCount >= _personalBest!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNewBest
            ? Colors.amber.withOpacity(0.1)
            : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNewBest ? Colors.amber : Colors.grey[300]!,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isNewBest ? Icons.emoji_events : Icons.check_circle_outline,
            color: isNewBest ? Colors.amber : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            isNewBest ? 'New Personal Best! 🎉' : 'Result: $_jumpCount jumps',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isNewBest ? Colors.amber[800] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _running ? Colors.red : const Color(0xFF2A52BE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          onPressed: _running ? _stop : _start,
          child: Text(
            _running ? 'Stop' : _finished ? 'Play Again' : 'Start',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    return FutureBuilder<List<JumpScore>>(
      future: _jumpService.getLeaderboard(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final scores = snapshot.data ?? [];
        final userId = AuthManager().currentUserId;

        if (scores.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.leaderboard, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Belum ada skor.\nJadi yang pertama!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: scores.length,
          itemBuilder: (context, index) {
            final score = scores[index];
            final isMe = score.userId == userId;
            final rank = index + 1;

            Color rankColor = Colors.grey;
            if (rank == 1) rankColor = const Color(0xFFFFD700);
            if (rank == 2) rankColor = const Color(0xFFC0C0C0);
            if (rank == 3) rankColor = const Color(0xFFCD7F32);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFEFF6FF) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      isMe ? const Color(0xFF2A52BE) : Colors.grey[200]!,
                  width: isMe ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: rank <= 3
                        ? Icon(Icons.emoji_events,
                            color: rankColor, size: 24)
                        : Text(
                            '$rank',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      score.name + (isMe ? ' (You)' : ''),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isMe
                            ? const Color(0xFF2A52BE)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.sports_gymnastics,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${score.score}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isMe
                              ? const Color(0xFF2A52BE)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}