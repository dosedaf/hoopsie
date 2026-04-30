import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  Position _selectedPosition = Position.pg;
  double _skillLevel = 50;

  void _register() async {
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      username: _userController.text,
      password: _passController.text,
      position: _selectedPosition,
      skillLevel: _skillLevel.toInt(),
    );

    await DatabaseService().registerUser(newUser);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Registrasi Berhasil!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Akun")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Nama Lengkap"),
            ),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            const Text("Pilih Posisi"),
            DropdownButton<Position>(
              value: _selectedPosition,
              isExpanded: true,
              onChanged: (val) => setState(() => _selectedPosition = val!),
              items: Position.values
                  .map(
                    (p) => DropdownMenuItem(value: p, child: Text(p.fullName)),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text("Skill Level: ${_skillLevel.toInt()}"),
            Slider(
              value: _skillLevel,
              min: 1,
              max: 100,
              onChanged: (val) => setState(() => _skillLevel = val),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _register,
              child: const Text("Daftar Sekarang"),
            ),
          ],
        ),
      ),
    );
  }
}
