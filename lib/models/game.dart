enum GameStatus { open, full, ongoing, finished, cancelled }

enum GameType { oneOnOne, threeOnThree, fiveOnFive }

class Game {
  final String id;
  final String name;
  final String hostId;
  final String courtId;
  final DateTime startTime;
  final DateTime endTime;
  final GameType type;
  GameStatus status;

  Game({
    required this.id,
    required this.name,
    required this.hostId,
    required this.courtId,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.status = GameStatus.open,
  });
}

List<Game> myGames = [];

List<Game> mockGames = [
  Game(
    id: "g1",
    name: "bantai2",
    hostId: "u1",
    courtId: "c1",
    startTime: DateTime.now().add(Duration(hours: 2)),
    endTime: DateTime.now().add(Duration(hours: 3)),
    type: GameType.fiveOnFive,
  ),
  Game(
    id: "g2",
    name: "kyrie camp",
    hostId: "u2",
    courtId: "c2",
    startTime: DateTime.now().add(Duration(days: 1)),
    endTime: DateTime.now().add(Duration(days: 1, hours: 1)),
    type: GameType.threeOnThree,
    status: GameStatus.full,
  ),
  Game(
    id: "g3",
    name: "lawan bigmo menang dpt 50k",
    hostId: "u3",
    courtId: "c1",
    startTime: DateTime.now().subtract(Duration(hours: 1)),
    endTime: DateTime.now().add(Duration(hours: 1)),
    type: GameType.oneOnOne,
    status: GameStatus.ongoing,
  ),
];
