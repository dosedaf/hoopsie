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

  String get currentUserId => "u1";

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
          username TEXT NOT NULL,
          password TEXT NOT NULL,
          position TEXT NOT NULL,
          skill_level INTEGER DEFAULT 1
        )''');
        await db.execute('''CREATE TABLE courts (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          lat REAL NOT NULL,
          lng REAL NOT NULL
        )''');
        await db.execute('''CREATE TABLE games (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          host_id TEXT NOT NULL,
          court_id TEXT NOT NULL,
          start_time TEXT NOT NULL,
          end_time TEXT NOT NULL,
          type TEXT NOT NULL,
          status TEXT NOT NULL
        )''');
        await db.insert('courts', {
          'id': 'c1',
          'name': 'Sritex Arena, Surakarta',
          'lat': -7.5755,
          'lng': 110.8243,
        });
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

  Future<List<Game>> getAvailableGames() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('games');
    return List.generate(maps.length, (i) => Game.fromMap(maps[i]));
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
    await db.insert('games', {
      'id': game.id,
      'name': game.name,
      'host_id': game.hostId,
      'court_id': game.courtId,
      'start_time': game.startTime.toIso8601String(),
      'end_time': game.endTime.toIso8601String(),
      'type': game.type.name,
      'status': 'open',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteGame(String id) async {
    final db = await database;
    await db.delete('games', where: 'id = ?', whereArgs: [id]);
  }
}
