import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/booking_model.dart';
import 'toll_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TollService _tollService = TollService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get _bookings => _firestore.collection('bookings');
  CollectionReference get _tollCalculations => _firestore.collection('toll_calculations');

  // Create booking with toll calculation - UPDATED VERSION
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
  }) async {
    try {
      // Get current user
      User? user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }

      // ✅ FIXED: Use calculateToll instead of getTollsByRoute (no vehicleType)
      final tollResult = await _tollService.calculateToll(
        source: fromLocation,
        destination: toLocation,
        // vehicleType parameter REMOVED
      );

      double tollAmount = 0;
      List<Map<String, dynamic>> tollPlazas = [];

      if (tollResult['success'] == true) {
        tollAmount = tollResult['totalAmount'] ?? 0.0; // Changed from totalToll
        tollPlazas = List<Map<String, dynamic>>.from(tollResult['plazas'] ?? []);
      }

      // Calculate total amount
      double totalAmount = baseFare + tollAmount;

      // Create booking
      BookingModel booking = BookingModel(
        userId: user.uid,
        userName: user.displayName ?? 'User',
        userEmail: user.email ?? '',
        userPhone: user.phoneNumber ?? '',
        fromLocation: fromLocation,
        toLocation: toLocation,
        travelDate: travelDate,
        returnDate: returnDate,
        vehicleType: vehicleType,
        vehicleNumber: vehicleNumber,
        passengers: passengers,
        baseFare: baseFare,
        tollAmount: tollAmount,
        totalAmount: totalAmount,
        paymentMethod: paymentMethod,
        paymentStatus: 'pending',
        bookingStatus: 'confirmed',
        bookingDate: DateTime.now(),
        tollPlazas: tollPlazas,
        routeKey: tollResult['routeKey'], // May be null
        totalTollPlazas: tollResult['totalPlazas'] ?? 0,
      );

      // Save to Firestore
      DocumentReference docRef = await _bookings.add(booking.toMap());
      
      // Also save toll calculation separately
      await _tollCalculations.doc(docRef.id).set({
        'bookingId': docRef.id,
        'userId': user.uid,
        'fromLocation': fromLocation,
        'toLocation': toLocation,
        'vehicleType': vehicleType,
        'totalToll': tollAmount,
        'tollPlazas': tollPlazas,
        'routeKey': tollResult['routeKey'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      return {
        'success': true,
        'bookingId': docRef.id,
        'tollAmount': tollAmount,
        'totalAmount': totalAmount,
        'tollPlazas': tollPlazas,
      };
    } catch (e) {
      print('❌ Error creating booking: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Get user bookings
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
              doc.data() as Map<String, dynamic>,
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
          doc.data() as Map<String, dynamic>,
        );
      }
    } catch (e) {
      print('❌ Error getting booking: $e');
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
      
      // Also update toll calculation status
      await _tollCalculations.doc(bookingId).update({
        'status': status == 'completed' ? 'paid' : 'failed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error updating payment status: $e');
    }
  }

  // Cancel booking
  Future<void> cancelBooking(String bookingId) async {
    try {
      await _bookings.doc(bookingId).update({
        'bookingStatus': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await _tollCalculations.doc(bookingId).update({
        'status': 'cancelled',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error cancelling booking: $e');
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
      print('❌ Error getting toll calculation: $e');
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
              doc.data() as Map<String, dynamic>,
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
        .where('travelDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('travelDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('travelDate')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return BookingModel.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();
        });
  }
}