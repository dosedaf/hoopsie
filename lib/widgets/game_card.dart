import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this to pubspec.yaml for date formatting
import '../models/game.dart';

class GameCard extends StatelessWidget {
  final Game game;
  final bool isMyGame;
  final VoidCallback? onDelete;

  const GameCard({
    super.key,
    required this.game,
    required this.isMyGame,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Format: "Oct 25, 14:00 - 16:00"
    final String timeRange =
        "${DateFormat('MMM d, HH:mm').format(game.startTime)} - ${DateFormat('HH:mm').format(game.endTime)}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Show the Game Name prominently
              Expanded(
                child: Text(
                  game.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              // Game Type Badge (e.g., 3v3)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  game.type.displayName,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Time Information
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                timeRange,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Location/Court Information
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(game.courtId, style: const TextStyle(color: Colors.grey)),
            ],
          ),

          const Divider(height: 24, thickness: 0.5),

          // Footer: Host Info and Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey[200],
                    child: const Icon(
                      Icons.person,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Hosted by ${game.hostId}",
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                ],
              ),
              if (isMyGame)
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                  label: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () {}, // Join logic
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Join Game"),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
