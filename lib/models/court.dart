class Court {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String? photoPath;

  Court({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'lat': lat, 'lng': lng};
  }
}
