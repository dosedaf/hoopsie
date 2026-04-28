import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/court.dart';
import '../services/database_service.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
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
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final minute = dt.minute.toString().padLeft(2, '0');
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour}:$minute";
  }

  Future<void> _saveGame() async {
    if (_nameController.text.isEmpty ||
        selectedCourt == null ||
        selectedStartTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi nama game, lapangan, dan waktu mulai.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newGame = Game(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      hostId: _db.currentUserId,
      courtId: selectedCourt!.id,
      startTime: selectedStartTime!,
      endTime: selectedEndTime!,
      type: selectedType,
    );

    await _db.insertGame(newGame);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Widget _durationChip(String label, Duration duration) {
    final isSelected = selectedDuration == duration;
    return InkWell(
      onTap: () {
        setState(() {
          selectedDuration = duration;
          if (selectedStartTime != null) {
            selectedEndTime = selectedStartTime!.add(selectedDuration);
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2A52BE) : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF2A52BE) : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showCustomDurationDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Durasi (Menit)"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Contoh: 90"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                final minutes = int.tryParse(controller.text);
                if (minutes != null && minutes > 0) {
                  setState(() {
                    selectedDuration = Duration(minutes: minutes);
                    if (selectedStartTime != null) {
                      selectedEndTime = selectedStartTime!.add(
                        selectedDuration,
                      );
                    }
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buat Game',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Game',
                      prefixIcon: const Icon(Icons.sports_basketball),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<Court>(
                    value: selectedCourt,
                    decoration: InputDecoration(
                      labelText: 'Pilih Lapangan',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _availableCourts
                        .map(
                          (court) => DropdownMenuItem(
                            value: court,
                            child: Text(court.name),
                          ),
                        )
                        .toList(),
                    onChanged: (court) => setState(() => selectedCourt = court),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tipe Game',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<GameType>(
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
                  const SizedBox(height: 24),
                  // Time Picker Section
                  ListTile(
                    title: Text(
                      selectedStartTime == null
                          ? "Pilih Waktu Mulai"
                          : _formatDateTime(selectedStartTime!),
                    ),
                    trailing: const Icon(
                      Icons.calendar_month,
                      color: Color(0xFF2A52BE),
                    ),
                    onTap: () async {
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
                        selectedEndTime = selectedStartTime!.add(
                          selectedDuration,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      _durationChip("30m", const Duration(minutes: 30)),
                      _durationChip("1j", const Duration(hours: 1)),
                      _durationChip("1.5j", const Duration(minutes: 90)),
                      _durationChip("2j", const Duration(hours: 2)),
                      _durationChip("Custom", Duration.zero),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A52BE),
                  ),
                  onPressed: _saveGame,
                  child: const Text(
                    'Publish Game',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
