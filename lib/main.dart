import 'package:flutter/material.dart';
import 'theme.dart';
import 'pages/login_screen.dart';
import 'services/database_service.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  try {
    final dbService = DatabaseService();
    await dbService.database;
    debugPrint("Database initialized successfully");
  } catch (e) {
    debugPrint("DATABASE ERROR: $e");
  }

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
