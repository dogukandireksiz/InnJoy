class LocationModel {
  final String id;
  final String name;
  final String description;
  final String fireExitNote;
  final String fireExitDistance;
  final String? imageUrl; // Resim opsiyonel olabilir
  final double latitude;
  final double longitude;

  LocationModel({
    required this.id,
    required this.name,
    required this.description,
    required this.fireExitNote,
    required this.fireExitDistance,
    this.imageUrl,
    required this.latitude,
    required this.longitude,
  });

  // Firebase'den gelen veriyi Dart objesine çeviren fonksiyon
  factory LocationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return LocationModel(
      id: id,
      name: data['name'] ?? 'Bilinmeyen Yer',
      description: data['desc'] ?? 'Açıklama yok.',
      fireExitNote: data['fire_note'] ?? 'Bilgi yok.',
      fireExitDistance: data['fire_dist'] ?? '-',
      imageUrl: data['image'],
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}