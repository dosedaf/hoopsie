import 'package:flutter/material.dart';
import 'package:ta_tes/pages/main_navigation.dart';
import '../services/database_service.dart';
import '../services/auth_manager.dart';
import '../services/biometric_service.dart';
import '../models/user.dart';
import 'package:flutter/services.dart';

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
  Position _selectedPosition = Position.pg;
  double _skillLevel = 50;

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
                  backgroundColor: const Color(0xFF2A52BE),
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
    final user = await _db.loginUser(_loginUser.text.trim(), _loginPass.text);
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
    final exist = await _db.getUserByUsername(_signUser.text.trim());
    if(exist != null){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username sudah digunakan'),
        ),
      );
      return;
    }
    
    if (_signName.text.trim().isEmpty || _signUser.text.trim().isEmpty || _signPass.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua field harus diisi'),
        ),
      );
      return;
    }

    final hashedPassword = User.hashPassword(_signPass.text);
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _signName.text,
      username: _signUser.text,
      password: hashedPassword,
      position: _selectedPosition,
      skillLevel: _skillLevel.toInt(),
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
    final Color primaryBlue = const Color(0xFF326CFA);
    final Color darkBgColor = const Color(0xFF1E283F);
    final double containerHeight = MediaQuery.of(context).size.height * 0.7;

    return Scaffold(
      backgroundColor: darkBgColor,
      body: Stack(
        children: [
          Positioned(
            top: 60,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.sports_basketball,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  _isLoginSelected ? "Welcome\nBack" : "Create your\naccount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLoginSelected
                      ? "Sign in to run some play!"
                      : "Sign up to start ballin",
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: containerHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                children: [
                  _buildToggle(primaryBlue),
                  const SizedBox(height: 32),
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
    );
  }

  Widget _buildToggle(Color primaryBlue) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(25),
      ),
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
      child: Container(
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? primaryBlue : Colors.grey,
            fontWeight: FontWeight.bold,
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
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _loginPass,
            hint: "Password",
            icon: Icons.lock_outline,
            isPassword: true,
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
                style: TextStyle(color: primaryBlue),
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
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _signPass,
            hint: "Password",
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 20),
          _buildPositionDropdown(),
          const SizedBox(height: 20),
          Slider(
            value: _skillLevel,
            min: 1,
            max: 100,
            activeColor: primaryBlue,
            onChanged: (val) => setState(() => _skillLevel = val),
          ),
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
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF1F4F9),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPositionDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Position>(
          value: _selectedPosition,
          isExpanded: true,
          onChanged: (val) => setState(() => _selectedPosition = val!),
          items: Position.values
              .map((p) => DropdownMenuItem(value: p, child: Text(p.fullName)))
              .toList(),
        ),
      ),
    );
  }
}
