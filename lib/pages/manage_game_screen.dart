import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/database_service.dart';
import 'game_details_screen.dart';
import '../widgets/manage_game_card.dart';

class ManageGamesScreen extends StatefulWidget {
  const ManageGamesScreen({super.key});

  @override
  State<ManageGamesScreen> createState() => _ManageGamesScreenState();
}

class _ManageGamesScreenState extends State<ManageGamesScreen> {
  final DatabaseService _db = DatabaseService();

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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("You have left the game.")));
    setState(() {});
  }

  void _navigateToDetails(Game game) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GameDetailsScreen(game: game)),
    ).then((_) => setState(() {}));
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
              );
            },
          );
        },
      ),
    );
  }
}
