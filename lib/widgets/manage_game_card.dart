import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game.dart';

class ManageGameCard extends StatefulWidget {
  final Game game;
  final bool isMyGame;
  final VoidCallback? onDelete;
  final VoidCallback? onLeave;
  final VoidCallback? onTap;
  final Future<DateTime?> Function()? onReminder;

  const ManageGameCard({
    super.key,
    required this.game,
    required this.isMyGame,
    this.onDelete,
    this.onLeave,
    this.onTap,
    this.onReminder,
  });

  @override
  State<ManageGameCard> createState() => _ManageGameCardState();
}

class _ManageGameCardState extends State<ManageGameCard> {
  DateTime? _reminderTime;

  @override
  void initState() {
    super.initState();
    _loadReminderStatus();
  }

  Future<void> _loadReminderStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('reminder_${widget.game.id}');
    if (saved != null) {
      final dt = DateTime.tryParse(saved);
      if (dt != null && dt.isAfter(DateTime.now())) {
        setState(() => _reminderTime = dt);
      } else {
        await prefs.remove('reminder_${widget.game.id}');
      }
    }
  }

  String _formatReminderLabel() {
    if (_reminderTime == null) return '';
    final diff = _reminderTime!.difference(DateTime.now());
    if (diff.inHours >= 1) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return m > 0 ? 'Alerting in ${h}h ${m}m' : 'Alerting in ${h}h';
    }
    return 'Alerting in ${diff.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final String timeRange =
        "${DateFormat('MMM d, HH:mm').format(widget.game.startTime)} - ${DateFormat('HH:mm').format(widget.game.endTime)}";

    final bool hasReminder = _reminderTime != null;

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
          onTap: widget.onTap,
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
                      widget.game.name,
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
                  widget.game.courtName ?? widget.game.courtId,
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    if (widget.onReminder == null) return;
                    final scheduledTime = await widget.onReminder!();
                    if (scheduledTime != null) {
                      setState(() => _reminderTime = scheduledTime);
                    }
                  },
                  child: Row(
                    children: [
                      Icon(
                        hasReminder ? Icons.alarm_on : Icons.alarm_add,
                        size: 16,
                        color: hasReminder ? Colors.green : const Color(0xFF2A52BE),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasReminder ? _formatReminderLabel() : 'Set Reminder',
                        style: TextStyle(
                          color: hasReminder ? Colors.green : const Color(0xFF2A52BE),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24, thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildHostInfo(),
                    widget.isMyGame ? _buildHostActions() : _buildParticipantActions(),
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
        color: widget.isMyGame
            ? Colors.purple.withOpacity(0.1)
            : Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        widget.isMyGame ? "HOSTING" : "JOINED",
        style: TextStyle(
          color: widget.isMyGame ? Colors.purple : Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildHostActions() {
    return TextButton.icon(
      onPressed: widget.onDelete,
      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
      label: const Text("Delete", style: TextStyle(color: Colors.redAccent)),
    );
  }

  Widget _buildParticipantActions() {
    return OutlinedButton.icon(
      onPressed: widget.onLeave,
      icon: const Icon(Icons.exit_to_app, size: 16, color: Colors.orange),
      label: Text(
        widget.game.currentUserStatus == 'approved' ? "Leave" : "Cancel Request",
        style: const TextStyle(color: Colors.orange),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.orange),
      ),
    );
  }

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
          "By ${widget.game.hostName ?? 'User'}",
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}