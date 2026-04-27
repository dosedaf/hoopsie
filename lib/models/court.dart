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
}

List<Court> mockCourts = [
  Court(
    id: "c1",
    name: "Senayan Basketball Court",
    lat: -6.2185,
    lng: 106.8026,
  ),
  Court(id: "c2", name: "Bandung City Court", lat: -6.9175, lng: 107.6191),
  Court(id: "c3", name: "Gor Pajajaran Court", lat: -6.9034, lng: 107.6186),
];
