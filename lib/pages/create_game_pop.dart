import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/court.dart';
import '../services/database_service.dart';
import 'dart:io';

class CreateGamePop extends StatefulWidget {
  const CreateGamePop({super.key});

  @override
  State<CreateGamePop> createState() => _CreateGamePopState();
}

class _CreateGamePopState extends State<CreateGamePop> {
  final DatabaseService _db = DatabaseService();
  final _nameController = TextEditingController();

  List<Court> _availableCourts = [];
  GameType selectedType = GameType.fiveOnFive;
  Court? selectedCourt;
  DateTime? selectedStartTime;
  DateTime? selectedEndTime;
  Duration selectedDuration = const Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    final courts = await _db.getAllCourts();
    setState(() => _availableCourts = courts);
  }

  String _formatDateTime(DateTime dt) {
    final minute = dt.minute.toString().padLeft(2, '0');
    return "${dt.day}/${dt.month}/${dt.year} - ${dt.hour}:$minute";
  }

  Future<void> _saveGame() async {
    final userId = _db.currentUserId;

    if (_nameController.text.isEmpty ||
        selectedCourt == null ||
        selectedStartTime == null ||
        userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi detail game atau pastikan Anda sudah login'),
        ),
      );
      return;
    }

    final newGame = Game(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      hostId: userId,
      courtId: selectedCourt!.id,
      courtLat: selectedCourt!.lat,
      courtLng: selectedCourt!.lng,
      courtName: selectedCourt!.name,
      startTime: selectedStartTime!,
      endTime: selectedEndTime!,
      type: selectedType,
    );

    await _db.insertGame(newGame);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // Handles keyboard
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Elegant Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Buat Game Baru",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: "Nama Game",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<Court>(
                    value: selectedCourt,
                    decoration: InputDecoration(
                      hintText: "Pilih Lapangan",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _availableCourts
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.name)),
                        )
                        .toList(),
                    onChanged: (court) => setState(() => selectedCourt = court),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "Tipe Game",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<GameType>(
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: const Color(0xFF2A52BE),
                        selectedForegroundColor: Colors.white,
                      ),
                      segments: const [
                        ButtonSegment(
                          value: GameType.oneOnOne,
                          label: Text('1v1'),
                        ),
                        ButtonSegment(
                          value: GameType.threeOnThree,
                          label: Text('3v3'),
                        ),
                        ButtonSegment(
                          value: GameType.fiveOnFive,
                          label: Text('5v5'),
                        ),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (newSelection) =>
                          setState(() => selectedType = newSelection.first),
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "Waktu & Durasi",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),

                  InkWell(
                    onTap: _pickDateTime,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Color(0xFF2A52BE),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedStartTime == null
                                ? "Pilih Waktu Mulai"
                                : _formatDateTime(selectedStartTime!),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _durationChip("30m", const Duration(minutes: 30)),
                        _durationChip("1j", const Duration(hours: 1)),
                        _durationChip("1.5j", const Duration(minutes: 90)),
                        _durationChip("2j", const Duration(hours: 2)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A52BE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saveGame,
                      child: const Text(
                        "Publish Game",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _durationChip(String label, Duration duration) {
    final isSelected = selectedDuration == duration;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            selectedDuration = duration;
            if (selectedStartTime != null)
              selectedEndTime = selectedStartTime!.add(duration);
          });
        },
        selectedColor: const Color(0xFF2A52BE).withOpacity(0.1),
        checkmarkColor: const Color(0xFF2A52BE),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF2A52BE) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: DateTime.now(),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      selectedStartTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      selectedEndTime = selectedStartTime!.add(selectedDuration);
    });
  }
}
