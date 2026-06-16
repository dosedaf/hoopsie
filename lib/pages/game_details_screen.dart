import 'package:flutter/material.dart';
import '../models/game.dart';
import '../services/database_service.dart';
import '../services/auth_manager.dart';
import 'court_payments_screen.dart';

class GameDetailsScreen extends StatefulWidget {
  final Game game;
  const GameDetailsScreen({super.key, required this.game});

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  final DatabaseService _db = DatabaseService();
  final String? _currentUserId = AuthManager().currentUserId;
  late Future<List<dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _dataFuture = Future.wait([
      _db.getParticipantsWithDetails(widget.game.id),
      _db.getPaymentForGame(widget.game.id),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bool isHost = widget.game.hostId == _currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.game.name,
          style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final List<Map<String, dynamic>> participants = 
              List<Map<String, dynamic>>.from(snapshot.data?[0] ?? []);
          final Map<String, dynamic>? payment = snapshot.data?[1];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPaymentCard(payment, isHost),
              const SizedBox(height: 8),
              const Text(
                "Participants List",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 12),
              if (participants.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text("No participants yet for this game.")),
                )
              else
                ...participants.map((p) {
                  final String status = p['member_status'] ?? 'pending';
                  final String recordId = p['member_record_id'] ?? '';
                  final String participantUserId = p['id']?.toString() ?? '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.person_outline, color: Color(0xFF2563EB)),
                      ),
                      title: Text(
                        p['name'] ?? 'Unknown Player',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      subtitle: Text(
                        "${p['position'] ?? 'N/A'} • Player Status",
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                      trailing:
                          (isHost &&
                              status == 'pending' &&
                              participantUserId != _currentUserId)
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () async {
                                if (recordId.isNotEmpty) {
                                  await _db.updateMemberStatus(
                                    recordId,
                                    'approved',
                                  );
                                  setState(() {
                                    _dataFuture = Future.wait([
                                      _db.getParticipantsWithDetails(widget.game.id),
                                      _db.getPaymentForGame(widget.game.id),
                                    ]);
                                  });
                                }
                              },
                              child: const Text("Accept"),
                            )
                          : _buildStatusIcon(status),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic>? payment, bool isHost) {
    if (payment == null) return const SizedBox();

    final status = payment['status'] ?? 'unpaid';
    Color statusColor = Colors.grey;
    String statusText = 'Unpaid';
    if (status == 'paid') {
      statusColor = Colors.orange;
      statusText = 'Pending Approval';
    } else if (status == 'approved') {
      statusColor = Colors.green;
      statusText = 'Confirmed';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.payment, color: Color(0xFF2563EB)),
                    SizedBox(width: 8),
                    Text(
                      "Court Rental Status",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusText.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Rental Amount:",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      "${(payment['amount'] as num).toStringAsFixed(2)} ${payment['currency']}",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      "Converted:",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      "${(payment['converted_amount'] as num).toStringAsFixed(2)} ${payment['converted_currency']}",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ],
            ),
            if (isHost && status == 'unpaid') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CourtPaymentsScreen()),
                    ).then((_) {
                      setState(() {
                        _dataFuture = Future.wait([
                          _db.getParticipantsWithDetails(widget.game.id),
                          _db.getPaymentForGame(widget.game.id),
                        ]);
                      });
                    });
                  },
                  child: const Text(
                    "Pay Rental Fee Now",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    if (status == 'approved') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Text(
          "Approved",
          style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 11),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Text(
        "Pending",
        style: TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}
