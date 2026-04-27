import 'package:flutter/material.dart';
import 'theme.dart';
import 'pages/login_screen.dart';

void main() {
  runApp(const HoopsieApp());
}

class HoopsieApp extends StatelessWidget {
  const HoopsieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hoopsie',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
