// lib/models/toll_route_model.dart
class TollRouteModel {
  final String id;
  final String source;
  final String destination;
  final double distance;
  final double baseToll; // This field is required
  final List<String> tollPlazaIds;
  final Map<String, double> vehicleRates;
  final bool isActive;

  TollRouteModel({
    required this.id,
    required this.source,
    required this.destination,
    required this.distance,
    required this.baseToll, // Make sure this is included
    required this.tollPlazaIds,
    required this.vehicleRates,
    required this.isActive,
  });

  factory TollRouteModel.fromFirestore(Map<String, dynamic> data, String id) {
    return TollRouteModel(
      id: id,
      source: data['source'] ?? '',
      destination: data['destination'] ?? '',
      distance: (data['distance'] ?? 0).toDouble(),
      baseToll: (data['baseToll'] ?? 0).toDouble(), // This must exist
      tollPlazaIds: List<String>.from(data['tollPlazaIds'] ?? []),
      vehicleRates: Map<String, double>.from(data['vehicleRates'] ?? {}),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'destination': destination,
      'distance': distance,
      'baseToll': baseToll, // This must exist
      'tollPlazaIds': tollPlazaIds,
      'vehicleRates': vehicleRates,
      'isActive': isActive,
    };
  }
}