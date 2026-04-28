class Court {
  final String id;
  final String name;
  final double lat;
  final double lng;

  Court({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'lat': lat, 'lng': lng};
  }
}
