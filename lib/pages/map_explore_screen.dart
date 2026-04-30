import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../services/database_service.dart';
import 'package:geodesy/geodesy.dart' as geo;
import '../models/game.dart';
import '../models/court.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class MapExploreScreen extends StatefulWidget {
  const MapExploreScreen({super.key});

  @override
  State<MapExploreScreen> createState() => _MapExploreScreenState();
}

class _MapExploreScreenState extends State<MapExploreScreen> {
  final DatabaseService _db = DatabaseService();

  File? _tempFile;
  String _selectedType = 'Outdoor';
  String _selectedSize = 'Full';
  String _selectedSurface = 'Concrete';

  Future<String> _saveImagePermanently(String imagePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final name = "court_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final image = File(imagePath);
    final permanentImage = await image.copy('${directory.path}/$name');
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
                  InkWell(
                    onTap: () async {
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (image != null) {
                        setDialogState(() {
                          _tempFile = File(image.path);
                        });
                      }
                    },
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: _tempFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_tempFile!, fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.photo_library, color: Colors.blue),
                                Text(
                                  "Pick from Gallery",
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: opening,
                          );
                          if (t != null) setDialogState(() => opening = t);
                        },
                        child: Text("Open: ${opening.format(context)}"),
                      ),
                      TextButton(
                        onPressed: () async {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: closing,
                          );
                          if (t != null) setDialogState(() => closing = t);
                        },
                        child: Text("Close: ${closing.format(context)}"),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    items: ['Indoor', 'Outdoor']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => _selectedType = v!),
                    decoration: const InputDecoration(labelText: "Type"),
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedSize,
                    items: ['Full', 'Half']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => _selectedSize = v!),
                    decoration: const InputDecoration(labelText: "Court Size"),
                  ),
                  TextField(
                    controller: courtCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Number of Courts",
                    ),
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedSurface,
                    items: ['Wood', 'Concrete', 'Rubber', 'Asphalt']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => _selectedSurface = v!),
                    decoration: const InputDecoration(labelText: "Surface"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _tempFile = null;
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isEmpty) return;

                  String? savedPath;
                  if (_tempFile != null) {
                    savedPath = await _saveImagePermanently(_tempFile!.path);
                  }

                  String openStr =
                      "${opening.hour.toString().padLeft(2, '0')}:${opening.minute.toString().padLeft(2, '0')}";
                  String closeStr =
                      "${closing.hour.toString().padLeft(2, '0')}:${closing.minute.toString().padLeft(2, '0')}";

                  await _db.saveCourtExtended(
                    nameController.text.trim(),
                    point.latitude,
                    point.longitude,
                    openStr,
                    closeStr,
                    _selectedType,
                    _selectedSize,
                    int.tryParse(courtCountController.text) ?? 1,
                    _selectedSurface,
                    savedPath,
                  );

                  _tempFile = null;
                  if (context.mounted) {
                    Navigator.pop(context);
                    setState(() {});
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
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_db.getDiscoverableGames(), _db.getAllCourts()]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Game> games = snapshot.data?[0] ?? [];
          final List<Court> allCourts = snapshot.data?[1] ?? [];

          return FlutterMap(
            options: MapOptions(
              initialCenter: geo.LatLng(-7.566, 110.831),
              initialZoom: 13,
              onLongPress: (tapPosition, point) => _showAddCourtDialog(point),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.ta_tes.hoopsie',
              ),
              MarkerLayer(
                markers: [
                  ...allCourts.map(
                    (court) => Marker(
                      point: geo.LatLng(court.lat, court.lng),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showCourtOnlyPreview(court),
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  ...games.map(
                    (game) => Marker(
                      point: geo.LatLng(game.courtLat, game.courtLng),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showGamePreview(game),
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
