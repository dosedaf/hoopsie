import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _mapFilter = 'all'; // 'all', 'games', 'courts'

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
          final Color primaryBlue = const Color(0xFF2563EB);
          
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
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                          ],
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "CURRENCY",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: ['IDR', 'USD', 'EUR', 'SGD']
                                  .map((c) => ChoiceChip(
                                        label: Text(c),
                                        selected: selectedCurrency == c,
                                        onSelected: (bool selected) {
                                          if (selected) {
                                            setDialogState(() => selectedCurrency = c);
                                          }
                                        },
                                        selectedColor: const Color(0xFF2563EB),
                                        backgroundColor: const Color(0xFFF1F5F9),
                                        labelStyle: TextStyle(
                                          color: selectedCurrency == c ? Colors.white : const Color(0xFF475569),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: BorderSide(
                                            color: selectedCurrency == c ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        elevation: 0,
                                        pressElevation: 0,
                                      ))
                                  .toList(),
                            ),
                          ],
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
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                            final String courtName = nameController.text.trim();
                            final count = int.tryParse(courtCountController.text) ?? 0;
                            
                            if (courtName.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a court name!'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }
                            if (courtName.length < 3) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Court name must be at least 3 characters!'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }
                            if (count < 1) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid number of courts!'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }

                            final String priceText = priceController.text.trim();
                            double price = 0.0;
                            if (priceText.isNotEmpty) {
                              final parsedPrice = double.tryParse(priceText);
                              if (parsedPrice == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please enter a valid price number!'), backgroundColor: Colors.redAccent),
                                );
                                return;
                              }
                              price = parsedPrice;
                            }

                            final String bankName = bankNameController.text.trim();
                            final String bankAccount = bankAccountController.text.trim();
                            if ((bankName.isNotEmpty && bankAccount.isEmpty) || (bankAccount.isNotEmpty && bankName.isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please provide both Bank Name and Account Number!'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }
                            if (bankAccount.isNotEmpty && bankAccount.length < 5) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bank account must be at least 5 digits long!'), backgroundColor: Colors.redAccent),
                              );
                              return;
                            }

                            String? savedPath;
                            if (_tempFile != null) {
                              savedPath = await _saveImagePermanently(_tempFile!.path);
                            }

                            await _db.saveCourtExtended(
                              courtName,
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
                              bankName: bankName,
                              bankAccount: bankAccount,
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

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _mapFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _mapFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

                final Set<String> courtsWithGames = games.map((g) => g.courtId).toSet();

                // Filter courts based on _mapFilter
                final filteredCourts = allCourts.where((c) {
                  if (_mapFilter == 'games') return false;
                  if (_mapFilter == 'courts') return true;
                  // 'all' -> only show courts that don't have games to prevent duplicate overlapping markers
                  return !courtsWithGames.contains(c.id);
                }).toList();

                // Filter games based on _mapFilter
                final filteredGames = _mapFilter == 'courts' ? <Game>[] : games;

                final user = AuthManager().currentUser;
                final bool isOwner = user?.role == 'owner';

                return Stack(
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: geo.LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        initialZoom: 14,
                        onLongPress: (_, point) {
                          if (isOwner) {
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
                              'https://basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.ta_tes.hoopsie',
                        ),
                        MarkerLayer(
                          markers: [
                            // Current User Marker - Big, glowing minimalist style
                            Marker(
                              point: geo.LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              width: 60,
                              height: 60,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF2563EB).withOpacity(0.15),
                                    ),
                                  ),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF2563EB).withOpacity(0.3),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                      border: Border.all(color: const Color(0xFF2563EB), width: 3),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.navigation,
                                        color: Color(0xFF2563EB),
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Court markers - bright vibrant electric royal blue style
                            ...filteredCourts.map(
                              (c) => Marker(
                                point: geo.LatLng(c.lat, c.lng),
                                width: 40,
                                height: 40,
                                child: GestureDetector(
                                  onTap: () => _showCourtOnlyPreview(c),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(color: const Color(0xFF2563EB), width: 2.5),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.stadium,
                                        color: Color(0xFF2563EB),
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Game markers - big, vibrant orange basketball style
                            ...filteredGames.map(
                              (g) => Marker(
                                point: geo.LatLng(g.courtLat, g.courtLng),
                                width: 48,
                                height: 48,
                                child: GestureDetector(
                                  onTap: () => _showGamePreview(g),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEA580C),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFEA580C).withOpacity(0.35),
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
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Floating top card overlay
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Explore Map",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      Text(
                                        isOwner
                                            ? "Long press map to add new court"
                                            : "Find courts & active matches near you",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOwner)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.2)),
                                    ),
                                    child: const Text(
                                      "OWNER",
                                      style: TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip('all', '📍 All'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('games', '🏀 Games Only'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('courts', '🏟️ Courts Only'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildChoiceChip<T>({
    required String label,
    required T value,
    required T selectedValue,
    required ValueChanged<T> onSelected,
  }) {
    final bool isSelected = value == selectedValue;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          onSelected(value);
        }
      },
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF475569),
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0,
      pressElevation: 0,
    );
  }

  Widget _buildSelectionRow({
    required String title,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildDropdowns(StateSetter setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectionRow(
          title: "COURT TYPE",
          child: Row(
            children: [
              _buildChoiceChip(
                label: "Indoor",
                value: "Indoor",
                selectedValue: _selectedType,
                onSelected: (val) => setDialogState(() => _selectedType = val),
              ),
              const SizedBox(width: 8),
              _buildChoiceChip(
                label: "Outdoor",
                value: "Outdoor",
                selectedValue: _selectedType,
                onSelected: (val) => setDialogState(() => _selectedType = val),
              ),
            ],
          ),
        ),
        _buildSelectionRow(
          title: "COURT SIZE",
          child: Row(
            children: [
              _buildChoiceChip(
                label: "Full Court",
                value: "Full",
                selectedValue: _selectedSize,
                onSelected: (val) => setDialogState(() => _selectedSize = val),
              ),
              const SizedBox(width: 8),
              _buildChoiceChip(
                label: "Half Court",
                value: "Half",
                selectedValue: _selectedSize,
                onSelected: (val) => setDialogState(() => _selectedSize = val),
              ),
            ],
          ),
        ),
        _buildSelectionRow(
          title: "SURFACE TYPE",
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Wood',
              'Concrete',
              'Rubber',
              'Asphalt',
            ].map((s) => _buildChoiceChip(
              label: s,
              value: s,
              selectedValue: _selectedSurface,
              onSelected: (val) => setDialogState(() => _selectedSurface = val),
            )).toList(),
          ),
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
                        leading: const Icon(Icons.person, color: Color(0xFF2563EB)),
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
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB)),
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
                              backgroundColor: const Color(0xFF2563EB),
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