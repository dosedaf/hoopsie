import 'package:flutter/material.dart';
import '../models/game.dart';
import '../models/court.dart';

class CreateGameScreen extends StatefulWidget {
  const CreateGameScreen({super.key});

  @override
  State<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends State<CreateGameScreen> {
  final _nameController = TextEditingController();

  GameType selectedType = GameType.fiveOnFive;
  Court? selectedCourt;
  DateTime? selectedStartTime;
  DateTime? selectedEndTime;
  Duration selectedDuration = const Duration(hours: 1);

  // Helper untuk merapikan format teks tanggal dan waktu
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

  Widget _customDurationChip() {
    return InkWell(
      onTap: _showCustomDurationDialog,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          "Custom",
          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black87),
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
          title: const Text("Durasi (Menit)", style: TextStyle(fontSize: 18)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "Contoh: 90",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A52BE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                final minutes = int.tryParse(controller.text);
                if (minutes == null || minutes <= 0) return;

                setState(() {
                  selectedDuration = Duration(minutes: minutes);
                  if (selectedStartTime != null) {
                    selectedEndTime = selectedStartTime!.add(selectedDuration);
                  }
                });
                Navigator.pop(context);
              },
              child: const Text(
                "Simpan",
                style: TextStyle(color: Colors.white),
              ),
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
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        centerTitle: true,
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
                      hintText: 'Contoh: Sparring Santai',
                      prefixIcon: const Icon(
                        Icons.sports_basketball,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  DropdownButtonFormField<Court>(
                    value: selectedCourt,
                    decoration: InputDecoration(
                      labelText: 'Pilih Lapangan',
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    items: mockCourts.map((court) {
                      return DropdownMenuItem(
                        value: court,
                        child: Text(court.name),
                      );
                    }).toList(),
                    onChanged: (court) => setState(() => selectedCourt = court),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Tipe Game',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<GameType>(
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
                      onSelectionChanged: (newSelection) {
                        setState(() => selectedType = newSelection.first);
                      },
                      style: ButtonStyle(
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            selectedStartTime == null
                                ? "Pilih Waktu Mulai"
                                : _formatDateTime(selectedStartTime!),
                            style: TextStyle(
                              fontWeight: selectedStartTime == null
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                              color: selectedStartTime == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A52BE).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: Color(0xFF2A52BE),
                            ),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2030),
                              initialDate: DateTime.now(),
                            );
                            if (date == null) return;

                            if (!mounted) return;
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
                        const Divider(height: 24),
                        const Text(
                          'Durasi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _durationChip("30m", const Duration(minutes: 30)),
                            _durationChip("1j", const Duration(hours: 1)),
                            _durationChip("1.5j", const Duration(minutes: 90)),
                            _durationChip("2j", const Duration(hours: 2)),
                            _customDurationChip(),
                          ],
                        ),
                        if (selectedEndTime != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Berakhir pada: ${_formatDateTime(selectedEndTime!)}",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A52BE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // Validasi input
                    if (_nameController.text.isEmpty ||
                        selectedCourt == null ||
                        selectedStartTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Lengkapi nama game, lapangan, dan waktu mulai.',
                          ),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    myGames.add(
                      Game(
                        id: DateTime.now().toString(),
                        name: _nameController.text,
                        hostId: "u1",
                        courtId: selectedCourt!.id,
                        startTime: selectedStartTime!,
                        endTime: selectedEndTime!,
                        type: selectedType,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Publish Game',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
