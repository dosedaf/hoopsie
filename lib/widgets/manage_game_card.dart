import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game.dart';

class ManageGameCard extends StatelessWidget {
  final Game game;
  final bool isMyGame;
  final VoidCallback? onDelete;
  final VoidCallback? onLeave;
  final VoidCallback? onTap;

  const ManageGameCard({
    super.key,
    required this.game,
    required this.isMyGame,
    this.onDelete,
    this.onLeave,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String timeRange =
        "${DateFormat('MMM d, HH:mm').format(game.startTime)} - ${DateFormat('HH:mm').format(game.endTime)}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      game.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildRoleBadge(),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.calendar_today, timeRange),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.location_on_outlined,
                  game.courtName ?? game.courtId,
                ),
                const Divider(height: 24, thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHostInfo(),
                    // This is where we use your "Leave" and "Delete" logic
                    isMyGame ? _buildHostActions() : _buildParticipantActions(),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMyGame
            ? Colors.purple.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isMyGame ? "HOSTING" : "JOINED",
        style: TextStyle(
          color: isMyGame ? Colors.purple : Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildHostActions() {
    return TextButton.icon(
      onPressed: onDelete,
      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
      label: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
    );
  }

  Widget _buildParticipantActions() {
    return OutlinedButton.icon(
      onPressed: onLeave,
      icon: const Icon(Icons.exit_to_app, size: 16, color: Colors.orange),
      label: Text(
        game.currentUserStatus == 'approved' ? "Leave" : "Cancel Request",
        style: const TextStyle(color: Colors.orange),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.orange),
      ),
    );
  }

  // Helper UI methods
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }

  Widget _buildHostInfo() {
    return Row(
      children: [
        const CircleAvatar(radius: 12, child: Icon(Icons.person, size: 14)),
        const SizedBox(width: 8),
        Text(
          "By ${game.hostName ?? 'User'}",
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
