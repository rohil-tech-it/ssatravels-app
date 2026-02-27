class TollPlazaModel {
  final String id;
  final String name;
  final String location;
  final String district;
  final String highway;
  final double latitude;
  final double longitude;
  final double? amount; // Nullable for safety

  TollPlazaModel({
    required this.id,
    required this.name,
    required this.location,
    required this.district,
    required this.highway,
    required this.latitude,
    required this.longitude,
    this.amount, // Optional
  });

  factory TollPlazaModel.fromFirestore(Map<String, dynamic> data, String id) {
    return TollPlazaModel(
      id: id,
      name: data['name'] ?? '',
      location: data['location'] ?? '',
      district: data['district'] ?? '',
      highway: data['highway'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      amount: data['amount']?.toDouble(), // Null if not present
    );
  }
}