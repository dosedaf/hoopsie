import 'package:flutter/material.dart';
import 'package:crypt/crypt.dart';

enum Position {
  pg("Point Guard", "G"),
  sg("Shooting Guard", "G"),
  sf("Small Forward", "F"),
  pf("Power Forward", "F"),
  c("Center", "C");

  final String fullName;
  final String abbreviation;
  const Position(this.fullName, this.abbreviation);
}

class User {
  final String id;
  final String name;
  final String username;
  final String password;
  final Position position;
  final int skillLevel;
  final String? photoPath;

  User({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.position,
    required this.skillLevel,
    this.photoPath,
  });

  String get positionIndonesian {
    switch (position) {
      case Position.pg:
        return "Pengatur Serangan";
      case Position.sg:
        return "Penembak Utama";
      case Position.sf:
        return "Penyerang Serbaguna";
      case Position.pf:
        return "Penyerang Kuat";
      case Position.c:
        return "Pemain Tengah";
    }
  }

  double get visualRating => skillLevel / 10.0;

  String get skillTier {
    if (skillLevel >= 90) return "Hall of Fame";
    if (skillLevel >= 80) return "All-Star";
    if (skillLevel >= 70) return "Starter";
    if (skillLevel >= 60) return "Rotation";
    return "Rookie";
  }

  Color get tierColor {
    if (skillLevel >= 80) return Colors.orangeAccent;
    if (skillLevel >= 70) return Colors.blueAccent;
    return Colors.grey;
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      username: map['username'],
      password: map['password'],
      position: Position.values.firstWhere(
        (e) => e.name == map['position'].toString().toLowerCase(),
        orElse: () => Position.c,
      ),
      skillLevel: map['skill_level'] ?? 50,
      photoPath: map['photo_path'],
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'position': position.name,
      'skill_level': skillLevel,
      'photo_path': photoPath,
    };
  }

  bool verifyPassword(String plainPassword) {
    return Crypt(password).match(plainPassword);
  }

  static String hashPassword(String plainPassword) {
    return Crypt.sha256(plainPassword).toString();
  }
}
