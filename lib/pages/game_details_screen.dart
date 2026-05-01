import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/database_service.dart';
import '../services/auth_manager.dart';

class GameDetailsScreen extends StatefulWidget {
  final Game game;
  const GameDetailsScreen({super.key, required this.game});

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  final DatabaseService _db = DatabaseService();

  final String? _currentUserId = AuthManager().currentUserId;

  @override
  Widget build(BuildContext context) {
    final bool isHost = widget.game.hostId == _currentUserId;

    return Scaffold(
      appBar: AppBar(title: Text(widget.game.name)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _db.getParticipantsWithDetails(widget.game.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final participants = snapshot.data ?? [];

          if (participants.isEmpty) {
            return const Center(
              child: Text("No participants yet for this game."),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                "Participants",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...participants.map((p) {
                final String status = p['member_status'] ?? 'pending';
                final String recordId = p['member_record_id'] ?? '';

                final String participantUserId = p['id']?.toString() ?? '';

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(p['name'] ?? 'Unknown Player'),
                  subtitle: Text("${p['position'] ?? 'N/A'} • Status: $status"),
                  trailing:
                      (isHost &&
                          status == 'pending' &&
                          participantUserId != _currentUserId)
                      ? ElevatedButton(
                          onPressed: () async {
                            if (recordId.isNotEmpty) {
                              await _db.updateMemberStatus(
                                recordId,
                                'approved',
                              );
                              setState(() {});
                            }
                          },
                          child: const Text("Accept"),
                        )
                      : _buildStatusIcon(status),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    if (status == 'approved') {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    return Text(
      status.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }
}
