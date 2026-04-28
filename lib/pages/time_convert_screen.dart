import 'dart:async';
import 'package:flutter/material.dart';

class TimeConvertScreen extends StatefulWidget {
  const TimeConvertScreen({super.key});

  @override
  State<TimeConvertScreen> createState() => _TimeConvertScreenState();
}

class _TimeConvertScreenState extends State<TimeConvertScreen> {
  static const _primary = Color(0xFF2A52BE);
  static const _bg = Color(0xFFF8F9FA);

  late Timer _ticker;
  DateTime _now = DateTime.now().toUtc();

  // Zona waktu yang relevan (offset UTC dalam jam)
  static const List<_TimeZone> _zones = [
    _TimeZone('WIB',       'Waktu Indonesia Barat',  'Jakarta · Surabaya',      7),
    _TimeZone('WITA',      'Waktu Indonesia Tengah', 'Makassar · Bali',         8),
    _TimeZone('WIT',       'Waktu Indonesia Timur',  'Jayapura · Ambon',        9),
    _TimeZone('London',    'Greenwich Mean Time',    'London · Manchester',     0),
    _TimeZone('New York',  'Eastern Time',           'NBA HQ · Madison Sq.',   -5),
    _TimeZone('Los Angeles','Pacific Time',          'LA Lakers · LA Clippers',-8),
    _TimeZone('Tokyo',     'Japan Standard Time',    'Tokyo · Osaka',           9),
    _TimeZone('Singapore', 'Singapore Standard Time','Singapura',               8),
  ];

  // Manual converter state
  String _sourceZone = 'WIB';
  final _hourController   = TextEditingController();
  final _minuteController = TextEditingController();
  List<_ConvertedTime> _converted = [];
  String _convertError = '';

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now().toUtc());
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  DateTime _inZone(_TimeZone zone) =>
      _now.add(Duration(hours: zone.utcOffset));

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDate(DateTime dt) {
    const days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    const months = [
      'Jan','Feb','Mar','Apr','Mei','Jun',
      'Jul','Ags','Sep','Okt','Nov','Des'
    ];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}';
  }

  void _doConvert() {
    final h = int.tryParse(_hourController.text);
    final m = int.tryParse(_minuteController.text);

    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      setState(() {
        _convertError = 'Masukkan jam (0–23) dan menit (0–59) yang valid.';
        _converted = [];
      });
      return;
    }

    final srcOffset = _zones.firstWhere((z) => z.code == _sourceZone).utcOffset;
    // Konversi ke UTC dulu
    final utcMinutes = h * 60 + m - srcOffset * 60;

    setState(() {
      _convertError = '';
      _converted = _zones
          .where((z) => z.code != _sourceZone)
          .map((z) {
            final totalMin = (utcMinutes + z.utcOffset * 60) % (24 * 60);
            final adjusted = totalMin < 0 ? totalMin + 24 * 60 : totalMin;
            final rh = (adjusted ~/ 60).toString().padLeft(2, '0');
            final rm = (adjusted % 60).toString().padLeft(2, '0');
            return _ConvertedTime(z, '$rh:$rm');
          })
          .toList();
    });
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ───────────────────────────────────────────────
              const Text(
                'Konversi Waktu',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Waktu saat ini di berbagai zona',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // ── Live Clock Cards ──────────────────────────────────────
              const Text(
                'WAKTU SEKARANG',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // WIB · WITA · WIT — row of 3
              Row(
                children: _zones.take(3).map((zone) {
                  final dt = _inZone(zone);
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                          right: zone == _zones[2] ? 0 : 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              zone.code,
                              style: const TextStyle(
                                color: _primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            dt.second.toString().padLeft(2, '0'),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // International zones
              ..._zones.skip(3).map((zone) {
                final dt = _inZone(zone);
                final offsetLabel = zone.utcOffset >= 0
                    ? 'UTC+${zone.utcOffset}'
                    : 'UTC${zone.utcOffset}';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _card(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.language,
                              color: _primary, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                zone.code,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                zone.subtitle,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(dt),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _primary,
                                fontFeatures: [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            Text(
                              '${_formatDate(dt)}  ·  $offsetLabel',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 8),
              const Divider(height: 32),

              // ── Manual Converter ──────────────────────────────────────
              const Text(
                'KONVERSI MANUAL',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source zone selector
                    const Text(
                      'Dari zona waktu',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _zones.map((z) {
                        final isSel = _sourceZone == z.code;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _sourceZone = z.code),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? _primary
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              z.code,
                              style: TextStyle(
                                color: isSel
                                    ? Colors.white
                                    : const Color(0xFF475569),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Time input
                    const Text(
                      'Masukkan waktu',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _timeInput(
                            controller: _hourController,
                            hint: 'Jam',
                            label: 'HH',
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            ':',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _timeInput(
                            controller: _minuteController,
                            hint: 'Menit',
                            label: 'MM',
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _doConvert,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                            ),
                            child: const Text(
                              'Konversi',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_convertError.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 15),
                          const SizedBox(width: 6),
                          Text(
                            _convertError,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ),
                    ],

                    if (_converted.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 14),
                      ..._converted.map((c) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    c.zone.code,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    c.zone.name,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                                Text(
                                  c.time,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _primary,
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeInput({
    required TextEditingController controller,
    required String hint,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 2,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: label,
        hintStyle: const TextStyle(
            color: Color(0xFFCBD5E1), fontSize: 22),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _TimeZone {
  final String code;
  final String name;
  final String subtitle;
  final int utcOffset;
  const _TimeZone(this.code, this.name, this.subtitle, this.utcOffset);
}

class _ConvertedTime {
  final _TimeZone zone;
  final String time;
  const _ConvertedTime(this.zone, this.time);
}