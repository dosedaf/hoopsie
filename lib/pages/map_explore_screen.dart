import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geodesy/geodesy.dart' as geo;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/game.dart';
import '../models/court.dart';
import '../services/database_service.dart';

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

      final position = await Geolocator.getCurrentPosition();
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
    TimeOfDay opening = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay closing = const TimeOfDay(hour: 22, minute: 0);
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Add New Court Details"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Court Name"),
                  ),
                  const SizedBox(height: 15),
                  _buildImagePicker(setDialogState, picker),
                  const SizedBox(height: 15),
                  _buildTimePickers(context, setDialogState, opening, closing, (
                    newOp,
                    newCl,
                  ) {
                    opening = newOp;
                    closing = newCl;
                  }),
                  _buildDropdowns(setDialogState),
                  TextField(
                    controller: courtCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Number of Courts",
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) return;
                  String? savedPath;
                  if (_tempFile != null)
                    savedPath = await _saveImagePermanently(_tempFile!.path);

                  await _db.saveCourtExtended(
                    nameController.text.trim(),
                    point.latitude,
                    point.longitude,
                    "${opening.hour.toString().padLeft(2, '0')}:${opening.minute.toString().padLeft(2, '0')}",
                    "${closing.hour.toString().padLeft(2, '0')}:${closing.minute.toString().padLeft(2, '0')}",
                    _selectedType,
                    _selectedSize,
                    int.tryParse(courtCountController.text) ?? 1,
                    _selectedSurface,
                    savedPath,
                  );
                  if (mounted) {
                    _tempFile = null;
                    Navigator.pop(context);
                    setState(() {
                      _mapDataFuture = _buildMapFuture();
                    });
                  }
                },
                child: const Text("Save Court"),
              ),
            ],
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
                    onLongPress: (_, point) => _showAddCourtDialog(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.ta_tes.hoopsie',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: geo.LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                        ...allCourts.map(
                          (c) => Marker(
                            point: geo.LatLng(c.lat, c.lng),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => _showCourtOnlyPreview(c),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        ...games.map(
                          (g) => Marker(
                            point: geo.LatLng(g.courtLat, g.courtLng),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => _showGamePreview(g),
                              child: const Icon(
                                Icons.sports_basketball,
                                color: Colors.orange,
                                size: 35,
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
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  court.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text("${court.type} • ${court.surface} Surface"),
              subtitle: Text(
                "Hours: ${court.openingTime} - ${court.closingTime}",
              ),
            ),
            ListTile(
              leading: const Icon(Icons.grid_4x4),
              title: Text(
                "${court.courtCount} ${court.size} Court(s) Available",
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Host Game Here"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}