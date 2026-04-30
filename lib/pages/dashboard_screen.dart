import 'package:flutter/material.dart';
import 'dart:io';
import '../models/game.dart';
import '../models/user.dart';
import '../widgets/game_card.dart';
import 'create_game_pop.dart';
import 'profile_screen.dart';
import '../services/database_service.dart';
import '../services/auth_manager.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  late Future<List<Game>> _gamesFuture;

  String? get currentUserId => AuthManager().currentUserId;

  @override
  void initState() {
    super.initState();
    _refreshGames();
  }

  void _refreshGames() {
    setState(() {
      _gamesFuture = _db.getDiscoverableGames();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<User?>(
          future: _db.getCurrentUser(),
          builder: (context, userSnapshot) {
            final currentUser = userSnapshot.data;

            return RefreshIndicator(
              onRefresh: () async => _refreshGames(),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildHeader(currentUser),

                  const SizedBox(height: 24),
                  _buildCreateGameShortcut(),
                  const SizedBox(height: 32),
                  const Text(
                    'Available Games',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  FutureBuilder<List<Game>>(
                    future: _gamesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }

                      final games = snapshot.data ?? [];

                      if (games.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              "No games available nearby right now. Why not create one?",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: games
                            .map(
                              (game) => GameCard(
                                game: game,
                                isMyGame: false,
                                onJoin: () async {
                                  await _db.joinGame(game.id);
                                  if (!mounted) return; // Fix for async gap

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Request to join sent!"),
                                    ),
                                  );
                                  _refreshGames();
                                },
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.location_on, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Surakarta',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          ),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF2A52BE),
            backgroundImage: (user?.photoPath != null)
                ? FileImage(File(user!.photoPath!))
                : null,
            child: (user?.photoPath == null)
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateGameShortcut() {
    return Container(
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create a Game',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Find players for your match',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const CreateGamePop(),
              );

              if (result == true) {
                _refreshGames();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
