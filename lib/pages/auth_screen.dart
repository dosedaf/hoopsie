import 'package:flutter/material.dart';
import 'package:ta_tes/pages/main_navigation.dart';
import '../services/database_service.dart';
import '../services/auth_manager.dart';
import '../services/biometric_service.dart';
import '../models/user.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final PageController _pageController = PageController();
  final _db = DatabaseService();
  final _biometric = BiometricService();

  bool _isLoginSelected = true;
  bool _biometricAvailable = false;
  bool _hasBiometricUsers = false;

  final _loginUser = TextEditingController();
  final _loginPass = TextEditingController();

  final _signName = TextEditingController();
  final _signUser = TextEditingController();
  final _signPass = TextEditingController();
  final _signPassConfirm = TextEditingController();
  Position _selectedPosition = Position.pg;
  double _skillLevel = 50;
  String _selectedRole = 'player'; // 'player' or 'owner'

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _loginUser.dispose();
    _loginPass.dispose();
    _signName.dispose();
    _signUser.dispose();
    _signPass.dispose();
    _signPassConfirm.dispose();
    super.dispose();
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
            ...users.map(
              (user) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF2563EB),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePage(bool isLogin) {
    if (_isLoginSelected == isLogin) return;
    setState(() => _isLoginSelected = isLogin);
    _pageController.animateToPage(
      isLogin ? 0 : 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleLogin() async {
    final String username = _loginUser.text.trim();
    final String password = _loginPass.text;

    if (username.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both username and password')),
      );
      return;
    }

    final user = await _db.loginUser(username, password);
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username atau Password salah')),
      );
      return;
    }
    _doLogin(user);
  }

  void _handleRegister() async {
    final String name = _signName.text.trim();
    final String username = _signUser.text.trim();
    final String password = _signPass.text;
    final String passwordConfirm = _signPassConfirm.text;

    if (name.isEmpty || username.isEmpty || password.isEmpty || passwordConfirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    if (password != passwordConfirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak cocok')),
      );
      return;
    }

    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name must be at least 2 characters')),
      );
      return;
    }

    if (username.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username must be at least 3 characters')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    final exist = await _db.getUserByUsername(username);
    if (exist != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username sudah digunakan')),
      );
      return;
    }

    final hashedPassword = User.hashPassword(password);
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      username: username,
      password: hashedPassword,
      position: _selectedPosition,
      skillLevel: _skillLevel.toInt(),
      role: _selectedRole,
    );

    await _db.registerUser(newUser);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Registrasi Berhasil!"),
        backgroundColor: Colors.green,
      ),
    );
    _togglePage(true);
  }

  void _doLogin(User user) {
    AuthManager().login(user);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = const Color.fromARGB(255, 38, 101, 236);
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            // Subtle basketball court lines in background
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: CustomPaint(
                  painter: _CourtLinesPainter(),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    top: topPadding + 16,
                    left: 24,
                    right: 24,
                    bottom: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sports_basketball,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isLoginSelected ? "Welcome\nBack" : "Create your\naccount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLoginSelected
                            ? "Sign in to run some play!"
                            : "Sign up to start ballin",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      children: [
                        // Subtle grab handle
                        Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildToggle(primaryBlue),
                        const SizedBox(height: 28),
                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              _buildLoginForm(primaryBlue),
                              _buildSignupForm(primaryBlue),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(Color primaryBlue) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _toggleItem(
              "Login",
              _isLoginSelected,
              primaryBlue,
              () => _togglePage(true),
            ),
          ),
          Expanded(
            child: _toggleItem(
              "Register",
              !_isLoginSelected,
              primaryBlue,
              () => _togglePage(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleItem(
    String label,
    bool active,
    Color primaryBlue,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: active ? primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(23),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(Color primaryBlue) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInputField(
            controller: _loginUser,
            hint: "Username",
            icon: Icons.person_outline,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9_\.]")),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _loginPass,
            hint: "Password",
            icon: Icons.lock_outline,
            isPassword: true,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r"\s")),
            ],
          ),
          const SizedBox(height: 40),
          _buildActionButton("Login", primaryBlue, _handleLogin),
          if (_biometricAvailable && _hasBiometricUsers) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loginWithBiometric,
              icon: Icon(Icons.fingerprint, color: primaryBlue),
              label: Text(
                "Login with Biometrics",
                style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSignupForm(Color primaryBlue) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInputField(
            controller: _signName,
            hint: "Full Name",
            icon: Icons.badge_outlined,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z\s\.]")),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _signUser,
            hint: "Username",
            icon: Icons.person_outline,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[a-zA-Z0-9_\.]")),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _signPass,
            hint: "Password",
            icon: Icons.lock_outline,
            isPassword: true,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r"\s")),
            ],
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _signPassConfirm,
            hint: "Confirm Password",
            icon: Icons.lock_outline,
            isPassword: true,
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r"\s")),
            ],
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Account Type",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text("Player")),
                  selected: _selectedRole == 'player',
                  selectedColor: primaryBlue,
                  labelStyle: TextStyle(
                    color: _selectedRole == 'player' ? Colors.white : const Color(0xFF475569),
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedRole = 'player');
                  },
                  backgroundColor: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(
                    color: _selectedRole == 'player' ? Colors.transparent : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text("Court Owner")),
                  selected: _selectedRole == 'owner',
                  selectedColor: primaryBlue,
                  labelStyle: TextStyle(
                    color: _selectedRole == 'owner' ? Colors.white : const Color(0xFF475569),
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedRole = 'owner');
                  },
                  backgroundColor: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(
                    color: _selectedRole == 'owner' ? Colors.transparent : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
            ],
          ),
          if (_selectedRole == 'player') ...[
            const SizedBox(height: 20),
            _buildPositionDropdown(),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text("Skill: ", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                Text(_skillLevel.toInt().toString(), style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _skillLevel,
              min: 1,
              max: 100,
              activeColor: primaryBlue,
              inactiveColor: const Color(0xFFE2E8F0),
              onChanged: (val) => setState(() => _skillLevel = val),
            ),
          ],
          const SizedBox(height: 30),
          _buildActionButton("Register", primaryBlue, _handleRegister),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 15, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [color, color.withRed((color.red + 30).clamp(0, 255))],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildPositionDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Position>(
          value: _selectedPosition,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.w500),
          onChanged: (val) => setState(() => _selectedPosition = val!),
          items: Position.values
              .map((p) => DropdownMenuItem(value: p, child: Text(p.fullName)))
              .toList(),
        ),
      ),
    );
  }
}

class _CourtLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw center circle line
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.16), 50, paint);
    canvas.drawCircle(Offset(size.width / 2, size.height * 0.16), 4, paint);

    // Draw half-court line
    canvas.drawLine(
      Offset(0, size.height * 0.16),
      Offset(size.width, size.height * 0.16),
      paint,
    );

    // Draw three-point arc
    // Basket at X = width/2, Y = 25
    final basketOffset = Offset(size.width / 2, 25);
    canvas.drawArc(
      Rect.fromCircle(center: basketOffset, radius: 150),
      0,
      math.pi,
      false,
      paint,
    );

    // Draw the key (restricted area)
    final keyRect = Rect.fromLTRB(
      size.width / 2 - 40,
      0,
      size.width / 2 + 40,
      90,
    );
    canvas.drawRect(keyRect, paint);

    // Draw free throw circle
    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width / 2, 90), radius: 40),
      0,
      math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
