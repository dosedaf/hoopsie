import 'package:geodesy/geodesy.dart';

enum GameStatus { open, full, ongoing, finished, cancelled }

enum GameType {
  oneOnOne("1v1"),
  threeOnThree("3v3"),
  fiveOnFive("5v5");

  final String displayName;

  const GameType(this.displayName);
}

class Game {
  final String id;
  final String name;
  final String hostId;
  final String? hostName;
  final String courtId;
  final String courtName;
  final double courtLat;
  final double courtLng;
  final String? photoPath; // <--- ADD THIS
  final DateTime startTime;
  final DateTime endTime;
  final GameType type;
  GameStatus status;
  final String? currentUserStatus;

  LatLng get location => LatLng(courtLat, courtLng);

  Game({
    required this.id,
    required this.name,
    required this.hostId,
    this.hostName,
    required this.courtId,
    required this.courtName,
    required this.courtLat,
    required this.courtLng,
    this.photoPath,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.status = GameStatus.open,
    this.currentUserStatus,
  });

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      hostId: map['host_id'] ?? '',
      hostName: map['host_name'],
      courtId: map['court_id'] ?? '',
      courtName: map['court_name'] ?? '',
      courtLat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      courtLng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      photoPath: map['photo_path'],
      startTime: DateTime.parse(map['start_time']),
      endTime: DateTime.parse(map['end_time']),
      type: GameType.values.firstWhere((e) => e.name == map['type']),
      status: GameStatus.values.firstWhere((e) => e.name == map['status']),
      currentUserStatus: map['current_user_status'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'hostId': hostId,
      'courtId': courtId,
      'courtLat': courtLat,
      'courtLng': courtLng,
      'courtName': courtName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type.name,
      'status': status.name,
    };
  }
}
