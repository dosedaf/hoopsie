import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../services/database_service.dart';
import '../services/osm_service.dart';
import 'package:geodesy/geodesy.dart' as geo;
import '../models/game.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MapExploreScreen extends StatefulWidget {
  const MapExploreScreen({super.key});

  @override
  State<MapExploreScreen> createState() => _MapExploreScreenState();
}

class _MapExploreScreenState extends State<MapExploreScreen> {
  final DatabaseService _db = DatabaseService();

  List<geo.LatLng> _detectedCourts = [];

  @override
  void initState() {
    super.initState();
    _loadOSMCourts();
  }

  Future<void> _loadOSMCourts() async {
    final courts = await OSMService.fetchNearbyBasketballCourts(
      -7.7956,
      110.3695,
    );
    setState(() => _detectedCourts = courts);
  }

  Future<String> _saveImagePermanently(String imagePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final name = "court_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final image = File(imagePath);
    final permanentImage = await image.copy('${directory.path}/$name');
    return permanentImage.path;
  }

  void _showAddCourtDialog(geo.LatLng point) {
    final nameController = TextEditingController();
    final ImagePicker picker = ImagePicker();
    File? tempFile;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Add New Court"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Court Name",
                      hintText: "e.g. Sritex Arena",
                    ),
                  ),
                  const SizedBox(height: 20),

                  InkWell(
                    onTap: () async {
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                      );
                      if (image != null) {
                        setDialogState(() {
                          tempFile = File(image.path);
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: tempFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(tempFile!, fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Tap to Take Photo",
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ],
                            ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter a court name"),
                      ),
                    );
                    return;
                  }

                  String? savedPath;
                  if (tempFile != null) {
                    savedPath = await _saveImagePermanently(tempFile!.path);
                  }

                  await _db.saveCourt(
                    nameController.text.trim(),
                    point.latitude,
                    point.longitude,
                    savedPath,
                  );

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
      body: FutureBuilder<List<Game>>(
        future: _db.getDiscoverableGames(),
        builder: (context, snapshot) {
          final games = snapshot.data ?? [];

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
                          size: 30,
                        ),
                      ),
                    ),
                  ),

                  ..._detectedCourts.map(
                    (pos) => Marker(
                      point: pos,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.blueGrey.withOpacity(0.5),
                        size: 20,
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
}
