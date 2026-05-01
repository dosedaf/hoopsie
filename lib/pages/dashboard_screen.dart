import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:geocoding/geocoding.dart';
import '../models/game.dart';
import '../models/user.dart';
import '../widgets/game_card.dart';
import 'create_game_pop.dart';
import 'profile_screen.dart';
import '../services/database_service.dart';
import '../services/auth_manager.dart';
import '../services/ml_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseService _db = DatabaseService();
  final MLService _ml = MLService();
  late Future<List<Game>> _gamesFuture;

  Map<String, int> _gameScores = {};
  String _currentCity = "Fetching location...";

  final _searchController = TextEditingController();
  List<Game> _allGames = [];
  List<Game> _filteredGames = [];
  String _searchQuery = '';

  String? get currentUserId => AuthManager().currentUserId;

  @override
  void initState() {
    super.initState();
    _refreshGames();
    _getCityName();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getCityName() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _currentCity = "Yogyakarta"); // Fallback for Linux
        return;
      }

      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          setState(() => _currentCity = "Yogyakarta");
          return;
        }
      }

      geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.low,
      ).timeout(const Duration(seconds: 3));

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        setState(() {
          _currentCity =
              placemarks[0].subAdministrativeArea ??
              placemarks[0].locality ??
              "Yogyakarta";
        });
      }
    } catch (e) {
      // default
      setState(() => _currentCity = "Yogyakarta");
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredGames = _allGames.where((game) {
        return game.name.toLowerCase().contains(_searchQuery) ||
            (game.courtName?.toLowerCase().contains(_searchQuery) ?? false) ||
            (game.hostName?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    });
  }

  void _refreshGames() {
    setState(() {
      _gamesFuture = _db.getDiscoverableGames().then((games) async {
        final currentUser = AuthManager().currentUser;

        if (currentUser == null) return games;

        for (var game in games) {
          try {
            final participants = await _db.getGameParticipants(game.id);
            final score = await _ml.getMatchQuality(currentUser, participants);
            if (score != null) {
              _gameScores[game.id] = score;
            }
          } catch (e) {
            debugPrint("Error fetching AI score for game ${game.id}: $e");
          }
        }
        _allGames = games;
        _filteredGames = games;
        return games;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: FutureBuilder<User?>(
          future: _db.getCurrentUser(),
          builder: (context, userSnapshot) {
            final currentUser = userSnapshot.data;

            return RefreshIndicator(
              onRefresh: () async {
                _refreshGames();
                await _getCityName();
              },
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(currentUser),
                  const SizedBox(height: 24),
                  _buildCreateGameShortcut(),
                  const SizedBox(height: 32),
                  const Text(
                    'Available Games Nearby',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Game>>(
                    future: _gamesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }

                      final games = _searchQuery.isEmpty
                          ? (snapshot.data ?? [])
                          : _filteredGames;

                      if (games.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40.0),
                            child: Column(
                              children: [
                                Icon(
                                  _searchQuery.isEmpty
                                      ? Icons.search_off
                                      : Icons.manage_search,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _searchQuery.isEmpty
                                      ? "No games available nearby right now.\nWhy not create one?"
                                      : 'Tidak ada game yang cocok dengan "$_searchQuery"',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: games.map((game) {
                          return GameCard(
                            game: game,
                            isMyGame: false,
                            matchScore: _gameScores[game.id],
                            onJoin: () async {
                              await _db.joinGame(game.id);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Request to join sent!"),
                                ),
                              );
                              _refreshGames();
                            },
                          );
                        }).toList(),
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

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Cari nama game, lapangan, atau host...',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF2A52BE)),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                onPressed: () => _searchController.clear(),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A52BE), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildHeader(User? user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: Color(0xFF2A52BE)),
            const SizedBox(width: 8),
            Text(
              _currentCity,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
            _refreshGames();
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
              ],
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
        ),
      ],
    );
  }

  Widget _buildCreateGameShortcut() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A52BE), Color(0xFF1E3A9F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A52BE).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Find players for your match',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2A52BE),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
