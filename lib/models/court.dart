import 'package:flutter/material.dart';

class Court {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String? photoPath;
  final String openingTime; // Format: "08:00"
  final String closingTime; // Format: "22:00"
  final String type; // Indoor/Outdoor
  final String size; // Full/Half
  final int courtCount; // Number of courts
  final String surface; // Wood, Concrete, Rubber

  Court({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.photoPath,
    this.openingTime = "00:00",
    this.closingTime = "23:59",
    this.type = "Outdoor",
    this.size = "Full",
    this.courtCount = 1,
    this.surface = "Concrete",
  });

  bool get isOpenNow {
    final now = DateTime.now();
    final startTime = TimeOfDay(
      hour: int.parse(openingTime.split(":")[0]),
      minute: int.parse(openingTime.split(":")[1]),
    );
    final endTime = TimeOfDay(
      hour: int.parse(closingTime.split(":")[0]),
      minute: int.parse(closingTime.split(":")[1]),
    );

    double nowDouble = now.hour + now.minute / 60.0;
    double startDouble = startTime.hour + startTime.minute / 60.0;
    double endDouble = endTime.hour + endTime.minute / 60.0;

    return nowDouble >= startDouble && nowDouble <= endDouble;
  }

  factory Court.fromMap(Map<String, dynamic> map) {
    return Court(
      id: map['id'].toString(),
      name: map['name'],
      lat: map['lat'],
      lng: map['lng'],
      photoPath: map['photo_path'],
      openingTime: map['opening_time'] ?? "08:00",
      closingTime: map['closing_time'] ?? "22:00",
      type: map['type'] ?? "Outdoor",
      size: map['size'] ?? "Full",
      courtCount: map['court_count'] ?? 1,
      surface: map['surface'] ?? "Concrete",
    );
  }
}
