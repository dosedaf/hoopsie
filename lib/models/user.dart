enum Position {
  pg("Point Guard"),
  sg("Shooting Guard"),
  sf("Small Forward"),
  pf("Power Forward"),
  c("Center");

  final String displayName;

  const Position(this.displayName);
}

class User {
  final String id;
  final String name;
  final String username;
  final String password;
  final Position position;
  final int skillLevel;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.position,
    required this.skillLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'position': position,
      'skill_level': skillLevel,
    };
  }
}
