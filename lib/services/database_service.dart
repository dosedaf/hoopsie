import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/game.dart';
import '../models/court.dart';
import 'dart:developer';
import 'dart:io';
import 'dart:math' show asin, cos, sqrt;
import 'package:geolocator/geolocator.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  String get currentUserId => "u2";

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // final String dbDirectory = await getDatabasesPath();
    final String dbDirectory = join(Directory.current.path, 'database');
    final String path = join(dbDirectory, 'hoopsie.db');

    final directory = Directory(dbDirectory);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    log("DEBUG: Database is located at: $path");
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE users (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    username TEXT NOT NULL,
    password TEXT NOT NULL,
    position TEXT NOT NULL, -- e.g., 'pg', 'sg'
    skill_level INTEGER DEFAULT 1
);
        ''');
        await db.execute('''
        CREATE TABLE courts (
  id TEXT PRIMARY KEY,
  name TEXT,
  lat REAL,
  lng REAL,
  photo_path TEXT 
)
        ''');
        await db.execute('''
        CREATE TABLE games (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    host_id TEXT NOT NULL,
    court_id TEXT NOT NULL,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    type TEXT NOT NULL,
    status TEXT NOT NULL,
    FOREIGN KEY (host_id) REFERENCES users (id),
    FOREIGN KEY (court_id) REFERENCES courts (id)
);
''');
        await db.insert('courts', {
          'id': 'c1',
          'name': 'Sritex Arena, Surakarta',
          'lat': -7.5755,
          'lng': 110.8243,
        });
        await db.execute('''
  CREATE TABLE game_members (
    id TEXT PRIMARY KEY,
    game_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    status TEXT NOT NULL, -- pending, approved, rejected, checkedIn
    FOREIGN KEY (game_id) REFERENCES games (id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
  )
''');
        await db.execute('''CREATE TABLE quiz_questions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          question TEXT NOT NULL,
          options TEXT NOT NULL,
          correct_index INTEGER NOT NULL,
          image_url TEXT,
          created_at TEXT NOT NULL
        )''');

        await db.execute('''CREATE TABLE quiz_answers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          question_id INTEGER NOT NULL,
          answered_at TEXT NOT NULL,
          FOREIGN KEY (user_id) REFERENCES users(id),
          FOREIGN KEY (question_id) REFERENCES quiz_questions(id),
          UNIQUE(user_id, question_id)
        )''');

        await db.execute('''
INSERT INTO users (id, name, username, password, position, skill_level)
VALUES ('u1', 'Ayodya Enhanayoan', 'ayodya', 'password123', 'pg', 85);

