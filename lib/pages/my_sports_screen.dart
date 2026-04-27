import 'package:flutter/material.dart';
import '../models/game.dart';
import '../widgets/game_card.dart';

class MySportsScreen extends StatefulWidget {
  const MySportsScreen({super.key});

  @override
  State<MySportsScreen> createState() => _MySportsScreenState();
}

class _MySportsScreenState extends State<MySportsScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Games',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: myGames.isEmpty
                  ? const Center(
                      child: Text(
                        'No games created yet. Head to Explore to create one!',
                      ),
                    )
                  : ListView.builder(
                      itemCount: myGames.length,
                      itemBuilder: (context, index) {
                        final game = myGames[index];
                        return GameCard(
                          game: game,
                          isMyGame: true,
                          onDelete: () {
                            setState(() {
                              myGames.removeAt(index);
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
