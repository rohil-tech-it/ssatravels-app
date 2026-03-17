// lib/services/toll_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/toll_plaza_model.dart';
import '../models/toll_route_model.dart';
import '../models/vehicle_model.dart';
import '../data/tamilnadu_toll_plazas.dart';
import '../data/tamilnadu_toll_routes.dart';
import 'toll_calculator.dart'; // Add this import

class TollService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _tollPlazas => _firestore.collection('toll_plazas');
  CollectionReference get _vehicles => _firestore.collection('vehicles');
  CollectionReference get _bookings => _firestore.collection('toll_bookings');
  CollectionReference get _tollRoutes => _firestore.collection('toll_routes');

  // ==================== TOLL PLAZA OPERATIONS ====================

  // Get all toll plazas from Firestore
  Stream<List<TollPlazaModel>> getAllTollPlazas() {
    return _tollPlazas
        .where('isActive', isEqualTo: true)
        .orderBy('district')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TollPlazaModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // Initialize Tamil Nadu toll plazas from local data to Firestore
  Future<void> initializeTollPlazasToFirestore() async {
    try {
      final plazas = TamilNaduTollData.getAllTollPlazas();

      for (var plaza in plazas) {
        try {
          // Check if already exists
          final existingDoc = await _tollPlazas.doc(plaza['id']).get();

          if (!existingDoc.exists) {
            await _tollPlazas.doc(plaza['id']).set({
              'id': plaza['id'],
              'name': plaza['name'],
              'location': plaza['location'],
              'district': plaza['district'],
              'highway': plaza['highway'],
              'latitude': plaza['latitude'],
              'longitude': plaza['longitude'],
              'amount': plaza['amount'] ?? 50,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'isActive': true,
            });
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get toll plaza by ID
  Future<TollPlazaModel?> getTollPlazaById(String plazaId) async {
    try {
      final doc = await _tollPlazas.doc(plazaId).get();
      if (doc.exists) {
        return TollPlazaModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Add new toll plaza
  Future<void> addTollPlaza({
    required String name,
    required String location,
    required String district,
    required String highway,
    required double latitude,
    required double longitude,
    required double amount,
  }) async {
    try {
      final id =
          '${district.toLowerCase()}_${name.toLowerCase().replaceAll(' ', '_')}';

      await _tollPlazas.doc(id).set({
        'id': id,
        'name': name,
        'location': location,
        'district': district,
        'highway': highway,
        'latitude': latitude,
        'longitude': longitude,
        'amount': amount,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Update toll plaza
  Future<void> updateTollPlaza({
    required String plazaId,
    String? name,
    String? location,
    String? district,
    String? highway,
    double? latitude,
    double? longitude,
    double? amount,
    bool? isActive,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (location != null) updateData['location'] = location;
      if (district != null) updateData['district'] = district;
      if (highway != null) updateData['highway'] = highway;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (amount != null) updateData['amount'] = amount;
      if (isActive != null) updateData['isActive'] = isActive;

      await _tollPlazas.doc(plazaId).update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  // Delete toll plaza (soft delete)
  Future<void> deleteTollPlaza(String plazaId) async {
    try {
      await _tollPlazas.doc(plazaId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get districts from Firestore (unique values)
  Future<List<String>> getDistricts() async {
    try {
      final snapshot =
          await _tollPlazas.where('isActive', isEqualTo: true).get();

      Set<String> districts = {};
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('district')) {
          districts.add(data['district']);
        }
      }

      return districts.toList()..sort();
    } catch (e) {
      return [];
    }
  }

  // ==================== TOLL ROUTE OPERATIONS ====================

  // Get all toll routes
  Stream<List<TollRouteModel>> getAllTollRoutes() {
    return _tollRoutes
        .where('isActive', isEqualTo: true)
        .orderBy('source')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TollRouteModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // Add toll route
  Future<void> addTollRoute(TollRouteModel route) async {
    try {
      await _tollRoutes.doc(route.id).set(route.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Update toll route
  Future<void> updateTollRoute(TollRouteModel route) async {
    try {
      await _tollRoutes.doc(route.id).update(route.toMap());
    } catch (e) {
      rethrow;
    }
  }

  // Delete toll route
  Future<void> deleteTollRoute(String routeId) async {
    try {
      await _tollRoutes.doc(routeId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // ==================== VEHICLE OPERATIONS ====================

  // Get all vehicles
  Stream<List<VehicleModel>> getAllVehicles() {
    return _vehicles.orderBy('displayName').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return VehicleModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // Get active vehicles only (for user app)
  Stream<List<VehicleModel>> getActiveVehicles() {
    return _vehicles
        .where('isActive', isEqualTo: true)
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VehicleModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // Add vehicle
  Future<void> addVehicle({
    required String name,
    required String displayName,
    required String category,
    required int seatingCapacity,
    required double baseTollMultiplier,
    String? model,
  }) async {
    try {
      final vehicleId = name.toLowerCase().replaceAll(' ', '_');
      final now = DateTime.now();

      Map<String, dynamic> vehicleData = {
        'name': vehicleId,
        'displayName': displayName,
        'vehicleName': displayName.split('(').first.trim(),
        'vehicleModel': model ?? '',
        'category': category,
        'seatingCapacity': seatingCapacity,
        'baseTollMultiplier': baseTollMultiplier,
        'isActive': true,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      await _vehicles.doc(vehicleId).set(vehicleData);
    } catch (e) {
      rethrow;
    }
  }

  // Update vehicle
  Future<void> updateVehicle({
    required String vehicleId,
    String? displayName,
    String? category,
    int? seatingCapacity,
    double? baseTollMultiplier,
    bool? isActive,
    String? model,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (displayName != null) updateData['displayName'] = displayName;
      if (category != null) updateData['category'] = category;
      if (seatingCapacity != null) {
        updateData['seatingCapacity'] = seatingCapacity;
      }
      if (baseTollMultiplier != null) {
        updateData['baseTollMultiplier'] = baseTollMultiplier;
      }
      if (isActive != null) updateData['isActive'] = isActive;
      if (model != null) updateData['model'] = model;

      await _vehicles.doc(vehicleId).update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  // Delete vehicle (soft delete)
  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _vehicles.doc(vehicleId).update({
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Get vehicle by ID
  Future<VehicleModel?> getVehicleById(String vehicleId) async {
    try {
      final doc = await _vehicles.doc(vehicleId).get();
      if (doc.exists) {
        return VehicleModel.fromFirestore(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // ==================== ENHANCED TOLL CALCULATION ====================
  // THIS IS THE KEY PART - COMBINING FIRESTORE AND LOCAL DATA

  // Enhanced route finding that works with both Firestore and local data
  Future<Map<String, dynamic>> findRouteWithLocal({
    required String source,
    required String destination,
  }) async {
    try {
      // First try Firestore
      final firestoreResult = await calculateToll(
        source: source,
        destination: destination,
      );

      if (firestoreResult['success'] == true && 
          firestoreResult['totalPlazas'] > 0) {
        return firestoreResult;
      }

      // If Firestore fails, try local data
      final localRoute = TamilNaduTollRoutes.getRoute(source, destination);
      
      if (localRoute != null) {
        final totalAmount = localRoute['totalTollAmount'] ?? 
                           localRoute['baseToll'] ?? 0;
        final tollPlazaIds = List<String>.from(localRoute['tollPlazaIds'] ?? []);
        
        // Get plaza details from local data
        List<Map<String, dynamic>> plazaDetails = [];
        for (var plazaId in tollPlazaIds) {
          final plaza = TamilNaduTollData.getAllTollPlazas()
              .firstWhere((p) => p['id'] == plazaId, orElse: () => {});
          if (plaza.isNotEmpty) {
            plazaDetails.add({
              'id': plazaId,
              'name': plaza['name'] ?? plazaId,
              'location': plaza['location'] ?? '',
              'district': plaza['district'] ?? '',
              'highway': plaza['highway'] ?? '',
              'amount': plaza['amount'] ?? 50,
            });
          }
        }

        return {
          'success': true,
          'source': source,
          'destination': destination,
          'totalPlazas': tollPlazaIds.length,
          'plazas': plazaDetails,
          'totalAmount': totalAmount.toDouble(),
          'distance': (localRoute['distance'] ?? 0).toDouble(),
          'message': 'Found in local database',
        };
      }

      // If no route found, try reverse
      final reverseLocalRoute = TamilNaduTollRoutes.getRoute(destination, source);
      if (reverseLocalRoute != null) {
        return await findRouteWithLocal(
          source: destination,
          destination: source,
        );
      }

      return {
        'success': false,
        'message': 'No toll route found between $source and $destination',
        'totalAmount': 0,
        'totalPlazas': 0,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'totalAmount': 0,
        'totalPlazas': 0,
      };
    }
  }

  // Original calculate toll method (keep this as is)
  Future<Map<String, dynamic>> calculateToll({
    required String source,
    required String destination,
  }) async {
    try {
      // First get the route
      final routeSnapshot = await _tollRoutes
          .where('source', isEqualTo: source)
          .where('destination', isEqualTo: destination)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (routeSnapshot.docs.isEmpty) {
        // Try reverse route
        final reverseSnapshot = await _tollRoutes
            .where('source', isEqualTo: destination)
            .where('destination', isEqualTo: source)
            .where('isActive', isEqualTo: true)
            .limit(1)
            .get();

        if (reverseSnapshot.docs.isEmpty) {
          return {
            'success': true,
            'message': 'No tolls on this route',
            'source': source,
            'destination': destination,
            'totalPlazas': 0,
            'totalAmount': 0,
          };
        }

        // Use reverse route
        final routeData =
            reverseSnapshot.docs.first.data() as Map<String, dynamic>;
        final tollPlazaIds = List<String>.from(routeData['tollPlazaIds'] ?? []);

        return await _calculateTollFromIds(
          tollPlazaIds: tollPlazaIds,
          source: source,
          destination: destination,
        );
      }

      final routeData = routeSnapshot.docs.first.data() as Map<String, dynamic>;
      final tollPlazaIds = List<String>.from(routeData['tollPlazaIds'] ?? []);

      return await _calculateTollFromIds(
        tollPlazaIds: tollPlazaIds,
        source: source,
        destination: destination,
      );
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Helper method to calculate toll from plaza IDs
  Future<Map<String, dynamic>> _calculateTollFromIds({
    required List<String> tollPlazaIds,
    required String source,
    required String destination,
  }) async {
    if (tollPlazaIds.isEmpty) {
      return {
        'success': true,
        'message': 'No toll plazas on this route',
        'source': source,
        'destination': destination,
        'totalPlazas': 0,
        'totalAmount': 0,
      };
    }

    // Get toll plaza details
    List<Map<String, dynamic>> plazaDetails = [];
    double totalAmount = 0;

    for (String plazaId in tollPlazaIds) {
      final plazaDoc = await _tollPlazas.doc(plazaId).get();
      if (plazaDoc.exists) {
        final plazaData = plazaDoc.data() as Map<String, dynamic>;

        // Get simple amount
        double amount = (plazaData['amount'] ?? 50).toDouble();

        totalAmount += amount;

        plazaDetails.add({
          'id': plazaId,
          'name': plazaData['name'],
          'location': plazaData['location'],
          'district': plazaData['district'],
          'highway': plazaData['highway'],
          'amount': amount,
        });
      }
    }

    return {
      'success': true,
      'source': source,
      'destination': destination,
      'totalPlazas': plazaDetails.length,
      'plazas': plazaDetails,
      'totalAmount': totalAmount,
      'message': totalAmount > 0
          ? 'Via $totalAmount toll plazas'
          : 'No tolls on this route',
    };
  }

  // Simple method to get just the amount (for quick display)
  Future<double> getTollAmount(String source, String destination) async {
    final result = await calculateToll(
      source: source,
      destination: destination,
    );

    if (result['success'] == true) {
      return result['totalAmount'] ?? 0;
    }
    return 0;
  }

  // ==================== LOCAL DATA HELPER METHODS ====================

  // Get all available sources from local data
  List<String> getAllSources() {
    return TamilNaduTollRoutes.getAllSources();
  }

  // Get destinations for a source
  List<String> getDestinationsForSource(String source) {
    return TamilNaduTollRoutes.getDestinationsBySource(source);
  }

  // Check if route exists in local data
  bool routeExists(String source, String destination) {
    return TamilNaduTollRoutes.getRoute(source, destination) != null;
  }

  // Get route summary from local data
  String getRouteSummary(String source, String destination) {
    return TollCalculator.getRouteSummary(source, destination);
  }

  // Get all locations from local data
  List<String> getAllLocations() {
    return TamilNaduTollRoutes.getAllLocations();
  }

  // ==================== DASHBOARD STATISTICS ====================

  // Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final vehiclesCount =
          await _vehicles.where('isActive', isEqualTo: true).count().get();

      final routesCount =
          await _tollRoutes.where('isActive', isEqualTo: true).count().get();

      final plazasCount =
          await _tollPlazas.where('isActive', isEqualTo: true).count().get();

      final bookingsCount = await _bookings.count().get();

      // Get recent bookings
      final recentBookings = await _bookings
          .orderBy('bookingDate', descending: true)
          .limit(5)
          .get();

      return {
        'success': true,
        'vehicles': vehiclesCount.count ?? 0,
        'routes': routesCount.count ?? 0,
        'plazas': plazasCount.count ?? 0,
        'bookings': bookingsCount.count ?? 0,
        'recentBookings': recentBookings.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            ...data,
          };
        }).toList(),
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}