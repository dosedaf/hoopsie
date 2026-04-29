// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/game.dart';
import '../models/court.dart';
import 'dart:developer';
import 'dart:io';

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
        await db.execute('''CREATE TABLE courts (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          lat REAL NOT NULL,
          lng REAL NOT NULL
        )''');
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
      -- This checks if "u2" (you) has a record in game_members for this game
      (SELECT status FROM game_members 
       WHERE game_id = games.id AND user_id = ?) AS current_user_status
    FROM games 
    LEFT JOIN users ON games.host_id = users.id
    LEFT JOIN courts ON games.court_id = courts.id
    WHERE games.host_id != ? AND games.status = 'open'
    ORDER BY games.start_time ASC
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
}
