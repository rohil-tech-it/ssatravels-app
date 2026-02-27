import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/toll_plaza_model.dart';
import '../models/toll_route_model.dart';
import '../models/vehicle_model.dart';
import '../data/tamilnadu_toll_plazas.dart';

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
      print('🚀 Starting toll plaza initialization...');

      final plazas = TamilNaduTollData.getAllTollPlazas();
      int successCount = 0;
      int errorCount = 0;

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
              'amount': plaza['amount'] ?? 50, // SIMPLE AMOUNT
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'isActive': true,
            });
            successCount++;
            print('✅ Added: ${plaza['name']} - ₹${plaza['amount']}');
          } else {
            print('⏭️ Already exists: ${plaza['name']}');
          }
        } catch (e) {
          errorCount++;
          print('❌ Error adding ${plaza['name']}: $e');
        }
      }

      print('✅ Import completed: $successCount added, $errorCount errors');
    } catch (e) {
      print('❌ Error initializing tolls: $e');
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
      print('Error getting toll plaza: $e');
    }
    return null;
  }

  // Add new toll plaza - SIMPLE AMOUNT VERSION
  Future<void> addTollPlaza({
    required String name,
    required String location,
    required String district,
    required String highway,
    required double latitude,
    required double longitude,
    required double amount, // Simple amount - no rates map
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
        'amount': amount, // Simple amount field
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Toll plaza added: $name - ₹$amount');
    } catch (e) {
      print('Error adding toll plaza: $e');
      rethrow;
    }
  }

  // Update toll plaza - SIMPLE AMOUNT VERSION
  Future<void> updateTollPlaza({
    required String plazaId,
    String? name,
    String? location,
    String? district,
    String? highway,
    double? latitude,
    double? longitude,
    double? amount, // Simple amount
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
      if (amount != null) updateData['amount'] = amount; // Simple amount
      if (isActive != null) updateData['isActive'] = isActive;

      await _tollPlazas.doc(plazaId).update(updateData);
      print('✅ Toll plaza updated: $plazaId');
    } catch (e) {
      print('Error updating toll plaza: $e');
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
      print('✅ Toll plaza deleted: $plazaId');
    } catch (e) {
      print('Error deleting toll plaza: $e');
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
      print('Error getting districts: $e');
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
      print('✅ Toll route added: ${route.id}');
    } catch (e) {
      print('Error adding toll route: $e');
      rethrow;
    }
  }

  // Update toll route
  Future<void> updateTollRoute(TollRouteModel route) async {
    try {
      await _tollRoutes.doc(route.id).update(route.toMap());
      print('✅ Toll route updated: ${route.id}');
    } catch (e) {
      print('Error updating toll route: $e');
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
      print('✅ Toll route deleted: $routeId');
    } catch (e) {
      print('Error deleting toll route: $e');
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
  // In toll_service.dart, update addVehicle method:

  Future<void> addVehicle({
    required String name,
    required String displayName,
    required String category, // This should match rateCard keys
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
        'category': category, // Save the category
        'seatingCapacity': seatingCapacity,
        'baseTollMultiplier': baseTollMultiplier,
        'isActive': true,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };

      await _vehicles.doc(vehicleId).set(vehicleData);
      print('✅ Vehicle added: $displayName with category: $category');
    } catch (e) {
      print('Error adding vehicle: $e');
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
    String? model, // ← ADD THIS LINE
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      if (displayName != null) updateData['displayName'] = displayName;
      if (category != null) updateData['category'] = category;
      if (seatingCapacity != null)
        updateData['seatingCapacity'] = seatingCapacity;
      if (baseTollMultiplier != null)
        updateData['baseTollMultiplier'] = baseTollMultiplier;
      if (isActive != null) updateData['isActive'] = isActive;
      if (model != null) updateData['model'] = model; // ← ADD THIS LINE

      await _vehicles.doc(vehicleId).update(updateData);
      print('✅ Vehicle updated: $vehicleId');
    } catch (e) {
      print('Error updating vehicle: $e');
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
      print('✅ Vehicle deleted: $vehicleId');
    } catch (e) {
      print('Error deleting vehicle: $e');
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
      print('Error getting vehicle: $e');
    }
    return null;
  }

  // ==================== TOLL CALCULATION ====================
  // UPDATED: Simple amount calculation - no vehicle types

  // Calculate toll between two cities - SIMPLE VERSION
  Future<Map<String, dynamic>> calculateToll({
    required String source,
    required String destination,
  }) async {
    try {
      print('📍 Calculating toll for route: $source → $destination');

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
            'totalAmount': 0, // Simple amount
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
      print('❌ Error calculating toll: $e');
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
      'totalAmount': totalAmount, // Simple total amount
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
      print('Error getting stats: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