INSERT INTO users (id, name, username, password, position, skill_level)
VALUES ('u2', 'Budi Santoso', 'budisan', 'password456', 'c', 70);
        ''');

        final now = DateTime.now().toIso8601String();
        final quizData = [
          [
            'Berapa poin nilai tembakan three-point?',
            '["1 poin","2 poin","3 poin","4 poin"]',
            2,
            null,
          ],
          [
            'Berapa durasi satu quarter di NBA?',
            '["10 menit","12 menit","15 menit","20 menit"]',
            1,
            null,
          ],
          [
            'Apa nama pelanggaran berjalan tanpa dribble?',
            '["Foul","Traveling","Double Dribble","Goaltending"]',
            1,
            null,
          ],
          [
            'Berapa tinggi standar ring basket dari lantai?',
            '["2,85 m","3,05 m","3,25 m","3,50 m"]',
            1,
            null,
          ],
          [
            'Siapa yang mencetak 100 poin dalam satu game NBA?',
            '["Michael Jordan","Kobe Bryant","Wilt Chamberlain","LeBron James"]',
            2,
            null,
          ],
          [
            'Berapa shot clock di NBA (detik)?',
            '["14","18","24","30"]',
            2,
            null,
          ],
          [
            'Posisi yang bertugas mengatur serangan disebut?',
            '["Small Forward","Power Forward","Point Guard","Center"]',
            2,
            null,
          ],
          [
            'Tim mana yang paling banyak juara NBA sepanjang sejarah?',
            '["LA Lakers","Boston Celtics","Chicago Bulls","Golden State Warriors"]',
            1,
            null,
          ],
          [
            '"Triple-double" berarti dua digit di tiga statistik apa?',
            '["Poin, rebound, assist","Poin, steal, block","Rebound, assist, foul","Poin, foul, turnover"]',
            0,
            null,
          ],
          [
            'Berapa pemain satu tim yang boleh di lapangan sekaligus?',
            '["4","5","6","7"]',
            1,
            null,
          ],
          [
            'Siapa pemain ini?',
            '["Kevin Durant","LeBron James","Stephen Curry","Giannis"]',
            1,
            'assets/images/quiz/lebron.jpg',
          ],
          [
            'Siapa pemain ini?',
            '["Klay Thompson","Chris Paul","Stephen Curry","Damian Lillard"]',
            2,
            'assets/images/quiz/curry.webp',
          ],
          [
            'Siapa pemain ini?',
            '["Kevin Durant","Kawhi Leonard","Paul George","Jimmy Butler"]',
            0,
            'assets/images/quiz/kd.avif',
          ],
        ];

        for (final q in quizData) {
          await db.insert('quiz_questions', {
            'question': q[0],
            'options': q[1],
            'correct_index': q[2],
            'image_url': q[3],
            'created_at': now,
          });
        }
      },
    );
  }

  Future<List<Court>> getAllCourts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('courts');
    return List.generate(maps.length, (i) {
      return Court(
        id: maps[i]['id'],
        name: maps[i]['name'],
        lat: maps[i]['lat'],
        lng: maps[i]['lng'],
      );
    });
  }

  Future<List<Game>> getMyGames() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'games',
      where: 'host_id = ?',
      whereArgs: [currentUserId],
    );
    return List.generate(maps.length, (i) => Game.fromMap(maps[i]));
  }

  Future<void> insertGame(Game game) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.insert('games', {
        'id': game.id,
        'name': game.name,
        'host_id': game.hostId,
        'court_id': game.courtId,
        'start_time': game.startTime.toIso8601String(),
        'end_time': game.endTime.toIso8601String(),
        'type': game.type.name,
        'status': 'open',
      });

      await txn.insert('game_members', {
        'id': 'mem_${game.id}_${game.hostId}',
        'game_id': game.id,
        'user_id': game.hostId,
        'status': 'approved',
      });
    });
  }

  Future<void> joinGame(String gameId) async {
    final db = await database;

    final List<Map<String, dynamic>> existing = await db.query(
      'game_members',
      where: 'game_id = ? AND user_id = ?',
      whereArgs: [gameId, currentUserId],
    );

    if (existing.isEmpty) {
      await db.insert('game_members', {
        'id': 'mem_${gameId}_$currentUserId',
        'game_id': gameId,
        'user_id': currentUserId,
        'status': 'pending',
      });
    }
  }

  Future<void> deleteGame(String id) async {
    final db = await database;
    await db.delete('games', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateGame(Game game) async {
    final db = await database;
    await db.update(
      'games',
      game.toMap(),
      where: 'id = ?',
      whereArgs: [game.id],
    );
  }

  Future<List<Game>> getMyHostedGames() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
    SELECT 
      games.*, 
      users.name AS host_name, 
      courts.name AS court_name
    FROM games 
    LEFT JOIN users ON games.host_id = users.id
    LEFT JOIN courts ON games.court_id = courts.id
    WHERE games.host_id = ?
  ''',
      [currentUserId],
    );

    return List.generate(maps.length, (i) => Game.fromMap(maps[i]));
  }

  Future<List<Game>> getDiscoverableGames() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
    SELECT 
      games.*, 
      users.name AS host_name, 
      courts.name AS court_name,
      courts.lat, 
      courts.lng, 
      courts.photo_path, -- <--- ADD THIS LINE HERE
      (SELECT status FROM game_members 
       WHERE game_id = games.id AND user_id = ?) AS current_user_status
    FROM games 
    LEFT JOIN users ON games.host_id = users.id
    LEFT JOIN courts ON games.court_id = courts.id
    WHERE games.host_id != ? AND games.status = 'open'
  ''',
      [currentUserId, currentUserId],
    );

    return List.generate(maps.length, (i) => Game.fromMap(maps[i]));
  }

  Future<List<Game>> getAvailableGames() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT 
      games.*, 
      users.name as host_name 
    FROM games 
    JOIN users ON games.host_id = users.id
    WHERE games.status = 'open'
  ''');

    return List.generate(maps.length, (i) => Game.fromMap(maps[i]));
  }

  Future<String?> getMemberStatus(String gameId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'game_members',
      columns: ['status'],
      where: 'game_id = ? AND user_id = ?',
      whereArgs: [gameId, currentUserId],
    );

    if (maps.isEmpty) return null;
    return maps.first['status'] as String;
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT 
      game_members.id AS member_record_id,
      game_members.status,
      users.name AS requester_name,
      games.name AS game_name
    FROM game_members
    JOIN users ON game_members.user_id = users.id
    JOIN games ON game_members.game_id = games.id
    WHERE games.host_id = ? AND game_members.status = 'pending'
  ''',
      [currentUserId],
    );
  }

  Future<void> acceptMember(String memberRecordId) async {
    final db = await database;
    await db.update(
      'game_members',
      {'status': 'approved'},
      where: 'id = ?',
      whereArgs: [memberRecordId],
    );
  }

  Future<List<Map<String, dynamic>>> getGameParticipants(String gameId) async {
    final db = await database;
    return await db.rawQuery(
      '''
    SELECT 
      game_members.id AS member_record_id,
      game_members.status,
      users.id AS user_id,
      users.name,
      users.position
    FROM game_members
    JOIN users ON game_members.user_id = users.id
    WHERE game_members.game_id = ?
  ''',
      [gameId],
    );
  }

  Future<void> updateMemberStatus(String recordId, String status) async {
    final db = await database;
    await db.update(
      'game_members',
      {'status': status},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  Future<List<Map<String, dynamic>>> getUnansweredQuestions(
    String userId,
  ) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT * FROM quiz_questions
      WHERE id NOT IN (
        SELECT question_id FROM quiz_answers WHERE user_id = ?
      )
      ORDER BY RANDOM()
    ''',
      [userId],
    );
  }

  Future<void> markQuizAnswered({
    required String userId,
    required int questionId,
  }) async {
    final db = await database;
    await db.insert('quiz_answers', {
      'user_id': userId,
      'question_id': questionId,
      'answered_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Game>> getMyGamesAndJoined() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
    SELECT DISTINCT
      games.*, 
      users.name AS host_name, 
      courts.name AS court_name,
      courts.lat,        -- Added for consistency
      courts.lng,        -- Added for consistency
      courts.photo_path, -- <--- ADD THIS LINE HERE
      m.status AS current_user_status
    FROM games 
    LEFT JOIN users ON games.host_id = users.id
    LEFT JOIN courts ON games.court_id = courts.id
    LEFT JOIN game_members m ON m.game_id = games.id AND m.user_id = ?
    WHERE games.host_id = ? OR m.user_id = ?
    ORDER BY games.start_time ASC
  ''',
      [currentUserId, currentUserId, currentUserId],
    );

    return List.generate(maps.length, (i) => Game.fromMap(maps[i]));
  }

  Future<void> leaveGame(String gameId) async {
    final db = await database;
    await db.delete(
      'game_members',
      where: 'game_id = ? AND user_id = ?',
      whereArgs: [gameId, currentUserId],
    );
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    var p = 0.017453292519943295;
    var c = cos;
    var a =
        0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // returns distance in km
  }

  Future<List<Game>> getNearbyGames(double radiusKm) async {
    Position position = await Geolocator.getCurrentPosition();

    List<Game> allGames = await getDiscoverableGames();

    return allGames.where((game) {
      double dist = _calculateDistance(
        position.latitude,
        position.longitude,
        game.courtLat,
        game.courtLng,
      );
      return dist <= radiusKm;
    }).toList();
  }

  Future<void> saveCourt(
    String name,
    double lat,
    double lng,
    String? photoPath,
  ) async {
    final db = await database;
    await db.insert('courts', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'lat': lat,
      'lng': lng,
      'photo_path': photoPath,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
