import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ta_tes/services/auth_manager.dart';
import '../models/game.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import 'game_details_screen.dart';
import '../widgets/manage_game_card.dart';

class ManageGamesScreen extends StatefulWidget {
  const ManageGamesScreen({super.key});
  @override
  State<ManageGamesScreen> createState() => _ManageGamesScreenState();
}

class _ManageGamesScreenState extends State<ManageGamesScreen> {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notif = NotificationService();
  final userId = AuthManager().currentUserId ?? '';

  Future<void> _handleDelete(String gameId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Game?"),
        content: const Text(
          "This will permanently remove the game for everyone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.deleteGame(gameId);
      setState(() {});
    }
  }

  Future<void> _handleLeave(String gameId) async {
    await _db.leaveGame(gameId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("You have left the game.")),
    );
    setState(() {});
  }

  void _navigateToDetails(Game game) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GameDetailsScreen(game: game)),
    ).then((_) => setState(() {}));
  }

  Future<DateTime?> _showReminderDialog(Game game) async {
    final valueController = TextEditingController();
    String selectedUnit = 'menit';
    DateTime? result;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 24, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set Reminder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                game.name,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: valueController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: 'Berapa?',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      onChanged: (_) => setSheet(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedUnit,
                        items: ['menit', 'jam'].map((u) {
                          return DropdownMenuItem(value: u, child: Text(u));
                        }).toList(),
                        onChanged: (v) => setSheet(() => selectedUnit = v!),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Builder(builder: (_) {
                final val = int.tryParse(valueController.text);
                if (val == null || val <= 0) return const SizedBox();
                final minutes = selectedUnit == 'jam' ? val * 60 : val;
                final scheduledTime =
                    game.startTime.subtract(Duration(minutes: minutes));
                final isPast = scheduledTime.isBefore(DateTime.now());
                return Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    isPast
                        ? '⚠️ Waktu sudah lewat'
                        : '🔔 Notifikasi pada ${scheduledTime.day}/${scheduledTime.month} '
                            '${scheduledTime.hour.toString().padLeft(2, '0')}:'
                            '${scheduledTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPast ? Colors.red : const Color(0xFF2A52BE),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A52BE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final val = int.tryParse(valueController.text);
                    if (val == null || val <= 0) return;
                    final minutes = selectedUnit == 'jam' ? val * 60 : val;
                    final scheduledTime =
                        game.startTime.subtract(Duration(minutes: minutes));

                    if (scheduledTime.isBefore(DateTime.now())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Waktu reminder sudah lewat!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final userName = AuthManager().currentUser?.name ?? userId;

                    await _notif.scheduleNotification(
                      id: game.id.hashCode ^ minutes ^ userId.hashCode,
                      title: '🏀 [$userName] Game segera dimulai!',
                      body: '${game.name} di ${game.courtName} mulai $val $selectedUnit lagi.',
                      scheduledTime: scheduledTime,
                    );

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('reminder_${userId}_${game.id}', scheduledTime.toIso8601String());

                    result = scheduledTime;
                    Navigator.pop(ctx);

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reminder $val $selectedUnit berhasil diset!'),
                        backgroundColor: const Color(0xFF2A52BE),
                      ),
                    );
                  },
                  child: const Text(
                    'Set Reminder',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage My Games")),
      body: FutureBuilder<List<Game>>(
        future: _db.getMyGamesAndJoined(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final games = snapshot.data ?? [];
          return ListView.builder(
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              final bool amIHost = game.hostId == _db.currentUserId;
              return ManageGameCard(
                game: game,
                isMyGame: amIHost,
                onDelete: () => _handleDelete(game.id),
                onLeave: () => _handleLeave(game.id),
                onTap: () => _navigateToDetails(game),
                onReminder: () => _showReminderDialog(game),
              );
            },
          );
        },
      ),
    );
  }
}