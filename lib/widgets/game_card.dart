import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game.dart';

class GameCard extends StatelessWidget {
  final Game game;
  final bool isMyGame;
  final VoidCallback? onDelete;
  final VoidCallback? onJoin;
  final VoidCallback? onTap;

  const GameCard({
    super.key,
    required this.game,
    required this.isMyGame,
    this.onDelete,
    this.onJoin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String timeRange =
        "${DateFormat('MMM d, HH:mm').format(game.startTime)} - ${DateFormat('HH:mm').format(game.endTime)}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      // REMOVED padding: const EdgeInsets.all(16) from here
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
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
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      game.courtName ?? game.courtId,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(height: 24, thickness: 0.5),
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
                          "Hosted by ${game.hostName ?? 'Unknown User'}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
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
                      Builder(
                        builder: (context) {
                          if (game.currentUserStatus == 'pending') {
                            return ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.withOpacity(0.5),
                              ),
                              child: const Text("Requested"),
                            );
                          } else if (game.currentUserStatus == 'approved') {
                            return ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.withOpacity(0.5),
                              ),
                              child: const Text("Joined"),
                            );
                          } else {
                            return ElevatedButton(
                              onPressed: onJoin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text("Join Game"),
                            );
                          }
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
