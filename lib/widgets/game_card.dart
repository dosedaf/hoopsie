import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game.dart';

class GameCard extends StatelessWidget {
  final Game game;
  final bool isMyGame;
  final VoidCallback? onDelete;
  final VoidCallback? onJoin;
  final VoidCallback? onTap;
  final VoidCallback? onLeave;
  final int? matchScore;

  const GameCard({
    super.key,
    required this.game,
    required this.isMyGame,
    this.matchScore,
    this.onDelete,
    this.onJoin,
    this.onTap,
    this.onLeave,
  });

  @override
  Widget build(BuildContext context) {
    final String timeRange =
        "${DateFormat('MMM d, HH:mm').format(game.startTime)} - ${DateFormat('HH:mm').format(game.endTime)}";

    Color scoreColor = (matchScore ?? 0) >= 80 ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    
    // Type-based colors
    Color typeColor;
    switch (game.type) {
      case GameType.fiveOnFive:
        typeColor = const Color(0xFF2563EB);
        break;
      case GameType.threeOnThree:
        typeColor = const Color(0xFFF97316);
        break;
      case GameType.oneOnOne:
        typeColor = const Color(0xFF8B5CF6);
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(
          left: BorderSide(
            color: typeColor,
            width: 5,
          ),
        ),
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
                    Expanded(
                      child: Text(
                        game.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Match Quality Badge
                    if (matchScore != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: scoreColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: scoreColor.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt, size: 12, color: scoreColor),
                            const SizedBox(width: 2),
                            Text(
                              "$matchScore% Match",
                              style: TextStyle(
                                color: scoreColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    // Game Type Badge (1v1, 3v3, etc)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: typeColor.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        game.type.displayName,
                        style: TextStyle(
                          color: typeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: typeColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeRange,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 15,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        game.courtName ?? game.courtId,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 0.5, color: Color(0xFFE2E8F0)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFFF1F5F9),
                          child: const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Host: ${game.hostName ?? 'Unknown'}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (isMyGame)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                        label: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      )
                    else
                      _buildJoinButton(typeColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinButton(Color activeColor) {
    if (game.currentUserStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Text(
          "Requested",
          style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    } else if (game.currentUserStatus == 'approved') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Text(
          "Joined",
          style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: onJoin,
        style: ElevatedButton.styleFrom(
          backgroundColor: activeColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          "Join Game",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    }
  }
}
