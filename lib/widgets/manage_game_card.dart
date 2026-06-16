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

    // Status-specific themes
    final Color primaryColor = widget.isMyGame ? const Color(0xFF2A52BE) : Colors.orange[800]!;
    final Color accentBgColor = widget.isMyGame ? const Color(0xFFEFF6FF) : const Color(0xFFFFF7ED);
    final Color badgeColor = widget.isMyGame ? const Color(0xFF2A52BE) : Colors.orange[800]!;
    final String statusLabel = widget.isMyGame ? "HOSTING" : "JOINED";

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: primaryColor.withOpacity(0.15), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: primaryColor, width: 6),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
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
                            widget.game.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: badgeColor.withOpacity(0.2)),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.calendar_today, timeRange, primaryColor.withOpacity(0.75)),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      widget.game.courtName ?? widget.game.courtId,
                      Colors.redAccent.withOpacity(0.85),
                    ),
                    const SizedBox(height: 12),
                    
                    // Reminder bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: hasReminder ? Colors.green[50] : accentBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GestureDetector(
                        onTap: () async {
                          if (widget.onReminder == null) return;
                          final scheduledTime = await widget.onReminder!();
                          if (scheduledTime != null) {
                            setState(() => _reminderTime = scheduledTime);
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasReminder ? Icons.alarm_on : Icons.alarm_add,
                              size: 16,
                              color: hasReminder ? Colors.green[700] : primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              hasReminder ? _formatReminderLabel() : 'Set Reminder Alert',
                              style: TextStyle(
                                color: hasReminder ? Colors.green[700] : primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const Divider(height: 24, thickness: 0.5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildHostInfo(primaryColor),
                        widget.isMyGame ? _buildHostActions() : _buildParticipantActions(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge() {
    return const SizedBox();
  }

  Widget _buildHostActions() {
    return TextButton.icon(
      onPressed: widget.onDelete,
      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
      label: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildParticipantActions() {
    return OutlinedButton.icon(
      onPressed: widget.onLeave,
      icon: const Icon(Icons.exit_to_app, size: 16, color: Colors.orange),
      label: Text(
        widget.game.currentUserStatus == 'approved' ? "Leave" : "Cancel Request",
        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.orange),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHostInfo(Color color) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.person, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          "Host: ${widget.game.hostName ?? 'User'}",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}