import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/admin_config.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== COLLECTION REFERENCES ==========
  static CollectionReference get rateCard =>
      FirebaseFirestore.instance.collection('rateCard');
  static CollectionReference get tollDatabase =>
      FirebaseFirestore.instance.collection('tollDatabase');
  static CollectionReference get cities =>
      FirebaseFirestore.instance.collection('cities');
  static CollectionReference get routeDistances =>
      FirebaseFirestore.instance.collection('routeDistances');
  static CollectionReference get vehicleModels =>
      FirebaseFirestore.instance.collection('vehicleModels');

  // ========== AUTH METHODS ==========
  Future<void> init() async {
    // Initialize if needed
    await _initializeDefaultVehicles(); // ADD THIS LINE
  }

  // ========== NEW: INITIALIZE DEFAULT 8 VEHICLES ==========
  Future<void> _initializeDefaultVehicles() async {
    try {
      // Check if vehicles already exist
      final snapshot = await rateCard.get();

      // If less than 8 vehicles exist, create default 8 vehicles
      if (snapshot.docs.length < 8) {
       
        // Delete existing vehicles first to avoid duplicates
        for (var doc in snapshot.docs) {
          await rateCard.doc(doc.id).delete();
        }

        // COMPLETE LIST OF 8 VEHICLES
        final List<Map<String, dynamic>> defaultVehicles = [
          {
            'vehicleName': 'Hatchback',
            'displayName': 'Hatchback',
            'seats': 5,
            'vehicleType': 'hatchback',
            'below200': {
              'hourlyRate': 100.0,
              'perKm': 9.0,
              'driverFood': 100.0,
              'nightHalt': 100.0,
              'minHours': 8,
            },
            'above200': {
              'perKm': 10.0,
              'driverAllowance': 300.0,
              'driverFood': 100.0,
              'nightHalt': 100.0,
            },
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'vehicleName': 'Sedan',
            'displayName': 'Sedan',
            'seats': 5,
            'vehicleType': 'sedan',
            'below200': {
              'hourlyRate': 150.0,
              'perKm': 9.0,
              'driverFood': 100.0,
              'nightHalt': 100.0,
              'minHours': 8,
            },
            'above200': {
              'perKm': 11.0,
              'driverAllowance': 300.0,
              'driverFood': 100.0,
              'nightHalt': 100.0,
            },
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'vehicleName': 'Innova',
            'displayName': 'Innova',
            'seats': 7,
            'vehicleType': 'innova',
            'below200': {
              'hourlyRate': 240.0,
              'perKm': 40.0,
              'driverFood': 0.0,
              'nightHalt': 100.0,
              'minHours': 8,
            },
            'above200': {
              'perKm': 15.0,
              'driverAllowance': 300.0,
              'driverFood': 100.0,
              'nightHalt': 100.0,
            },
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'vehicleName': 'Tavera',
            'displayName': 'Tavera',
            'seats': 9,
            'vehicleType': 'tavera',
            'below200': {
              'hourlyRate': 240.0,
              'perKm': 90.0,
              'driverFood': 0.0,
              'nightHalt': 100.0,
              'minHours': 8,
            },
            'above200': {
              'perKm': 15.0,
              'driverAllowance': 300.0,
              'driverFood': 100.0,
              'nightHalt': 100.0,
            },
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
          // Document ID: ertiga
          {
            // Basic Info
            'vehicleType': 'ertiga',
            'vehicleTypeName': 'Ertiga',
            'seats': 7,

            // Below 200 KM Rates
            'below200': {
              'hourlyRate': 280.0,
              'perKm': 45.0,
              'driverFood': 100.0,
              'nightHalt': 100.0,
              'minHours': 8,
            },

            // Above 200 KM Rates
            'above200': {
              'perKm': 18.0,
              'driverAllowance': 350.0,
              'driverFood': 100.0,
              'nightHalt': 100.0,
            },

            // Metadata
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'vehicleName': 'Tempo Traveller',
            'displayName': 'Tempo Traveller',
            'seats': 14,
            'vehicleType': 'tempo',
            'below200': {
              'hourlyRate': 320.0,
              'perKm': 50.0,
              'driverFood': 100.0,
              'nightHalt': 150.0,
              'minHours': 8,
            },
            'above200': {
              'perKm': 20.0,
              'driverAllowance': 400.0,
              'driverFood': 100.0,
              'nightHalt': 150.0,
            },
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'vehicleName': 'Tourist Van',
            'displayName': 'Tourist Van',
            'seats': 18,
            'vehicleType': 'tourist_van',
            'below200': {
              'hourlyRate': 380.0,
              'perKm': 55.0,
              'driverFood': 100.0,
              'nightHalt': 150.0,
              'minHours': 8,
            },
            'above200': {
              'perKm': 22.0,
              'driverAllowance': 450.0,
              'driverFood': 100.0,
              'nightHalt': 150.0,
            },
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
          {
            'vehicleName': 'Van 407',
            'displayName': 'Van 407',
            'seats': 25,
            'vehicleType': 'van_407',
            'below200': {
              'hourlyRate': 450.0,
              'perKm': 60.0,
              'driverFood': 150.0,
              'nightHalt': 200.0,
              'minHours': 8,
            },
            'above200': {
              'perKm': 25.0,
              'driverAllowance': 500.0,
              'driverFood': 150.0,
              'nightHalt': 200.0,
            },
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          },
        ];

        // Add all vehicles to Firebase
        for (var vehicle in defaultVehicles) {
          await rateCard.doc(vehicle['vehicleType']).set(vehicle);
        }

      } else {
      }

      // Initialize vehicle models if empty or missing
      final modelsSnapshot = await vehicleModels.get();

      // Check if hatchback and sedan documents exist
      final hasHatchback =
          modelsSnapshot.docs.any((doc) => doc.id == 'hatchback');
      final hasSedan = modelsSnapshot.docs.any((doc) => doc.id == 'sedan');

      if (!hasHatchback || !hasSedan) {
        await _initializeVehicleModels();
      }
    } catch (e) {
    }
  }

  // ========== NEW: INITIALIZE VEHICLE MODELS ==========
  Future<void> _initializeVehicleModels() async {
    try {

      // Hatchback Models
      await vehicleModels.doc('hatchback').set({
        'vehicleType': 'Hatchback',
        'models': [
          'Tata Tiago',
          'Swift Dzire, Hyundai Santro',
          'Tata Zest, Tata Indica',
          'Toyota Liva',
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Sedan Models
      await vehicleModels.doc('sedan').set({
        'vehicleType': 'Sedan',
        'models': [
          'Swift Dzire',
          'Toyota Etios',
          'Tata Zest',
          'Honda Amaze',
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Other vehicle types with empty models (admin can add later)
      final otherTypes = [
        'innova',
        'tavera',
        'ertiga',
        'tempo',
        'tourist_van',
        'van_407'
      ];
      for (var type in otherTypes) {
        await vehicleModels.doc(type).set({
          'vehicleType': type.replaceAll('_', ' ').toUpperCase(),
          'models': [],
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
    }
  }

  // ========== NEW: GET ACTIVE VEHICLES ONLY ==========
  static Future<List<Map<String, dynamic>>> getActiveVehicles() async {
    try {
      final snapshot = await rateCard.where('isActive', isEqualTo: true).get();

      List<Map<String, dynamic>> vehicles = [];
      for (var doc in snapshot.docs) {
        vehicles.add({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }

      // Sort by vehicle type or seats
      vehicles.sort((a, b) => a['seats'].compareTo(b['seats']));

      return vehicles;
    } catch (e) {
      return [];
    }
  }

  // ========== NEW: GET VEHICLE MODELS ==========
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

  // ========== NEW: ADD VEHICLE MODEL (Admin) ==========
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
      throw Exception('Failed to add vehicle model');
    }
  }

  // ========== MODIFIED: GET ALL RATE CARDS (ACTIVE ONLY) ==========
  static Future<Map<String, dynamic>> getAllRateCards() async {
    try {
      final snapshot = await rateCard.where('isActive', isEqualTo: true).get();

      Map<String, dynamic> activeRates = {};

      for (var doc in snapshot.docs) {
        activeRates[doc.id] = doc.data();
      }

      return activeRates;
    } catch (e) {
      return {};
    }
  }

  // ========== MODIFIED: ADD NEW VEHICLE TYPE ==========
  static Future<void> addNewVehicleType(
    String vehicleName,
    int seats,
    Map<String, dynamic> below200,
    Map<String, dynamic> above200,
  ) async {
    try {
      final vehicleType = vehicleName.toLowerCase().replaceAll(' ', '_');

      await rateCard.doc(vehicleType).set({
        'vehicleName': vehicleName,
        'displayName': vehicleName,
        'seats': seats,
        'vehicleType': vehicleType,
        'below200': below200,
        'above200': above200,
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
      throw Exception('Failed to add vehicle type');
    }
  }

  // ========== MODIFIED: GET SPECIFIC RATE ==========
  static Future<Map<String, dynamic>?> getRateCard(String vehicleType) async {
    try {
      final doc = await rateCard
          .where('vehicleType', isEqualTo: vehicleType.toLowerCase())
          .where('isActive', isEqualTo: true)
          .get();

      if (doc.docs.isNotEmpty) {
        return doc.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ========== MODIFIED: UPDATE VEHICLE ACTIVITY ==========
  static Future<void> updateVehicleActivity(
      String vehicleType, bool isActive) async {
    try {
      await rateCard.doc(vehicleType.toLowerCase()).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update vehicle activity');
    }
  }

  // ========== NEW: GET VEHICLE SEATING CAPACITIES ==========
  static Future<Map<String, int>> getVehicleSeating() async {
    try {
      final snapshot = await rateCard.where('isActive', isEqualTo: true).get();

      Map<String, int> seating = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        seating[data['vehicleName']] = data['seats'];
      }

      return seating;
    } catch (e) {
      return {};
    }
  }

  // ========== AUTH & USER METHODS ==========
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final phoneNumber = user.phoneNumber;
    if (phoneNumber == null) return false;

    try {
      final userDoc =
          await _firestore.collection('users').doc(phoneNumber).get();

      if (userDoc.exists) {
        final userData = userDoc.data();
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
      final doc = await _firestore.collection('users').doc(phoneNumber).get();

      return doc.data();
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

      final userDoc =
          await _firestore.collection('users').doc(formattedPhone).get();

      if (!userDoc.exists) {
        return {
          'success': false,
          'error': 'User not found. Please register first.',
        };
      }

      final userData = userDoc.data()!;
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

      final existingDoc =
          await _firestore.collection('users').doc(formattedPhone).get();

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

      await _firestore.collection('users').doc(formattedPhone).set(userData);

      try {
        await _auth.signInAnonymously();
      } catch (e) {
      }
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  // ========== BOOKING DATA METHODS ==========

  // 1. GET ALL RATE CARDS (LEGACY - INCLUDES INACTIVE)
  static Future<Map<String, dynamic>> getAllRateCardsLegacy() async {
    try {
      final snapshot = await rateCard.get();
      Map<String, dynamic> allRates = {};

      for (var doc in snapshot.docs) {
        allRates[doc.id] = doc.data();
      }

      return allRates;
    } catch (e) {
      return {};
    }
  }

  // 2. GET TOLL DATABASE (FIXED RETURN TYPE)
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

  // 3. GET ROUTE DISTANCES - ADDED MISSING METHOD
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
            } catch (e) {
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

  // 4. GET CITIES
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

  // 5. UPDATE RATE CARD (Admin Method)
  static Future<void> updateRateCard(
    String vehicleType,
    Map<String, dynamic> newRates,
  ) async {
    try {
      await rateCard
          .doc(vehicleType.toLowerCase())
          .set(newRates, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update rate card');
    }
  }

  // 6. UPDATE TOLL (Admin Method)
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
      throw Exception('Failed to update toll');
    }
  }

  // 7. UPDATE CITY (Admin Method)
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
      throw Exception('Failed to update city');
    }
  }

  // 8. UPDATE ROUTE DISTANCE (Admin Method)
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
      throw Exception('Failed to update route distance');
    }
  }

  // 9. STREAM FOR REAL-TIME UPDATES
  static Stream<DocumentSnapshot> getRateCardStream(String vehicleType) {
    return rateCard.doc(vehicleType.toLowerCase()).snapshots();
  }

  static Stream<QuerySnapshot> getAllRatesStream() {
    return rateCard.snapshots();
  }

  static Stream<QuerySnapshot> getActiveRatesStream() {
    return rateCard.where('isActive', isEqualTo: true).snapshots();
  }

  static Stream<DocumentSnapshot> getTollStream(String route) {
    return tollDatabase.doc(route).snapshots();
  }

  // 10. GET TOLL FOR SPECIFIC ROUTE
  static Future<Map<String, dynamic>?> getTollForRoute(String route) async {
    try {
      final doc = await tollDatabase.doc(route).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  // 11. GET CITY COORDINATES
  static Future<Map<String, dynamic>?> getCityCoordinates(
      String cityName) async {
    try {
      final doc = await cities.doc(cityName).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  // 12. GET DISTANCE BETWEEN TWO CITIES
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

  // 13. ADD NEW VEHICLE TYPE (Admin - LEGACY VERSION)
  static Future<void> addNewVehicleTypeLegacy(
      String vehicleType, Map<String, dynamic> defaultRates) async {
    try {
      await rateCard.doc(vehicleType.toLowerCase()).set({
        ...defaultRates,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
     throw Exception('Failed to add vehicle type');
    }
  }

  // 14. DELETE VEHICLE TYPE (Admin)
  static Future<void> deleteVehicleType(String vehicleType) async {
    try {
      await rateCard.doc(vehicleType.toLowerCase()).delete();
      await vehicleModels.doc(vehicleType.toLowerCase()).delete();
    } catch (e) {
      throw Exception('Failed to delete vehicle type');
    }
  }

  // 15. GET ALL ADMIN DATA AT ONCE (For Dashboard)
  static Future<Map<String, dynamic>> getAllAdminData() async {
    try {
      final rateCards = await getAllRateCardsLegacy();
      final tolls = await getTollDatabase();
      final routes = await getRouteDistances();
      final citiesData = await getCities();
      final activeVehicles = await getActiveVehicles();

      return {
        'rateCards': rateCards,
        'tolls': tolls,
        'routes': routes,
        'cities': citiesData,
        'activeVehicles': activeVehicles,
      };
    } catch (e) {
      return {};
    }
  }

  // 16. SAVE BOOKING TO FIRESTORE
  static Future<void> saveBooking(Map<String, dynamic> bookingData) async {
    try {
      final bookingsRef = FirebaseFirestore.instance.collection('bookings');
      await bookingsRef.add({
        ...bookingData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to save booking');
    }
  }

  // 17. GET USER BOOKINGS
  static Future<List<Map<String, dynamic>>> getUserBookings(
      String phoneNumber) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userPhone', isEqualTo: phoneNumber)
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> bookings = [];
      for (var doc in snapshot.docs) {
        bookings.add({
          'id': doc.id,
          ...doc.data(),
        });
      }

      return bookings;
    } catch (e) {
      return [];
    }
  }

  // 18. GET ALL BOOKINGS (Admin)
  static Future<List<Map<String, dynamic>>> getAllBookings() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get();

      List<Map<String, dynamic>> bookings = [];
      for (var doc in snapshot.docs) {
        bookings.add({
          'id': doc.id,
          ...doc.data(),
        });
      }

      return bookings;
    } catch (e) {
      return [];
    }
  }

  // 19. UPDATE BOOKING STATUS
  static Future<void> updateBookingStatus(
    String bookingId,
    String status,
    String? driverId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': status,
        if (driverId != null) 'driverId': driverId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update booking status');
    }
  }
}
