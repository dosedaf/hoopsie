import 'package:flutter/material.dart';
import '../services/nba_schedule_service.dart';

class TimeConvertScreen extends StatefulWidget {
  const TimeConvertScreen({super.key});

  @override
  State<TimeConvertScreen> createState() => _TimeConvertScreenState();
}

class _TimeConvertScreenState extends State<TimeConvertScreen> {
  static const _primary = Color(0xFF2563EB);
  static const _bg = Color(0xFFF8F9FA);

  final _nbaService = NbaScheduleService();

  NbaSchedule _nbaSchedule =
      const NbaSchedule(recentGames: [], upcomingGames: []);
  bool _nbaLoading = true;
  String? _nbaError;

  static const List<_TimeZone> _matchZones = [
    _TimeZone('WIB', 7),
    _TimeZone('WITA', 8),
    _TimeZone('WIT', 9),
    _TimeZone('London', 0),
  ];

  @override
  void initState() {
    super.initState();
    _loadNbaSchedule();
  }

  Future<void> _loadNbaSchedule() async {
    setState(() {
      _nbaLoading = true;
      _nbaError = null;
    });
    try {
      final schedule = await _nbaService.fetchSchedule(
        recentLimit: 5,
        upcomingLimit: 5,
      );
      if (!mounted) return;
      setState(() {
        _nbaSchedule = schedule;
        _nbaLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nbaError = 'Gagal memuat jadwal NBA. Periksa koneksi internet.';
        _nbaLoading = false;
      });
    }
  }

  DateTime _inZoneFromUtc(DateTime utc, _TimeZone zone) =>
      utc.add(Duration(hours: zone.utcOffset));

  String _formatClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatGameDate(DateTime utc) {
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
    ];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    final local = utc.toLocal();
    return '${days[local.weekday - 1]}, ${local.day} ${months[local.month - 1]} ${local.year}';
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
            color: Colors.grey.withValues(alpha: 0.08),
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
      appBar: AppBar(
        title: const Text('Jadwal & Konversi Waktu'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 22, color: _primary),
            onPressed: _loadNbaSchedule,
            tooltip: 'Refresh jadwal',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jadwal pertandingan NBA dengan konversi zona waktu',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              _buildNbaScheduleSection(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNbaScheduleSection() {
    if (_nbaLoading) {
      return _card(
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_nbaError != null) {
      return _card(
        child: Column(
          children: [
            const Icon(Icons.wifi_off, color: Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(
              _nbaError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadNbaSchedule,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }

    if (_nbaSchedule.isEmpty) {
      return _card(
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Tidak ada jadwal NBA tersedia saat ini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_nbaSchedule.recentGames.isNotEmpty) ...[
          _sectionHeader('PERTANDINGAN TERAKHIR'),
          ..._nbaSchedule.recentGames.map(
            (game) => _buildNbaGameCard(game, isPast: true),
          ),
          const SizedBox(height: 16),
        ],
        if (_nbaSchedule.upcomingGames.isNotEmpty) ...[
          _sectionHeader('PERTANDINGAN MENDATANG'),
          ..._nbaSchedule.upcomingGames.map(
            (game) => _buildNbaGameCard(game, isPast: false),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 1,
          color: Colors.grey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNbaGameCard(NbaGame game, {required bool isPast}) {
    final dateLabel = _formatGameDate(game.gameTimeUtc);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _card(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPast
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPast ? 'SELESAI' : 'MENDATANG',
                    style: TextStyle(
                      color: isPast ? const Color(0xFF64748B) : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  game.status,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              dateLabel,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildTeamRow(game.away, isPast: isPast),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isPast
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                ],
              ),
            ),
            _buildTeamRow(game.home, isPast: isPast),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: _matchZones.map((zone) {
                  final local = _inZoneFromUtc(game.gameTimeUtc, zone);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            zone.code,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatClock(local),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isPast ? const Color(0xFF64748B) : _primary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(NbaTeamInfo team, {required bool isPast}) {
    final textColor =
        isPast ? const Color(0xFF64748B) : const Color(0xFF1E293B);

    return Row(
      children: [
        _teamLogo(team.logoUrl),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                team.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: textColor,
                ),
              ),
              if (team.abbreviation.isNotEmpty)
                Text(
                  team.abbreviation,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        if (isPast && team.score != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${team.score}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
      ],
    );
  }

  Widget _teamLogo(String url) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Image.network(
          url,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.sports_basketball,
            color: Color(0xFF94A3B8),
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _TimeZone {
  final String code;
  final int utcOffset;
  const _TimeZone(this.code, this.utcOffset);
}
