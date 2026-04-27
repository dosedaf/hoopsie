import 'package:flutter/material.dart';
import '../models/game.dart';
import '../widgets/game_card.dart';
import 'create_game_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.location_on, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Surakarta',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const CircleAvatar(
                backgroundColor: Color(0xFF2A52BE),
                child: Icon(Icons.person, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Create Game Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create your Game',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${myGames.length} Games in your calendar',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A52BE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateGameScreen(),
                      ),
                    );
                    setState(() {}); // Refresh list after returning
                  },
                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                  label: const Text(
                    'Create',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Join Nearby Section
          const Text(
            'Available Games',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          // const SizedBox(height: 16),
          //...nearbyGames.map((game) => GameCard(game: game, isMyGame: false)),
        ],
      ),
    );
  }
}
