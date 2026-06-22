import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../models/user.dart';
import 'dart:io';
import '../services/auth_manager.dart';
import '../services/biometric_service.dart';
import 'auth_screen.dart';
import 'skill_test_screen.dart';
import 'saran_kesan_screen.dart';
import 'court_payments_screen.dart';
import 'jump_counter_screen.dart';
import 'minigame_screen.dart';
import 'time_convert_screen.dart';
import 'step_counter_screen.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> _pickProfilePicture(User user) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final updatedUser = User(
        id: user.id,
        name: user.name,
        username: user.username,
        password: user.password,
        position: user.position,
        skillLevel: user.skillLevel,
        photoPath: image.path,
        role: user.role,
      );

      await _db.updateUser(updatedUser);
      setState(() {
        _userFuture = _db.getCurrentUser();
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _showEditProfileSheet(User user) {
    final nameController = TextEditingController(text: user.name);
    Position selectedPosition = user.position;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Full Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\.]")),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  ),
                ),
              ),
              if (user.role == 'player') ...[
                const SizedBox(height: 16),
                const Text(
                  'Primary Position',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Position>(
                      value: selectedPosition,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedPosition = val;
                          });
                        }
                      },
                      items: Position.values
                          .map((p) => DropdownMenuItem(value: p, child: Text(p.fullName)))
                          .toList(),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name cannot be empty')),
                      );
                      return;
                    }
                    if (name.length < 2) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name must be at least 2 characters')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);

                    final updatedUser = User(
                      id: user.id,
                      name: nameController.text.trim(),
                      username: user.username,
                      password: user.password,
                      position: selectedPosition,
                      skillLevel: user.skillLevel,
                      photoPath: user.photoPath,
                      role: user.role,
                    );

                    await _db.updateUser(updatedUser);
                    setState(() {
                      _userFuture = _db.getCurrentUser();
                    });

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully!')),
                    );
                  },
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
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
          final bool isOwner = user.role == 'owner';

          return SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 24.0, bottom: 100.0),
            child: Column(
              children: [
                _buildCompactHeader(user),
                const SizedBox(height: 20),
                if (!isOwner) _buildBasketballStats(user),
                if (isOwner) _buildOwnerStats(user),
                const SizedBox(height: 20),
                _buildMenuSection(context, user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactHeader(User user) {
    final bool isOwner = user.role == 'owner';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () => _pickProfilePicture(user),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF2563EB), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[100],
                      backgroundImage: user.photoPath != null
                          ? FileImage(File(user.photoPath!))
                          : null,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (user.photoPath == null)
                            const Icon(Icons.person, size: 40, color: Colors.grey),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (!isOwner)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      user.position.abbreviation,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  "@${user.username}",
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOwner ? const Color(0xFFEFF6FF) : user.tierColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOwner ? const Color(0xFF2563EB).withValues(alpha: 0.2) : user.tierColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        isOwner ? "COURT OWNER" : user.skillTier.toUpperCase(),
                        style: TextStyle(
                          color: isOwner ? const Color(0xFF2563EB) : user.tierColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showEditProfileSheet(user),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 10, color: Color(0xFF475569)),
                              SizedBox(width: 4),
                              Text(
                                "EDIT",
                                style: TextStyle(
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerStats(User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Account Specifications",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            Icons.verified_user_outlined,
            "Role Type",
            "Verified Court Provider",
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildStatRow(
            Icons.payments_outlined,
            "Service Fees Status",
            "Automatic payout transfers active",
          ),
        ],
      ),
    );
  }

  Widget _buildBasketballStats(User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Player Attributes",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            Icons.sports_basketball_outlined,
            "Primary Position",
            "${user.position.fullName} (${user.positionIndonesian})",
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.star_outline, color: Colors.orangeAccent),
                  SizedBox(width: 12),
                  Text(
                    "Overall Rating",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                  ),
                ],
              ),
              Text(
                "${user.visualRating.toStringAsFixed(1)} / 10",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: user.skillLevel / 100.0,
            backgroundColor: const Color(0xFFF1F5F9),
            color: const Color(0xFF2563EB),
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
        Icon(icon, color: const Color(0xFF2563EB), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context, User user) {
    final bool isOwner = user.role == 'owner';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFF7ED),
              child: Icon(Icons.rate_review_outlined, color: Colors.orange, size: 20),
            ),
            title: const Text(
              "Saran Kesan Matkul TPM",
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 14),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SaranKesanScreen()),
              );
            },
          ),
          const Divider(height: 8, indent: 56, color: Color(0xFFF1F5F9)),
          
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEFF6FF),
              child: Icon(Icons.payment_outlined, color: Color(0xFF2563EB), size: 20),
            ),
            title: const Text(
              "Court Rentals & Payments",
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 14),
            ),
            subtitle: const Text("Manage bookings, fees, and payouts", style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CourtPaymentsScreen()),
              );
            },
          ),
          const Divider(height: 8, indent: 56, color: Color(0xFFF1F5F9)),

          if (!isOwner) ...[
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF5F3FF),
                child: Icon(Icons.psychology_outlined, color: Colors.indigo, size: 20),
              ),
              title: const Text(
                "Skill Level Test",
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 14),
              ),
              subtitle: const Text("Get your basketball IQ score", style: TextStyle(fontSize: 12)),
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
            const Divider(height: 8, indent: 56, color: Color(0xFFF1F5F9)),

            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFEFF6FF),
                child: Icon(Icons.access_time, color: Color(0xFF2563EB), size: 20),
              ),
              title: const Text(
                "NBA Match Time",
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 14),
              ),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TimeConvertScreen()),
                );
              },
            ),
            const Divider(height: 8, indent: 56, color: Color(0xFFF1F5F9)),
          ],

          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFFAF5FF),
              child: Icon(Icons.sports_gymnastics_outlined, color: Colors.deepPurple, size: 20),
            ),
            title: const Text(
              "Jump Counter Game",
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 14),
            ),
            subtitle: const Text("Test your vertical jump count", style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const JumpCounterScreen()),
              );
            },
          ),
          const Divider(height: 8, indent: 56, color: Color(0xFFF1F5F9)),

          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFF0FDFA),
              child: Icon(Icons.videogame_asset_outlined, color: Colors.teal, size: 20),
            ),
            title: const Text(
              "Basketball Minigame",
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 14),
            ),
            subtitle: const Text("Play a quick shooter game", style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MinigameScreen()),
              );
            },
          ),
          const Divider(height: 8, indent: 56, color: Color(0xFFF1F5F9)),

          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFECFDF5),
              child: Icon(Icons.directions_walk, color: Color(0xFF059669), size: 20),
            ),
            title: const Text(
              "Step Counter",
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 14),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StepCounterScreen()),
              );
            },
          ),
          const Divider(height: 8, indent: 56, color: Color(0xFFF1F5F9)),

          if (_biometricAvailable) ...[
            ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFF1F5F9),
                child: Icon(
                  Icons.fingerprint,
                  color: _biometricEnabled ? const Color(0xFF2563EB) : Colors.grey,
                  size: 20,
                ),
              ),
              title: const Text(
                'Login Biometrik',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF334155), fontSize: 14),
              ),
              subtitle: Text(
                _biometricEnabled ? 'Aktif' : 'Nonaktif',
                style: TextStyle(
                  fontSize: 12,
                  color: _biometricEnabled ? const Color(0xFF2563EB) : Colors.grey,
                ),
              ),
              trailing: Switch(
                value: _biometricEnabled,
                activeColor: const Color(0xFF2563EB),
                onChanged: (_) => _toggleBiometric(),
              ),
            ),
            const Divider(height: 8, indent: 56, color: Color(0xFFF1F5F9)),
          ],

          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
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
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                label: const Text(
                  "Log Out",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
