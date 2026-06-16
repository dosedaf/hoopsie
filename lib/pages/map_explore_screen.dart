import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geodesy/geodesy.dart' as geo;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/game.dart';
import '../models/court.dart';
import '../models/user.dart' hide Position;
import '../services/database_service.dart';
import '../services/auth_manager.dart';
import 'create_game_pop.dart';

class MapExploreScreen extends StatefulWidget {
  const MapExploreScreen({super.key});

  @override
  State<MapExploreScreen> createState() => _MapExploreScreenState();
}

class _MapExploreScreenState extends State<MapExploreScreen> {
  final DatabaseService _db = DatabaseService();
  Position? _currentPosition;
  bool _isLoadingLocation = true;
  File? _tempFile;
  String _selectedType = 'Outdoor';
  String _selectedSize = 'Full';
  String _selectedSurface = 'Concrete';
  late Future<List<dynamic>> _mapDataFuture;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _mapDataFuture = _buildMapFuture();
  }

  Future<List<dynamic>> _buildMapFuture() => Future.wait([
    _db.getDiscoverableGames(),
    _db.getAllCourts(),
  ]);

  Future<void> _initLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setFallbackLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setFallbackLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setFallbackLocation();
        return;
      }

      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      _setFallbackLocation();
    }
  }

  void _setFallbackLocation() {
    if (mounted) {
      setState(() {
        _currentPosition = Position(
          latitude: -7.7956,
          longitude: 110.3695,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
        _isLoadingLocation = false;
      });
    }
  }

  Future<String> _saveImagePermanently(String imagePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final name = "court_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final permanentImage = await File(
      imagePath,
    ).copy('${directory.path}/$name');
    return permanentImage.path;
  }

  void _showAddCourtDialog(geo.LatLng point) {
    final nameController = TextEditingController();
    final courtCountController = TextEditingController(text: "1");
    final priceController = TextEditingController(text: "0.0");
    String selectedCurrency = 'IDR';
    final bankNameController = TextEditingController();
    final bankAccountController = TextEditingController();
    TimeOfDay opening = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay closing = const TimeOfDay(hour: 22, minute: 0);
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final Color primaryBlue = const Color(0xFF2A52BE);
          
          return Container(
            padding: EdgeInsets.only(
              top: 24,
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Register New Court",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  const Text(
                    "Fill in the details below to add your court to the map.",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  
                  // SECTION 1: COURT PROFILE & PHOTO
                  const Text("1. COURT PROFILE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1.1)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Court Name",
                      prefixIcon: const Icon(Icons.stadium_outlined),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildImagePicker(setDialogState, picker),
                  const SizedBox(height: 16),
                  
                  // SECTION 2: HOURS & SPECS
                  const Text("2. HOURS & SPECIFICATIONS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1.1)),
                  const SizedBox(height: 8),
                  _buildTimePickers(context, setDialogState, opening, closing, (newOp, newCl) {
                    opening = newOp;
                    closing = newCl;
                  }),
                  const SizedBox(height: 12),
                  _buildDropdowns(setDialogState),
                  const SizedBox(height: 12),
                  TextField(
                    controller: courtCountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Number of Available Courts",
                      prefixIcon: const Icon(Icons.grid_4x4),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // SECTION 3: PRICING & PAYOUT
                  const Text("3. PRICING & PAYOUT (OPTIONAL)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, letterSpacing: 1.1)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: "Price / Hour",
                            prefixIcon: const Icon(Icons.monetization_on_outlined),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedCurrency,
                          decoration: InputDecoration(
                            labelText: "Currency",
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: ['IDR', 'USD', 'EUR', 'GBP', 'JPY', 'CNY', 'SGD']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => selectedCurrency = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bankNameController,
                    decoration: InputDecoration(
                      labelText: "Bank / E-Wallet Name",
                      hintText: "e.g., Bank Central Asia, GoPay",
                      prefixIcon: const Icon(Icons.account_balance),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bankAccountController,
                    decoration: InputDecoration(
                      labelText: "Bank Account / Account Number",
                      hintText: "e.g., 1234567890",
                      prefixIcon: const Icon(Icons.credit_card),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            final count = int.tryParse(courtCountController.text) ?? 0;
                            if (nameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a court name!'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }
                            if (count < 1) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid number of courts!'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }

                            String? savedPath;
                            if (_tempFile != null) {
                              savedPath = await _saveImagePermanently(_tempFile!.path);
                            }

                            final price = double.tryParse(priceController.text) ?? 0.0;
                            await _db.saveCourtExtended(
                              nameController.text.trim(),
                              point.latitude,
                              point.longitude,
                              "${opening.hour.toString().padLeft(2, '0')}:${opening.minute.toString().padLeft(2, '0')}",
                              "${closing.hour.toString().padLeft(2, '0')}:${closing.minute.toString().padLeft(2, '0')}",
                              _selectedType,
                              _selectedSize,
                              count,
                              _selectedSurface,
                              savedPath,
                              price: price,
                              currency: selectedCurrency,
                              bankName: bankNameController.text.trim(),
                              bankAccount: bankAccountController.text.trim(),
                            );

                            setState(() {
                              _tempFile = null;
                              _mapDataFuture = _buildMapFuture();
                            });

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Court registered successfully!'), backgroundColor: Colors.green),
                            );
                          },
                          child: const Text("Register", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nearby Courts")),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<dynamic>>(
              future: _mapDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final List<Game> games = snapshot.data![0];
                final List<Court> allCourts = snapshot.data![1];

                return FlutterMap(
                  options: MapOptions(
                    initialCenter: geo.LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    initialZoom: 14,
                    onLongPress: (_, point) {
                      final user = AuthManager().currentUser;
                      if (user != null && user.role == 'owner') {
                        _showAddCourtDialog(point);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Only Court Owners can add new courts!"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.ta_tes.hoopsie',
                    ),
                    MarkerLayer(
                      markers: [
                        // Current User Marker
                        Marker(
                          point: geo.LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          width: 45,
                          height: 45,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.4),
                                  blurRadius: 10,
                                  spreadRadius: 3,
                                ),
                              ],
                              border: Border.all(color: Colors.blue, width: 2),
                            ),
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                        ),
                        ...allCourts.map(
                          (c) => Marker(
                            point: geo.LatLng(c.lat, c.lng),
                            width: 45,
                            height: 45,
                            child: GestureDetector(
                              onTap: () => _showCourtOnlyPreview(c),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(color: const Color(0xFF2A52BE), width: 2.5),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.stadium,
                                    color: Color(0xFF2A52BE),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        ...games.map(
                          (g) => Marker(
                            point: geo.LatLng(g.courtLat, g.courtLng),
                            width: 45,
                            height: 45,
                            child: GestureDetector(
                              onTap: () => _showGamePreview(g),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.orange[850],
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.sports_basketball,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildImagePicker(StateSetter setDialogState, ImagePicker picker) {
    return InkWell(
      onTap: () async {
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );
        if (image != null) setDialogState(() => _tempFile = File(image.path));
      },
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: _tempFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_tempFile!, fit: BoxFit.cover),
              )
            : const Icon(Icons.photo_library, color: Colors.blue),
      ),
    );
  }

  Widget _buildTimePickers(
    BuildContext context,
    StateSetter setDialogState,
    TimeOfDay op,
    TimeOfDay cl,
    Function(TimeOfDay, TimeOfDay) onUpdate,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: () async {
            final t = await showTimePicker(context: context, initialTime: op);
            if (t != null) setDialogState(() => onUpdate(t, cl));
          },
          child: Text("Open: ${op.format(context)}"),
        ),
        TextButton(
          onPressed: () async {
            final t = await showTimePicker(context: context, initialTime: cl);
            if (t != null) setDialogState(() => onUpdate(op, t));
          },
          child: Text("Close: ${cl.format(context)}"),
        ),
      ],
    );
  }

  Widget _buildDropdowns(StateSetter setDialogState) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedType,
          items: [
            'Indoor',
            'Outdoor',
          ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
          onChanged: (v) => setDialogState(() => _selectedType = v!),
          decoration: const InputDecoration(labelText: "Type"),
        ),
        DropdownButtonFormField<String>(
          value: _selectedSurface,
          items: [
            'Wood',
            'Concrete',
            'Rubber',
            'Asphalt',
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setDialogState(() => _selectedSurface = v!),
          decoration: const InputDecoration(labelText: "Surface"),
        ),
        DropdownButtonFormField<String>(
          value: _selectedSize,
          items: [
            'Full',
            'Half',
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setDialogState(() => _selectedSize = v!),
          decoration: const InputDecoration(labelText: "Court Size"),
        ),
      ],
    );
  }

  void _showGamePreview(Game game) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (game.photoPath != null && game.photoPath!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(File(game.photoPath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Text(
              game.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(game.courtName, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("View Details"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCourtOnlyPreview(Court court) {
    final currentUserId = AuthManager().currentUserId;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            court.ownerId != null ? _db.getUserById(court.ownerId!) : Future.value(null),
            _db.getPaymentsForCourt(court.id),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final User? owner = snapshot.data?[0];
            final List<Map<String, dynamic>> payments = List<Map<String, dynamic>>.from(snapshot.data?[1] ?? []);
            
            final bool isCurrentUserOwner = court.ownerId != null && court.ownerId == currentUserId;
            final String ownerDisplayName = isCurrentUserOwner
                ? "You (Court Owner)"
                : (owner?.name ?? "No registered owner");

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              court.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(court.isOpenNow ? "OPEN" : "CLOSED"),
                            backgroundColor: court.isOpenNow
                                ? Colors.green[100]
                                : Colors.red[100],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person, color: Color(0xFF2A52BE)),
                        title: const Text("Court Operator / Owner"),
                        subtitle: Text(ownerDisplayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.info_outline),
                        title: Text("${court.type} • ${court.surface} Surface"),
                        subtitle: Text("Hours: ${court.openingTime} - ${court.closingTime}"),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.grid_4x4),
                        title: Text("${court.courtCount} ${court.size} Court(s) Available"),
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.monetization_on, color: Colors.green),
                        title: Text(
                          court.price > 0
                              ? "${court.price.toStringAsFixed(2)} ${court.currency} / Hour"
                              : "Free Court",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: court.bankName != null && court.bankName!.isNotEmpty
                            ? Text("Payout Account: ${court.bankName} (${court.bankAccount})")
                            : const Text("No payout details registered"),
                      ),
                      
                      // Payment tracking section
                      if (court.price > 0) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Court Rental Transactions",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Icon(Icons.history, color: Colors.grey[600], size: 20),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (payments.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: const Center(
                              child: Text(
                                "No rental payments recorded for this court yet.",
                                style: TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ...payments.map((p) {
                            final String status = p['status'] ?? 'unpaid';
                            Color statusColor = Colors.grey;
                            String statusLabel = 'Unpaid';
                            if (status == 'paid') {
                              statusColor = Colors.orange;
                              statusLabel = 'Pending Owner Confirm';
                            } else if (status == 'approved') {
                              statusColor = Colors.green;
                              statusLabel = 'Sent / Confirmed';
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p['game_name'] ?? 'Basketball Game',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                        Text(
                                          "Host: ${p['host_name']} • Date: ${p['created_at'].toString().split('T')[0]}",
                                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "${(p['converted_amount'] as num).toStringAsFixed(2)} ${p['converted_currency']}",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2A52BE)),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],

                      const SizedBox(height: 24),
                      if (currentUserId != court.ownerId) // Host can book games, owners don't book themselves
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2A52BE),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                useRootNavigator: true,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                builder: (_) => CreateGamePop(preselectedCourt: court),
                              );
                            },
                            child: const Text("Host Game Here", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}