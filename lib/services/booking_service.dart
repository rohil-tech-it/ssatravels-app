// lib/services/booking_service.dart
// ignore_for_file: unused_element, avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import 'toll_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TollService _tollService = TollService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _bookings => _firestore.collection('bookings');
  CollectionReference get _tollCalculations =>
      _firestore.collection('toll_calculations');

  // Format: SSA + YYMMDD + 4-digit sequence (e.g., SSA2403070001)
  Future<String> _generateSSABookingId() async {
    try {
      final now = DateTime.now();
      
      final year = now.year.toString().substring(2); 
      final month = now.month.toString().padLeft(2, '0'); 
      final day = now.day.toString().padLeft(2, '0'); 
      final dateStr = '$year$month$day'; 
      
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final todayBookings = await _bookings
          .where('bookingDate', isGreaterThanOrEqualTo: startOfDay)
          .where('bookingDate', isLessThanOrEqualTo: endOfDay)
          .get();
      
      final count = todayBookings.docs.length;
      final sequence = (count + 1).toString().padLeft(4, '0'); // 0001, 0002, etc.
      
      // Final ID: SSA2403070001
      return 'SSA$dateStr$sequence';
      
    } catch (e) {
      final random = Random();
      final randomNum = random.nextInt(900000) + 100000; 
      final randomChars = String.fromCharCodes(
        List.generate(3, (_) => 65 + random.nextInt(26))
      ); // 3 random letters
      
      return 'SSA$randomNum$randomChars'; 
    }
  }

  Future<String> _generateRandomSSAId() async {
    final random = Random();
    final randomNum = random.nextInt(900000) + 100000; 
    final randomChars = String.fromCharCodes(
      List.generate(3, (_) => 65 + random.nextInt(26))
    ); 
    
    return 'SSA$randomNum$randomChars'; 
  }

  Future<Map<String, dynamic>> createBookingWithToll({
    required String fromLocation,
    required String toLocation,
    required DateTime travelDate,
    required String vehicleType,
    required String vehicleNumber,
    required int passengers,        
    required double baseFare,
    required String paymentMethod,
    DateTime? returnDate,
    required int adults,            
    required int children,         
    required int luggage,           
    String specialInstructions = '',
    String tripType = 'DROP TRIP',
  }) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'User not logged in'};
      }

      // Calculate toll
      final tollResult = await _tollService.calculateToll(
        source: fromLocation,
        destination: toLocation,
      );

      double tollAmount = 0;
      List<Map<String, dynamic>> tollPlazas = [];
      double distance = 0;
      String distanceText = '0 km';
      String duration = '0 h';
      int durationHours = 0;
      int durationMinutes = 0;

      if (tollResult['success'] == true) {
        tollAmount = tollResult['totalAmount'] ?? 0.0;
        tollPlazas = List<Map<String, dynamic>>.from(tollResult['plazas'] ?? []);
        distance = tollResult['distance'] ?? 0.0;
        distanceText = tollResult['distanceText'] ?? '0 km';
        duration = tollResult['duration'] ?? '0 h';
        durationHours = tollResult['durationHours'] ?? 0;
        durationMinutes = tollResult['durationMinutes'] ?? 0;
      }

      double totalAmount = baseFare + tollAmount;

      String customBookingId = await _generateSSABookingId();


      final now = FieldValue.serverTimestamp();
      
      final formattedDate = DateFormat('dd MMM yyyy').format(travelDate);
      final formattedTime = DateFormat('hh:mm a').format(travelDate);

      Map<String, dynamic> bookingData = {
        'bookingId': customBookingId,
        'documentId': customBookingId,
        'id': customBookingId,
        
        'userId': user.uid,                   
        'userID': user.uid,                  
        
        'customerName': user.displayName ?? 'User',
        'customerEmail': user.email ?? '',
        'customerPhone': user.phoneNumber ?? '',
        
        'fromLocation': fromLocation,
        'toLocation': toLocation,
        'pickupLocation': fromLocation,
        'dropLocation': toLocation,
        'travelDate': travelDate,
        'returnDate': returnDate,
        'tripType': tripType,
        
        'vehicleType': vehicleType,
        'vehicleNumber': vehicleNumber,
        'vehicleModel': 'Not specified',
        
        'passengers': passengers,        
        'adults': adults,                
        'children': children,            
        'luggage': luggage,              
        
        // 🔥 Fare details
        'baseFare': baseFare,            
        'tollAmount': tollAmount,         
        'tollCharges': tollAmount,        
        'totalAmount': totalAmount,      
        'totalFare': totalAmount,         
        'kmCharges': baseFare,            
        
        'driverAllowance': 0,             
        'driverFoodCharges': 100,        
        'extraHourCharges': 0,            
        'extraKmCharges': 0,              
        'nightHaltCharges': 0,            
        'waitingCharges': 0,               
        
        'distance': distance,              
        'distanceText': distanceText,      
        'duration': duration,              
        'durationHours': durationHours,    
        'durationMinutes': durationMinutes, 
        'selectedHours': durationHours,    
        'selectedMinutes': durationMinutes, 
        'selectedDuration': '${durationHours}h ${durationMinutes}m', 
        
        'bookingStatus': 'Pending',
        'status': 'Pending',
        'paymentStatus': 'Pending',
        'paymentMethod': paymentMethod,
        
        'bookingDate': now,
        'createdAt': now,
        'updatedAt': now,
        'bookedOn': '$formattedDate at $formattedTime',
        'formattedDate': formattedDate,
        'formattedTime': formattedTime,
        
        'tollPlazas': tollPlazas,
        'routeKey': tollResult['routeKey'] ?? '',
        'totalTollPlazas': tollResult['totalPlazas'] ?? 0,
      
        'pickupLatLng': null,
        'dropLatLng': null,
        
        'specialInstructions': specialInstructions,
      };

      await _bookings.doc(customBookingId).set(bookingData);

      await _tollCalculations.doc(customBookingId).set({
        'bookingId': customBookingId,
        'userId': user.uid,
        'fromLocation': fromLocation,
        'toLocation': toLocation,
        'vehicleType': vehicleType,
        'totalToll': tollAmount,
        'tollPlazas': tollPlazas,
        'routeKey': tollResult['routeKey'] ?? '',
        'distance': distance,
        'distanceText': distanceText,
        'duration': duration,
        'createdAt': now,
        'status': 'pending',
      });

      return {
        'success': true,
        'bookingId': customBookingId,
        'tollAmount': tollAmount,
        'totalAmount': totalAmount,
        'tollPlazas': tollPlazas,
        'message': 'Booking created successfully',
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  Stream<List<BookingModel>> getUserBookings() {
    User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }


    return _bookings
        .where('userId', isEqualTo: user.uid)
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BookingModel.fromMap(
              doc.id, 
              doc.data() as Map<String, dynamic>
            );
          }).toList();
        });
  }

  // Get booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      DocumentSnapshot doc = await _bookings.doc(bookingId).get();
      if (doc.exists) {
        return BookingModel.fromMap(
          doc.id, 
          doc.data() as Map<String, dynamic>
        );
      } else {
        print('❌ Booking not found');
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Update payment status
  Future<void> updatePaymentStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      
      await _bookings.doc(bookingId).update({
        'paymentStatus': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _tollCalculations.doc(bookingId).update({
        'status': status == 'completed' ? 'paid' : 'failed',
        'updatedAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      return;
    }
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      
      await _bookings.doc(bookingId).update({
        'bookingStatus': 'cancelled',
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _tollCalculations.doc(bookingId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      return;
    }
  }

  // Update ride status
  Future<void> updateRideStatus(String bookingId, String newStatus) async {
    try {
      
      await _bookings.doc(bookingId).update({
        'bookingStatus': newStatus,
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update ride status: $e');
    }
  }

  // Get toll calculation for booking
  Future<Map<String, dynamic>?> getTollCalculation(String bookingId) async {
    try {
      DocumentSnapshot doc = await _tollCalculations.doc(bookingId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Get all bookings (for admin)
  Stream<List<BookingModel>> getAllBookings() {
    return _bookings
        .orderBy('bookingDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BookingModel.fromMap(
              doc.id, 
              doc.data() as Map<String, dynamic>
            );
          }).toList();
        });
  }

  // Get bookings by date range (for admin)
  Stream<List<BookingModel>> getBookingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _bookings
        .where('travelDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('travelDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('travelDate')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BookingModel.fromMap(
              doc.id, 
              doc.data() as Map<String, dynamic>
            );
          }).toList();
        });
  }

  // Get today's bookings count
  Future<int> getTodaysBookingsCount() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      final todayBookings = await _bookings
          .where('bookingDate', isGreaterThanOrEqualTo: startOfDay)
          .where('bookingDate', isLessThanOrEqualTo: endOfDay)
          .count()
          .get();
      
      return todayBookings.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Get user's booking statistics
  Future<Map<String, dynamic>> getUserBookingStats(String userId) async {
    try {
      final snapshot = await _bookings
          .where('userId', isEqualTo: userId)
          .get();

      int totalBookings = snapshot.docs.length;
      int completedBookings = 0;
      int cancelledBookings = 0;
      int pendingBookings = 0;
      double totalSpent = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['bookingStatus']?.toString().toLowerCase() ?? '';
        final amount = _getDoubleValue(data['totalAmount'] ?? data['totalFare'] ?? 0);

        if (status == 'completed') {
          completedBookings++;
          totalSpent += amount;
        } else if (status == 'cancelled') {
          cancelledBookings++;
        } else {
          pendingBookings++;
        }
      }

      return {
        'totalBookings': totalBookings,
        'completedBookings': completedBookings,
        'cancelledBookings': cancelledBookings,
        'pendingBookings': pendingBookings,
        'totalSpent': totalSpent,
      };
    } catch (e) {
      return {
        'totalBookings': 0,
        'completedBookings': 0,
        'cancelledBookings': 0,
        'pendingBookings': 0,
        'totalSpent': 0.0,
      };
    }
  }

  // Helper method to safely get double values
  double _getDoubleValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
}