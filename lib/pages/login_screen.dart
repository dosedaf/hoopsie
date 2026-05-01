import 'package:flutter/material.dart';
import 'package:ta_tes/pages/main_navigation.dart';
import '../services/database_service.dart';
import '../services/auth_manager.dart';
import '../services/biometric_service.dart';
import '../models/user.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _db = DatabaseService();
  final _biometric = BiometricService();

  bool _biometricAvailable = false;
  bool _hasBiometricUsers = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final available = await _biometric.isAvailable();
    final ids = await AuthManager().getBiometricUserIds();
    setState(() {
      _biometricAvailable = available;
      _hasBiometricUsers = ids.isNotEmpty;
    });
  }

  Future<void> _loginWithBiometric() async {
    final success = await _biometric.authenticate();
    if (!success) return;

    // Load semua akun yang punya biometrik aktif
    final ids = await AuthManager().getBiometricUserIds();
    if (ids.isEmpty) return;

    if (ids.length == 1) {
      // Langsung login kalau hanya 1 akun
      final user = await _db.getUserById(ids.first);
      if (user == null) return;
      _doLogin(user);
    } else {
      // Tampilkan picker kalau lebih dari 1 akun
      if (!mounted) return;
      final users = (await Future.wait(
        ids.map((id) => _db.getUserById(id)),
      )).whereType<User>().toList();

      if (!mounted) return;
      _showAccountPicker(users);
    }
  }

  void _showAccountPicker(List<User> users) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Akun',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Masuk sebagai siapa?',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ...users.map((user) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2A52BE),
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('@${user.username}'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _doLogin(user);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _doLogin(User user) {
    AuthManager().login(user);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  Future<void> _handleLogin() async {
    final user = await _db.loginUser(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username atau Password salah')),
      );
      return;
    }

    AuthManager().login(user);

    // Tawarkan aktifkan biometrik kalau belum dan device support
    if (_biometricAvailable) {
      final alreadyEnabled =
          await AuthManager().isBiometricEnabled(user.id);
      if (!alreadyEnabled) {
        await _offerBiometric(user.id);
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  Future<void> _offerBiometric(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Aktifkan Login Biometrik?'),
        content: const Text(
          'Login lebih cepat lain kali menggunakan sidik jari atau wajah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A52BE),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Aktifkan',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthManager().saveBiometricUser(userId);
      setState(() => _hasBiometricUsers = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports_basketball,
              size: 80,
              color: Color(0xFF2A52BE),
            ),
            const Text(
              'Hoopsie',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A52BE),
                ),
                onPressed: _handleLogin,
                child: const Text(
                  'Login',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            // Tombol biometrik — muncul kalau ada akun yang sudah aktifkan
            if (_biometricAvailable && _hasBiometricUsers) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Color(0xFF2A52BE)),
                ),
                onPressed: _loginWithBiometric,
                icon: const Icon(
                  Icons.fingerprint,
                  color: Color(0xFF2A52BE),
                  size: 24,
                ),
                label: const Text(
                  'Login dengan Biometrik',
                  style: TextStyle(color: Color(0xFF2A52BE)),
                ),
              ),
            ],

            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignupScreen()),
              ),
              child: const Text('Belum punya akun? Daftar di sini'),
            ),
          ],
        ),
      ),
    );
  }
}