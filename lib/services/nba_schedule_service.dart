import 'dart:convert';
import 'package:http/http.dart' as http;

class NbaTeamInfo {
  final String name;
  final String abbreviation;
  final String logoUrl;
  final int? score;

  const NbaTeamInfo({
    required this.name,
    required this.abbreviation,
    required this.logoUrl,
    this.score,
  });
}

class NbaGame {
  final NbaTeamInfo away;
  final NbaTeamInfo home;
  final DateTime gameTimeUtc;
  final String status;
  final bool isPast;

  const NbaGame({
    required this.away,
    required this.home,
    required this.gameTimeUtc,
    required this.status,
    this.isPast = false,
  });
}

class NbaSchedule {
  final List<NbaGame> recentGames;
  final List<NbaGame> upcomingGames;

  const NbaSchedule({
    required this.recentGames,
    required this.upcomingGames,
  });

  bool get isEmpty => recentGames.isEmpty && upcomingGames.isEmpty;
}

class NbaScheduleService {
  static const _baseUrl =
      'https://site.api.espn.com/apis/site/v2/sports/basketball/nba/scoreboard';

  Future<NbaSchedule> fetchSchedule({
    int recentLimit = 5,
    int upcomingLimit = 5,
  }) async {
    final now = DateTime.now().toUtc();
    final seen = <String>{};
    final recent = <NbaGame>[];
    final upcoming = <NbaGame>[];

    for (var offset = -14; offset <= 14; offset++) {
      final date = now.add(Duration(days: offset));
      final games = await _fetchGamesForDate(date, seen: seen);

      for (final game in games) {
        if (_isUpcomingGame(game, now)) {
          upcoming.add(game);
        } else if (_isPastGame(game, now)) {
          recent.add(game.copyWith(isPast: true));
        }
      }
    }

    recent.sort((a, b) => b.gameTimeUtc.compareTo(a.gameTimeUtc));
    upcoming.sort((a, b) => a.gameTimeUtc.compareTo(b.gameTimeUtc));

    return NbaSchedule(
      recentGames: recent.take(recentLimit).toList(),
      upcomingGames: upcoming.take(upcomingLimit).toList(),
    );
  }

  bool _isPastGame(NbaGame game, DateTime now) {
    final status = game.status.toLowerCase();
    if (status == 'final') return true;
    return game.gameTimeUtc.isBefore(now) && status != 'scheduled';
  }

  bool _isUpcomingGame(NbaGame game, DateTime now) {
    final status = game.status.toLowerCase();
    if (status == 'final') return false;
    if (status.contains('progress') || status.contains('halftime')) {
      return true;
    }
    return game.gameTimeUtc.isAfter(now);
  }

  Future<List<NbaGame>> _fetchGamesForDate(
    DateTime date, {
    required Set<String> seen,
  }) async {
    final dateParam =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

    final response = await http.get(
      Uri.parse('$_baseUrl?dates=$dateParam'),
    );

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final events = data['events'] as List<dynamic>? ?? [];
    final games = <NbaGame>[];

    for (final event in events) {
      final game = _parseEvent(event as Map<String, dynamic>, seen);
      if (game != null) games.add(game);
    }

    return games;
  }

  NbaGame? _parseEvent(Map<String, dynamic> eventMap, Set<String> seen) {
    final id = eventMap['id']?.toString() ?? '';
    if (id.isNotEmpty) {
      if (seen.contains(id)) return null;
      seen.add(id);
    }

    final dateStr = eventMap['date'] as String?;
    if (dateStr == null) return null;

    final gameTime = DateTime.parse(dateStr).toUtc();

    final competitions = eventMap['competitions'] as List<dynamic>?;
    if (competitions == null || competitions.isEmpty) return null;

    final comp = competitions.first as Map<String, dynamic>;
    final statusDesc = (comp['status'] as Map<String, dynamic>?)?['type']
            ?['description'] as String? ??
        'Scheduled';

    final competitors = comp['competitors'] as List<dynamic>? ?? [];
    NbaTeamInfo? away;
    NbaTeamInfo? home;

    for (final c in competitors) {
      final cm = c as Map<String, dynamic>;
      final side = cm['homeAway'] as String?;
      final team = _parseTeam(cm);
      if (team == null) continue;
      if (side == 'away') away = team;
      if (side == 'home') home = team;
    }

    if (away == null || home == null) return null;

    return NbaGame(
      away: away,
      home: home,
      gameTimeUtc: gameTime,
      status: statusDesc,
    );
  }

  NbaTeamInfo? _parseTeam(Map<String, dynamic> competitor) {
    final team = competitor['team'] as Map<String, dynamic>?;
    if (team == null) return null;

    final name = team['displayName'] as String? ??
        team['shortDisplayName'] as String? ??
        team['name'] as String?;
    final abbr = team['abbreviation'] as String? ?? '';
    final logo = team['logo'] as String? ??
        ((team['logos'] as List<dynamic>?)?.isNotEmpty == true
            ? (team['logos'] as List).first['href'] as String?
            : null);

    if (name == null || logo == null) return null;

    final scoreStr = competitor['score'] as String?;
    final score = scoreStr != null ? int.tryParse(scoreStr) : null;

    return NbaTeamInfo(
      name: name,
      abbreviation: abbr,
      logoUrl: logo,
      score: score,
    );
  }
}

extension _NbaGameCopy on NbaGame {
  NbaGame copyWith({bool? isPast}) {
    return NbaGame(
      away: away,
      home: home,
      gameTimeUtc: gameTimeUtc,
      status: status,
      isPast: isPast ?? this.isPast,
    );
  }
}
