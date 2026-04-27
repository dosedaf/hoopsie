enum Position { PG, SG, SF, PF, C }

class User {
  final String id;
  final String username;
  final String password; // hash later
  final Position position;
  final int skillLevel;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.position,
    required this.skillLevel,
  });
}
