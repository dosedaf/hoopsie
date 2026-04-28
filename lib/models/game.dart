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
  final String courtId;
  final DateTime startTime;
  final DateTime endTime;
  final GameType type;

  Game({
    required this.id,
    required this.name,
    required this.hostId,
    required this.courtId,
    required this.startTime,
    required this.endTime,
    required this.type,
  });

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'].toString(),
      name: map['name'],
      hostId: map['host_id'],
      courtId: map['court_id'],
      startTime: DateTime.parse(map['start_time']),
      endTime: DateTime.parse(map['end_time']),
      type: GameType.values.firstWhere((e) => e.name == map['type']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'hostId': hostId,
      'courtId': courtId,
      'startTime': startTime,
      'endTime': endTime,
      'type': type,
    };
  }
}
