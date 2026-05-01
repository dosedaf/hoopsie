import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/database_service.dart';

class GameDetailsScreen extends StatefulWidget {
  final Game game;
  const GameDetailsScreen({super.key, required this.game});

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.game.name)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _db.getParticipantsWithDetails(widget.game.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final participants = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                "Participants",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ...participants.map((p) {
                final String status = p['member_status'];
                final String recordId = p['member_record_id'];

                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(p['name']),
                  subtitle: Text("${p['position']} • Status: $status"),
                  trailing: status == 'pending'
                      ? ElevatedButton(
                          onPressed: () async {
                            await _db.updateMemberStatus(recordId, 'approved');
                            setState(() {});
                          },
                          child: const Text("Accept"),
                        )
                      : const Icon(Icons.check_circle, color: Colors.green),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
