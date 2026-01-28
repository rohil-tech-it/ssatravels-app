// lib/services/booking_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ssatravels_app/models/booking_model.dart';

class BookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection reference
  CollectionReference get bookingsCollection => _firestore.collection('bookings');
  
  // Check if bookings collection exists
  Future<bool> checkBookingsCollection() async {
    try {
      final snapshot = await bookingsCollection.limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Get all bookings
  Stream<List<BookingModel>> getAllBookings() {
    return bookingsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookingModel.fromFirestore(doc))
            .toList());
  }
  
  // Add new booking
  Future<String> addBooking(BookingModel booking) async {
    try {
      final docRef = await bookingsCollection.add(booking.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding booking: $e');
      rethrow;
    }
  }
  
  // Update booking status
  Future<void> updateBookingStatus(String docId, String newStatus) async {
    try {
      await bookingsCollection.doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating status: $e');
      rethrow;
    }
  }
}