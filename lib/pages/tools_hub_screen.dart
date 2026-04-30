import 'package:flutter/material.dart';
import 'currency_convert_screen.dart';
import 'time_convert_screen.dart';
import 'minigame_screen.dart';

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Utilities")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildToolCard(
            context,
            title: "Minigame",
            subtitle: "Take a break and play",
            icon: Icons.videogame_asset,
            color: Colors.orange,
            page: const MinigameScreen(),
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            context,
            title: "Currency Converter",
            subtitle: "Check exchange rates",
            icon: Icons.attach_money,
            color: Colors.green,
            page: const CurrencyConvertScreen(),
          ),
          const SizedBox(height: 16),
          _buildToolCard(
            context,
            title: "Time Converter",
            subtitle: "Sync with other timezones",
            icon: Icons.access_time,
            color: Colors.blue,
            page: const TimeConvertScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        ),
      ),
    );
  }
}
