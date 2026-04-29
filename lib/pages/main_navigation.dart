import 'package:flutter/material.dart';
import 'package:ta_tes/pages/currency_convert_screen.dart';
import 'package:ta_tes/pages/time_convert_screen.dart';
import 'package:ta_tes/pages/minigame_screen.dart';
import 'dashboard_screen.dart';
import 'manage_game_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardScreen(),
    const ManageGamesScreen(),
    const MinigameScreen(),
    const CurrencyConvertScreen(),
    const TimeConvertScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF2A52BE),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_basketball),
            label: 'My Games',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.videogame_asset),
            label: 'Minigame',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Currency',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Time'),
        ],
      ),
    );
  }
}
