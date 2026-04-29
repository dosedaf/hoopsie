import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/database_service.dart';
import 'game_details_screen.dart';
import '../widgets/game_card.dart';

class ManageGamesScreen extends StatefulWidget {
  const ManageGamesScreen({super.key});

  @override
  State<ManageGamesScreen> createState() => _ManageGamesScreenState();
}

class _ManageGamesScreenState extends State<ManageGamesScreen> {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage My Games")),
      body: FutureBuilder<List<Game>>(
        future: _db.getMyHostedGames(),

        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final myGames = snapshot.data ?? [];

          if (myGames.isEmpty) {
            return const Center(
              child: Text("You haven't hosted any games yet."),
            );
          }

          return ListView.builder(
            itemCount: myGames.length,
            itemBuilder: (context, index) {
              final game = myGames[index];
              return GameCard(
                game: game,
                isMyGame: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GameDetailsScreen(game: game),
                    ),
                  ).then((_) => setState(() {}));
                },
                onDelete: () async {
                  await _db.deleteGame(game.id);
                  setState(() {});
                },
              );
            },
          );
        },
      ),
    );
  }
}
