import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/admin_config.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ========== COLLECTION REFERENCES ==========
  static CollectionReference get vehicles =>
      FirebaseFirestore.instance.collection('vehicles');
  static CollectionReference get vehicleModels =>
      FirebaseFirestore.instance.collection('vehicleModels');
  static CollectionReference get tollDatabase =>
      FirebaseFirestore.instance.collection('tollDatabase');
  static CollectionReference get cities =>
      FirebaseFirestore.instance.collection('cities');
  static CollectionReference get routeDistances =>
      FirebaseFirestore.instance.collection('routeDistances');
  static CollectionReference get bookings =>
      FirebaseFirestore.instance.collection('bookings');
  static CollectionReference get users =>
      FirebaseFirestore.instance.collection('users');

  // ========== AUTH METHODS ==========
  Future<void> init() async {
    // Initialize if needed
    await _initializeDefaultVehicles();
  }

  // ========== NEW: INITIALIZE DEFAULT 8 VEHICLES IN VEHICLES COLLECTION ==========
  Future<void> _initializeDefaultVehicles() async {
    try {
      // Check if vehicles already exist
      final snapshot = await vehicles.get();

      // If less than 8 vehicles exist, create default 8 vehicles
      if (snapshot.docs.length < 8) {
        // COMPLETE LIST OF 8 VEHICLES for vehicles collection
        final List<Map<String, dynamic>> defaultVehicles = [
          {
            // Document ID: hatchback
            'vehicleType': 'hatchback',
            'displayName': 'Hatchback',
            'model': 'Swift/Tiago',
            'seatingCapacity': 5,
            'baseRate': 9.0,
            'driverFood': 100.0,
            'nightHalt': 100.0,
            'minHours': 8,
            'extraHourRate': 100.0,
            'driverAllowance': 300.0,
            'above200Rate': 10.0,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            // Document ID: sedan
            'vehicleType': 'sedan',
            'displayName': 'Sedan',
            'model': 'Honda City',
            'seatingCapacity': 5,
            'baseRate': 9.0,
            'driverFood': 100.0,
            'nightHalt': 100.0,
            'minHours': 8,
            'extraHourRate': 100.0,
            'driverAllowance': 300.0,
            'above200Rate': 11.0,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            // Document ID: innova
            'vehicleType': 'innova',
            'displayName': 'Innova',
            'model': 'Toyota Innova',
            'seatingCapacity': 7,
            'baseRate': 40.0,
            'driverFood': 0.0,
            'nightHalt': 100.0,
            'minHours': 8,
            'extraHourRate': 150.0,
            'driverAllowance': 300.0,
            'above200Rate': 15.0,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            // Document ID: tavera
            'vehicleType': 'tavera',
            'displayName': 'Tavera',
            'model': 'Chevrolet Tavera',
            'seatingCapacity': 9,
            'baseRate': 90.0,
            'driverFood': 0.0,
            'nightHalt': 100.0,
            'minHours': 8,
            'extraHourRate': 150.0,
            'driverAllowance': 300.0,
            'above200Rate': 15.0,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            // Document ID: ertiga
            'vehicleType': 'ertiga',
            'displayName': 'Ertiga',
            'model': 'Maruti Ertiga',
            'seatingCapacity': 7,
            'baseRate': 45.0,
            'driverFood': 100.0,
            'nightHalt': 100.0,
            'minHours': 8,
            'extraHourRate': 150.0,
            'driverAllowance': 350.0,
            'above200Rate': 18.0,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            // Document ID: tempo
            'vehicleType': 'tempo',
            'displayName': 'Tempo Traveller',
            'model': 'Tempo Traveller',
            'seatingCapacity': 14,
            'baseRate': 50.0,
            'driverFood': 100.0,
            'nightHalt': 150.0,
            'minHours': 8,
            'extraHourRate': 200.0,
            'driverAllowance': 400.0,
            'above200Rate': 20.0,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            // Document ID: tourist_van
            'vehicleType': 'tourist_van',
            'displayName': 'Tourist Van',
            'model': 'Tourist Van',
            'seatingCapacity': 18,
            'baseRate': 55.0,
            'driverFood': 100.0,
            'nightHalt': 150.0,
            'minHours': 8,
            'extraHourRate': 200.0,
            'driverAllowance': 450.0,
            'above200Rate': 22.0,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            // Document ID: van_407
            'vehicleType': 'van_407',
            'displayName': 'Van 407',
            'model': 'Van 407',
            'seatingCapacity': 25,
            'baseRate': 60.0,
            'driverFood': 150.0,
            'nightHalt': 200.0,
            'minHours': 8,
            'extraHourRate': 250.0,
            'driverAllowance': 500.0,
            'above200Rate': 25.0,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
        ];

        // Add all vehicles to Firebase
        for (var vehicle in defaultVehicles) {
          final docId = vehicle['vehicleType'];
          await vehicles.doc(docId).set(vehicle);
        }
      } else {}

      // Initialize vehicle models if empty or missing
      await _initializeVehicleModels();
    } catch (e) {
      return;
    }
  }

  // ========== INITIALIZE VEHICLE MODELS ==========
  Future<void> _initializeVehicleModels() async {
    try {
      final modelsSnapshot = await vehicleModels.get();

      // Hatchback Models
      if (!modelsSnapshot.docs.any((doc) => doc.id == 'hatchback')) {
        await vehicleModels.doc('hatchback').set({
          'vehicleType': 'Hatchback',
          'models': [
            'Tata Tiago',
            'Swift Dzire',
            'Hyundai Santro',
            'Tata Zest',
            'Toyota Liva',
          ],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Sedan Models
      if (!modelsSnapshot.docs.any((doc) => doc.id == 'sedan')) {
        await vehicleModels.doc('sedan').set({
          'vehicleType': 'Sedan',
          'models': [
            'Honda City',
            'Toyota Yaris',
            'Hyundai Verna',
            'Swift Dzire',
            'Toyota Etios',
            'Tata Zest',
            'Honda Amaze',
          ],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Innova Models
      if (!modelsSnapshot.docs.any((doc) => doc.id == 'innova')) {
        await vehicleModels.doc('innova').set({
          'vehicleType': 'Innova',
          'models': [
            'Toyota Innova Crysta',
            'Toyota Innova',
            'Toyota Innova HyCross',
          ],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Other vehicle types with empty models (admin can add later)
      final otherTypes = [
        'tavera',
        'ertiga',
        'tempo',
        'tourist_van',
        'van_407'
      ];
      for (var type in otherTypes) {
        if (!modelsSnapshot.docs.any((doc) => doc.id == type)) {
          await vehicleModels.doc(type).set({
            'vehicleType': type.replaceAll('_', ' ').toUpperCase(),
            'models': [],
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      return;
    }
  }

  // ========== GET ACTIVE VEHICLES FROM VEHICLES COLLECTION ==========
  static Future<List<Map<String, dynamic>>> getActiveVehicles() async {
    try {
      final snapshot = await vehicles.where('isActive', isEqualTo: true).get();

      List<Map<String, dynamic>> vehiclesList = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        vehiclesList.add({
          'id': doc.id,
          ...data,
        });
      }

      // Sort by seating capacity
      vehiclesList.sort((a, b) =>
          (a['seatingCapacity'] ?? 0).compareTo(b['seatingCapacity'] ?? 0));

      return vehiclesList;
    } catch (e) {
      return [];
    }
  }

  // ========== GET VEHICLE BY ID ==========
  static Future<Map<String, dynamic>?> getVehicleById(String vehicleId) async {
    try {
      final doc = await vehicles.doc(vehicleId.toLowerCase()).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ========== GET VEHICLE MODELS ==========
  static Future<List<String>> getVehicleModels(String vehicleType) async {
    try {
      final doc = await vehicleModels.doc(vehicleType.toLowerCase()).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final models = data?['models'] as List<dynamic>?;
        return models?.cast<String>() ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ========== ADD VEHICLE MODEL (Admin) ==========
  static Future<void> addVehicleModel(String vehicleType, String model) async {
    try {
      final docRef = vehicleModels.doc(vehicleType.toLowerCase());
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        List<dynamic> models = List.from(data['models'] ?? []);
        if (!models.contains(model)) {
          models.add(model);
          await docRef.update({
            'models': models,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        await docRef.set({
          'vehicleType': vehicleType,
          'models': [model],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to add vehicle model: $e');
    }
  }

  // ========== GET ALL RATE CARDS (FROM VEHICLES COLLECTION) ==========
  static Future<Map<String, dynamic>> getAllRateCards() async {
    try {
      final snapshot = await vehicles.where('isActive', isEqualTo: true).get();

      Map<String, dynamic> rateCards = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Convert vehicle document to rate card format
        rateCards[doc.id] = {
          'seats': data['seatingCapacity'] ?? 4,
          'below200': {
            'perKm': data['baseRate'] ?? 9.0,
            'driverFood': data['driverFood'] ?? 100.0,
            'nightHalt': data['nightHalt'] ?? 100.0,
            'minHours': data['minHours'] ?? 8,
            'extraHourRate': data['extraHourRate'] ?? 100.0,
          },
          'above200': {
            'perKm': data['above200Rate'] ?? (data['baseRate'] ?? 10.0) * 1.1,
            'driverAllowance': data['driverAllowance'] ?? 300.0,
            'driverFood': data['driverFood'] ?? 100.0,
            'nightHalt': data['nightHalt'] ?? 100.0,
            'minHours': data['minHours'] ?? 12,
            'extraHourRate': data['extraHourRate'] ?? 150.0,
          },
        };
      }

      return rateCards;
    } catch (e) {
      return {};
    }
  }

  // ========== GET ALL RATE CARDS LEGACY (BACKWARD COMPATIBILITY) ==========
  static Future<Map<String, dynamic>> getAllRateCardsLegacy() async {
    // Just call the same method - no separate rateCard collection needed
    return getAllRateCards();
  }

  // ========== ADD NEW VEHICLE TYPE ==========
  static Future<void> addNewVehicleType(
    String vehicleName,
    int seats,
    Map<String, dynamic> below200,
    Map<String, dynamic> above200,
  ) async {
    try {
      final vehicleType = vehicleName.toLowerCase().replaceAll(' ', '_');

      // Extract values from below200 and above200 maps
      final baseRate = below200['perKm'] ?? 9.0;
      final above200Rate = above200['perKm'] ?? baseRate * 1.1;
      final driverFood = below200['driverFood'] ?? 100.0;
      final nightHalt = below200['nightHalt'] ?? 100.0;
      final minHours = below200['minHours'] ?? 8;
      final extraHourRate = below200['extraHourRate'] ?? 100.0;
      final driverAllowance = above200['driverAllowance'] ?? 300.0;

      await vehicles.doc(vehicleType).set({
        'vehicleType': vehicleType,
        'displayName': vehicleName,
        'model': '',
        'seatingCapacity': seats,
        'baseRate': baseRate,
        'above200Rate': above200Rate,
        'driverFood': driverFood,
        'nightHalt': nightHalt,
        'minHours': minHours,
        'extraHourRate': extraHourRate,
        'driverAllowance': driverAllowance,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Also create empty models entry
      await vehicleModels.doc(vehicleType).set({
        'vehicleType': vehicleName,
        'models': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add vehicle type: $e');
    }
  }

  // ========== UPDATE VEHICLE RATES ==========
  static Future<void> updateVehicleRates(
    String vehicleType,
    Map<String, dynamic> newRates,
  ) async {
    try {
      final docRef = vehicles.doc(vehicleType.toLowerCase());
      final doc = await docRef.get();

      if (!doc.exists) {
        throw Exception('Vehicle not found');
      }

      // Extract rate data from the nested structure
      final below200 = newRates['below200'] as Map<String, dynamic>?;
      final above200 = newRates['above200'] as Map<String, dynamic>?;
      final seats = newRates['seats'];

      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (seats != null) {
        updateData['seatingCapacity'] = seats;
      }

      if (below200 != null) {
        if (below200.containsKey('perKm')) {
          updateData['baseRate'] = below200['perKm'];
        }
        if (below200.containsKey('driverFood')) {
          updateData['driverFood'] = below200['driverFood'];
        }
        if (below200.containsKey('nightHalt')) {
          updateData['nightHalt'] = below200['nightHalt'];
        }
        if (below200.containsKey('minHours')) {
          updateData['minHours'] = below200['minHours'];
        }
        if (below200.containsKey('extraHourRate')) {
          updateData['extraHourRate'] = below200['extraHourRate'];
        }
      }

      if (above200 != null) {
        if (above200.containsKey('perKm')) {
          updateData['above200Rate'] = above200['perKm'];
        }
        if (above200.containsKey('driverAllowance')) {
          updateData['driverAllowance'] = above200['driverAllowance'];
        }
      }

      await docRef.update(updateData);
    } catch (e) {
      throw Exception('Failed to update vehicle rates: $e');
    }
  }

  // ========== UPDATE RATE CARD (ALIAS FOR updateVehicleRates) ==========
  static Future<void> updateRateCard(
    String vehicleType,
    Map<String, dynamic> newRates,
  ) async {
    return updateVehicleRates(vehicleType, newRates);
  }

  // ========== UPDATE VEHICLE ACTIVITY ==========
  static Future<void> updateVehicleActivity(
      String vehicleType, bool isActive) async {
    try {
      await vehicles.doc(vehicleType.toLowerCase()).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update vehicle activity: $e');
    }
  }

  // ========== DELETE VEHICLE TYPE ==========
  static Future<void> deleteVehicleType(String vehicleType) async {
    try {
      await vehicles.doc(vehicleType.toLowerCase()).delete();
      await vehicleModels.doc(vehicleType.toLowerCase()).delete();
    } catch (e) {
      throw Exception('Failed to delete vehicle type: $e');
    }
  }

  // ========== GET VEHICLE SEATING CAPACITIES ==========
  static Future<Map<String, int>> getVehicleSeating() async {
    try {
      final snapshot = await vehicles.where('isActive', isEqualTo: true).get();

      Map<String, int> seating = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        seating[data['displayName'] ?? doc.id] = data['seatingCapacity'] ?? 4;
      }

      return seating;
    } catch (e) {
      return {};
    }
  }

  // ========== GET SPECIFIC RATE CARD ==========
  static Future<Map<String, dynamic>?> getRateCard(String vehicleType) async {
    try {
      final doc = await vehicles.doc(vehicleType.toLowerCase()).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Convert to rate card format
        return {
          'seats': data['seatingCapacity'] ?? 4,
          'below200': {
            'perKm': data['baseRate'] ?? 9.0,
            'driverFood': data['driverFood'] ?? 100.0,
            'nightHalt': data['nightHalt'] ?? 100.0,
            'minHours': data['minHours'] ?? 8,
            'extraHourRate': data['extraHourRate'] ?? 100.0,
          },
          'above200': {
            'perKm': data['above200Rate'] ?? (data['baseRate'] ?? 10.0) * 1.1,
            'driverAllowance': data['driverAllowance'] ?? 300.0,
            'driverFood': data['driverFood'] ?? 100.0,
            'nightHalt': data['nightHalt'] ?? 100.0,
            'minHours': data['minHours'] ?? 12,
            'extraHourRate': data['extraHourRate'] ?? 150.0,
          },
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ========== TOLL DATABASE METHODS ==========
  static Future<Map<String, dynamic>> getTollDatabase() async {
    try {
      final snapshot = await tollDatabase.get();
      Map<String, dynamic> tolls = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        tolls[doc.id] = data;
      }

      return tolls;
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>?> getTollForRoute(String route) async {
    try {
      final doc = await tollDatabase.doc(route).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateToll(
      String route, Map<String, dynamic> tollData) async {
    try {
      String formattedRoute =
          route.replaceAll(' ', '_').replaceAll('-', '_').toLowerCase();

      await tollDatabase.doc(formattedRoute).set({
        ...tollData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update toll: $e');
    }
  }

  // ========== ROUTE DISTANCES METHODS ==========
  static Future<Map<String, Map<String, double>>> getRouteDistances() async {
    try {
      final snapshot = await routeDistances.get();
      Map<String, Map<String, double>> routes = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        Map<String, double> distances = {};

        data.forEach((key, value) {
          if (key != 'createdAt' && key != 'updatedAt' && value != null) {
            try {
              distances[key] = (value as num).toDouble();
            } catch (_) {
              // ignored
            }
          }
        });

        routes[doc.id] = distances;
      }

      return routes;
    } catch (e) {
      return {};
    }
  }

  static Future<double?> getDistanceBetweenCities(
      String fromCity, String toCity) async {
    try {
      final doc = await routeDistances.doc(fromCity).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        final distance = data?[toCity];
        if (distance != null) {
          return (distance as num).toDouble();
        }
      }

      // Try reverse
      final reverseDoc = await routeDistances.doc(toCity).get();
      if (reverseDoc.exists) {
        final data = reverseDoc.data() as Map<String, dynamic>?;
        final distance = data?[fromCity];
        if (distance != null) {
          return (distance as num).toDouble();
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateRouteDistance(
    String fromCity,
    String toCity,
    double distance,
  ) async {
    try {
      await routeDistances.doc(fromCity).set({
        toCity: distance,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Also add reverse route
      await routeDistances.doc(toCity).set({
        fromCity: distance,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update route distance: $e');
    }
  }

  // ========== CITIES METHODS ==========
  static Future<Map<String, Map<String, dynamic>>> getCities() async {
    try {
      final snapshot = await cities.get();
      Map<String, Map<String, dynamic>> cityMap = {};

      for (var doc in snapshot.docs) {
        cityMap[doc.id] = doc.data() as Map<String, dynamic>;
      }

      return cityMap;
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>?> getCityCoordinates(
      String cityName) async {
    try {
      final doc = await cities.doc(cityName).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  static Future<void> updateCity(
      String cityName, double lat, double lng) async {
    try {
      await cities.doc(cityName).set({
        'lat': lat,
        'lng': lng,
        'name': cityName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update city: $e');
    }
  }

  // ========== BOOKING METHODS ==========
  static Future<void> saveBooking(Map<String, dynamic> bookingData) async {
    try {
      await bookings.add({
        ...bookingData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to save booking: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserBookings(
      String phoneNumber) async {
    try {
      final snapshot = await bookings
          .where('userPhone', isEqualTo: phoneNumber)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> userBookings = [];
      for (var doc in snapshot.docs) {
        userBookings.add({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }

      return userBookings;
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllBookings() async {
    try {
      final snapshot =
          await bookings.orderBy('createdAt', descending: true).get();

      List<Map<String, dynamic>> allBookings = [];
      for (var doc in snapshot.docs) {
        allBookings.add({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }

      return allBookings;
    } catch (e) {
      return [];
    }
  }

  static Future<void> updateBookingStatus(
    String bookingId,
    String status,
    String? driverId,
  ) async {
    try {
      await bookings.doc(bookingId).update({
        'status': status,
        if (driverId != null) 'driverId': driverId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // ========== USER METHODS ==========
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final phoneNumber = user.phoneNumber;
    if (phoneNumber == null) return false;

    try {
      final userDoc = await users.doc(phoneNumber).get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>?;
        return userData?['isAdmin'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getCurrentPhoneNumber() async {
    return _auth.currentUser?.phoneNumber;
  }

  Future<Map<String, dynamic>?> getUserData(String phoneNumber) async {
    try {
      final doc = await users.doc(phoneNumber).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> loginWithPhonePassword({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      String formattedPhone = phoneNumber;
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+91$formattedPhone';
      }

      final userDoc = await users.doc(formattedPhone).get();

      if (!userDoc.exists) {
        return {
          'success': false,
          'error': 'User not found. Please register first.',
        };
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final storedPassword = userData['password'] as String?;
      final isAdmin = userData['isAdmin'] == true;

      if (storedPassword == null || storedPassword != password) {
        return {
          'success': false,
          'error': 'Invalid password',
        };
      }

      try {
        await _auth.signInAnonymously();
      } catch (e) {
        // Continue anyway
      }

      return {
        'success': true,
        'isAdmin': isAdmin,
        'userData': userData,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Login failed. Please try again.',
      };
    }
  }

  Future<void> registerUser({
    required String phoneNumber,
    required String password,
    required String fullName,
    required String email,
  }) async {
    try {
      String formattedPhone = phoneNumber;
      if (!formattedPhone.startsWith('+')) {
        formattedPhone = '+91$formattedPhone';
      }

      final existingDoc = await users.doc(formattedPhone).get();

      if (existingDoc.exists) {
        throw Exception('User already exists with this phone number');
      }

      if (AdminConfig.adminPhoneNumbers.contains(formattedPhone)) {
        throw Exception('This phone number is reserved for admin');
      }

      final userData = {
        'phoneNumber': formattedPhone,
        'password': password,
        'fullName': fullName,
        'email': email,
        'isAdmin': false,
        'userType': 'regular',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await users.doc(formattedPhone).set(userData);

      try {
        await _auth.signInAnonymously();
      } catch (_) {
        // ignored
      }
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ========== STREAMS FOR REAL-TIME UPDATES ==========
  static Stream<DocumentSnapshot> getVehicleStream(String vehicleType) {
    return vehicles.doc(vehicleType.toLowerCase()).snapshots();
  }

  static Stream<QuerySnapshot> getAllVehiclesStream() {
    return vehicles.snapshots();
  }

  static Stream<QuerySnapshot> getActiveVehiclesStream() {
    return vehicles.where('isActive', isEqualTo: true).snapshots();
  }

  static Stream<DocumentSnapshot> getTollStream(String route) {
    return tollDatabase.doc(route).snapshots();
  }

  // ========== ADMIN DASHBOARD DATA ==========
  static Future<Map<String, dynamic>> getAllAdminData() async {
    try {
      final vehiclesList = await getActiveVehicles();
      final rateCards = await getAllRateCards();
      final tolls = await getTollDatabase();
      final routes = await getRouteDistances();
      final citiesData = await getCities();
      final allBookings = await getAllBookings();

      return {
        'vehicles': vehiclesList,
        'rateCards': rateCards,
        'tolls': tolls,
        'routes': routes,
        'cities': citiesData,
        'bookings': allBookings,
      };
    } catch (e) {
      return {};
    }
  }

  // ========== BACKWARD COMPATIBILITY METHODS ==========
  // These methods are kept for compatibility with existing code

  static CollectionReference get rateCard =>
      vehicles; // Alias for backward compatibility

  static Future<void> addNewVehicleTypeLegacy(
      String vehicleType, Map<String, dynamic> defaultRates) async {
    try {
      final vehicleName = vehicleType.replaceAll('_', ' ').toUpperCase();
      final seats = defaultRates['seats'] ?? 4;
      final below200 = defaultRates['below200'] ?? {};
      final above200 = defaultRates['above200'] ?? {};

      await addNewVehicleType(vehicleName, seats, below200, above200);
    } catch (e) {
      throw Exception('Failed to add vehicle type: $e');
    }
  }
}
