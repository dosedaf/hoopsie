import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import 'dart:io';
import '../services/auth_manager.dart';
import '../services/biometric_service.dart';
import 'auth_screen.dart';
import 'skill_test_screen.dart';
import 'saran_kesan_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _db = DatabaseService();
  final BiometricService _biometric = BiometricService();
  late Future<User?> _userFuture;

  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _userFuture = _db.getCurrentUser();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final available = await _biometric.isAvailable();
    final userId = AuthManager().currentUserId;
    final enabled = userId != null
        ? await AuthManager().isBiometricEnabled(userId)
        : false;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
  }

  Future<void> _toggleBiometric() async {
    final userId = AuthManager().currentUserId;
    if (userId == null) return;

    if (_biometricEnabled) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Nonaktifkan Biometrik?'),
          content: const Text(
            'Kamu perlu login dengan username dan password setelah ini.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Nonaktifkan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await AuthManager().removeBiometricUser(userId);
        setState(() => _biometricEnabled = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login biometrik dinonaktifkan')),
        );
      }
    } else {
      final success = await _biometric.authenticate();
      if (!success) return;

      final userId = AuthManager().currentUserId;
      if (userId == null) return;

      await AuthManager().saveBiometricUser(userId);
      setState(() => _biometricEnabled = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login biometrik diaktifkan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Player Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<User?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Error loading profile."));
          }

          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                _buildHeader(user),
                const SizedBox(height: 30),
                _buildBasketballStats(user),
                const SizedBox(height: 30),
                _buildMenuSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(User user) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2A52BE), width: 2),
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user.photoPath != null
                      ? FileImage(File(user.photoPath!))
                      : null,
                  child: user.photoPath == null
                      ? const Icon(Icons.person, size: 65, color: Colors.white)
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    user.position.abbreviation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            "@${user.username}",
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 8),
          Chip(
            label: Text(
              user.skillTier.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            backgroundColor: user.tierColor,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildBasketballStats(User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Player Attributes",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            Icons.sports_basketball,
            "Primary Position",
            "${user.position.fullName} (${user.positionIndonesian})",
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.star, color: Colors.orangeAccent),
                  SizedBox(width: 12),
                  Text(
                    "Overall Rating",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Text(
                "${user.visualRating.toStringAsFixed(1)} / 10",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2A52BE),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: user.skillLevel / 100.0,
            backgroundColor: Colors.grey[200],
            color: const Color(0xFF2A52BE),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2A52BE)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.rate_review_rounded, color: Colors.orange),
          title: const Text(
            "Saran Kesan Matkul TPM",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SaranKesanScreen()),
            );
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.psychology, color: Color(0xFF2A52BE)),
          title: const Text(
            "Skill Level Test",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: const Text("Get your basketball IQ score"),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SkillTestScreen()),
            );
            if (updated == true) {
              setState(() {
                _userFuture = _db.getCurrentUser(); // Refresh profile UI
              });
            }
          },
        ),
        if (_biometricAvailable) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.fingerprint,
              color: _biometricEnabled ? const Color(0xFF2A52BE) : Colors.grey,
            ),
            title: const Text(
              'Login Biometrik',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              _biometricEnabled ? 'Aktif' : 'Nonaktif',
              style: TextStyle(
                fontSize: 12,
                color: _biometricEnabled
                    ? const Color(0xFF2A52BE)
                    : Colors.grey,
              ),
            ),
            trailing: Switch(
              value: _biometricEnabled,
              activeColor: const Color(0xFF2A52BE),
              onChanged: (_) => _toggleBiometric(),
            ),
          ),
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              AuthManager().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const AuthScreen()),
                (Route<dynamic> route) => false,
              );
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text(
              "Log Out",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
