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
        _allGames = games;
        _filteredGames = games;

        final currentUser = await _db.getCurrentUser();
        if (currentUser != null && games.isNotEmpty) {
          try {
            final scores = await _ml.calculateMatchScores(
              user: currentUser,
              games: games,
            );
            if (mounted) {
              setState(() {
                _gameScores = scores;
              });
            }
          } catch (e) {
            debugPrint("ML matching error: $e");
          }
        }
        return games;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(currentUser),
                  const SizedBox(height: 24),
                  _buildCreateGameShortcut(),
                  const SizedBox(height: 32),
                  const Text(
                    'Available Games Nearby',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
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
    final name = user?.name ?? "Baller";
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello, $name 👋",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFF2A52BE), size: 16),
                const SizedBox(width: 4),
                Text(
                  _currentCity,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
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
              border: Border.all(color: const Color(0xFF2A52BE), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2A52BE).withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 22,
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
          colors: [Color(0xFF2A52BE), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A52BE).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
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
                'Host a Match',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Find players for your court today',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
              ),
            ],
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF2A52BE),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final result = await showModalBottomSheet<bool>(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const CreateGamePop(),
              );
              if (result == true) {
                _refreshGames();
              }
            },
            child: const Text('Host', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
