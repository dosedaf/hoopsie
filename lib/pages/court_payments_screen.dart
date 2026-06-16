import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/auth_manager.dart';

class CourtPaymentsScreen extends StatefulWidget {
  const CourtPaymentsScreen({super.key});

  @override
  State<CourtPaymentsScreen> createState() => _CourtPaymentsScreenState();
}

class _CourtPaymentsScreenState extends State<CourtPaymentsScreen> with SingleTickerProviderStateMixin {
  final DatabaseService _db = DatabaseService();
  final String _currentUserId = AuthManager().currentUserId ?? '';
  late TabController _tabController;
  bool _isLoading = true;
  bool _isOwner = false;

  List<Map<String, dynamic>> _hostPayments = [];
  List<Map<String, dynamic>> _ownerPayments = [];
  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    final user = AuthManager().currentUser;
    _isOwner = user?.role == 'owner';
    _tabController = TabController(length: _isOwner ? 2 : 1, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final hostPays = await _db.getPaymentsForHost(_currentUserId);
      final ownerPays = await _db.getPaymentsForOwner(_currentUserId);

      // Calculate earnings from approved owner payments
      double balance = 0.0;
      for (final p in ownerPays) {
        if (p['status'] == 'approved') {
          balance += (p['amount'] as num).toDouble();
        }
      }

      setState(() {
        _hostPayments = hostPays;
        _ownerPayments = ownerPays;
        _walletBalance = balance;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading payments: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _processPayment(Map<String, dynamic> payment) async {
    String selectedMethod = 'Bank Transfer';
    final methods = ['Bank Transfer', 'Virtual Account', 'BCA KlikPay', 'GoPay', 'OVO', 'Credit Card'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Complete Rental Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Court: ${payment['court_name']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Game: ${payment['game_name']}'),
              const SizedBox(height: 12),
              const Text('Transfer to Owner Bank Details:', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
              Text('Bank: ${payment['bank_name'] ?? 'N/A'}'),
              Text('Account No: ${payment['bank_account'] ?? 'N/A'}'),
              Text('Owner/Payee Name: ${payment['owner_name'] ?? 'Unknown Owner'}'),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Amount Due:'),
                  Text(
                    '${(payment['amount'] as num).toStringAsFixed(2)} ${payment['currency']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Converted Price:'),
                  Text(
                    '${(payment['converted_amount'] as num).toStringAsFixed(2)} ${payment['converted_currency']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: const InputDecoration(labelText: 'Payment Method'),
                items: methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedMethod = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
              onPressed: () async {
                await _db.updatePaymentStatus(
                  payment['id'],
                  'paid',
                  paidAt: DateTime.now().toIso8601String(),
                  paymentMethod: selectedMethod,
                );
                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Payment submitted! Awaiting owner confirmation.'), backgroundColor: Colors.green),
                );
              },
              child: const Text('I Have Paid', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmPayment(Map<String, dynamic> payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payment Receipt'),
        content: Text(
          'Confirm that you have received ${(payment['amount'] as num).toStringAsFixed(2)} ${payment['currency']} '
          '(${ (payment['converted_amount'] as num).toStringAsFixed(2) } ${payment['converted_currency']}) '
          'from host ${payment['host_name']} for renting ${payment['court_name']}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Confirm Receipt', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.updatePaymentStatus(payment['id'], 'approved');
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment confirmed! Funds added to your wallet.'), backgroundColor: Colors.green),
      );
    }
  }

  void _showInvoice(Map<String, dynamic> payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 12),
            const Text(
              'RENTAL INVOICE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            Text(
              'Invoice Ref: ${payment['id']}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const Divider(height: 32),
            _buildInvoiceRow('Court Name', payment['court_name']),
            _buildInvoiceRow('Game', payment['game_name']),
            _buildInvoiceRow('Host (Payer)', payment['host_name'] ?? payment['owner_name'] ?? 'Guest'),
            _buildInvoiceRow('Payment Method', payment['payment_method'] ?? 'N/A'),
            _buildInvoiceRow('Payment Date', payment['paid_at'] != null 
                ? payment['paid_at'].toString().split('T')[0] 
                : 'N/A'),
            const Divider(height: 32),
            _buildInvoiceRow('Original Price', '${(payment['amount'] as num).toStringAsFixed(2)} ${payment['currency']}'),
            _buildInvoiceRow(
              'Converted Amount Paid', 
              '${(payment['converted_amount'] as num).toStringAsFixed(2)} ${payment['converted_currency']}',
              isBold: true,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text('Download Receipt PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isOwner ? 'Court Payments Hub' : 'My Court Rentals', style: const TextStyle(fontWeight: FontWeight.bold)),
        bottom: _isOwner
            ? TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF2563EB),
                labelColor: const Color(0xFF2563EB),
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'My Rentals (Host)'),
                  Tab(text: 'My Earnings (Owner)'),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _isOwner
                  ? [
                      _buildHostRentalsTab(),
                      _buildOwnerEarningsTab(),
                    ]
                  : [
                      _buildHostRentalsTab(),
                    ],
            ),
    );
  }

  Widget _buildHostRentalsTab() {
    if (_hostPayments.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No rental bookings found.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _hostPayments.length,
      itemBuilder: (context, index) {
        final pay = _hostPayments[index];
        final String status = pay['status'];

        Color badgeColor = Colors.grey;
        String statusText = 'UNPAID';
        if (status == 'paid') {
          badgeColor = Colors.orange;
          statusText = 'PENDING APPROVAL';
        } else if (status == 'approved') {
          badgeColor = Colors.green;
          statusText = 'APPROVED';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.15)),
          ),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Text(
                      pay['created_at'].toString().split('T')[0],
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  pay['court_name'],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Game: ${pay['game_name']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Original price', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        Text(
                          '${(pay['amount'] as num).toStringAsFixed(2)} ${pay['currency']}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(width: 40),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Converted Cost', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        Text(
                          '${(pay['converted_amount'] as num).toStringAsFixed(2)} ${pay['converted_currency']}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: status == 'unpaid'
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _processPayment(pay),
                          child: const Text('Pay to Owner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        )
                      : OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2563EB)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => _showInvoice(pay),
                          icon: const Icon(Icons.receipt_long, color: Color(0xFF2563EB), size: 18),
                          label: const Text('View Receipt', style: TextStyle(color: Color(0xFF2563EB))),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOwnerEarningsTab() {
    return Column(
      children: [
        // Wallet Card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Court Owner Wallet',
                    style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  Icon(Icons.account_balance_wallet, color: Colors.white.withOpacity(0.8)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Rp ${_walletBalance.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Withdraw Funds'),
                          content: Text('Your withdraw request of Rp ${_walletBalance.toStringAsFixed(2)} has been successfully submitted! It will arrive in your bank account shortly.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    label: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Rental Transactions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),

        Expanded(
          child: _ownerPayments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No rental transactions received.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _ownerPayments.length,
                  itemBuilder: (context, index) {
                    final pay = _ownerPayments[index];
                    final String status = pay['status'];

                    Color badgeColor = Colors.grey;
                    String statusText = 'UNPAID';
                    if (status == 'paid') {
                      badgeColor = Colors.orange;
                      statusText = 'AWAITING CONFIRMATION';
                    } else if (status == 'approved') {
                      badgeColor = Colors.green;
                      statusText = 'CONFIRMED';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.withOpacity(0.15)),
                      ),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: badgeColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                Text(
                                  pay['created_at'].toString().split('T')[0],
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              pay['court_name'],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Payer: ${pay['host_name'] ?? 'Host'} • Game: ${pay['game_name']}',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Earnings Amount', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                                    Text(
                                      '${(pay['amount'] as num).toStringAsFixed(2)} ${pay['currency']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ],
                                ),
                                if (status == 'paid')
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () => _confirmPayment(pay),
                                    child: const Text('Confirm Cash', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  )
                                else if (status == 'approved')
                                  IconButton(
                                    icon: const Icon(Icons.receipt_long, color: Color(0xFF2563EB)),
                                    onPressed: () => _showInvoice(pay),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
