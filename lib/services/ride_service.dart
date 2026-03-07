// lib/services/ride_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RideService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection name constant for easier maintenance
  static const String _ridesCollection = 'rides';

  // ==================== STREAM METHODS ====================

  /// Get real-time stream of user's rides with optional filter
  /// Automatically creates necessary indexes if they don't exist
  Stream<QuerySnapshot> getUserRides({String? filterStatus}) {
    try {
      final user = _getCurrentUser();

      Query query = _firestore
          .collection(_ridesCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true);

      // Apply filter if not 'All'
      if (filterStatus != null && filterStatus != 'All') {
        query = _applyStatusFilter(query, filterStatus);
      }

      return query.snapshots();
    } catch (e) {
      return Stream.error('Failed to get rides: $e');
    }
  }

  /// Search rides - returns all user rides for client-side filtering
  Stream<QuerySnapshot> searchRides(String searchQuery) {
    try {
      final user = _getCurrentUser();

      return _firestore
          .collection(_ridesCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(50) // Limit to prevent too many results
          .snapshots();
    } catch (e) {
      return Stream.error('Failed to search rides: $e');
    }
  }

  /// Get stream of rides for a specific date range
  Stream<QuerySnapshot> getRidesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    try {
      final user = _getCurrentUser();

      return _firestore
          .collection(_ridesCollection)
          .where('userId', isEqualTo: user.uid)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .snapshots();
    } catch (e) {
      return Stream.error('Failed to get rides by date range: $e');
    }
  }

  // ==================== FUTURE METHODS ====================

  /// Get single ride details by ID
  Future<DocumentSnapshot> getRideDetails(String rideId) async {
    try {
      return await _firestore.collection(_ridesCollection).doc(rideId).get();
    } catch (e) {
      throw Exception('Failed to get ride details: $e');
    }
  }

  /// Get user ride statistics
  Future<Map<String, dynamic>> getUserRideStats() async {
    try {
      final user = _getCurrentUser();

      final QuerySnapshot snapshot = await _firestore
          .collection(_ridesCollection)
          .where('userId', isEqualTo: user.uid)
          .get();

      final rides = snapshot.docs;

      // Calculate statistics
      int totalRides = rides.length;
      int completedRides =
          rides.where((doc) => doc['status'] == 'completed').length;
      int cancelledRides =
          rides.where((doc) => doc['status'] == 'cancelled').length;
      int upcomingRides = rides
          .where((doc) =>
              doc['status'] == 'pending' || doc['status'] == 'accepted')
          .length;

      double totalSpent = rides.fold(0.0, (double total, doc) {
        return total + (doc['fare'] ?? 0.0).toDouble();
      });

      double averageSpent = totalRides > 0 ? totalSpent / totalRides : 0.0;

      // Get most used vehicle type
      Map<String, int> vehicleCount = {};
      for (var doc in rides) {
        String vehicle = doc['vehicleType'] ?? 'Unknown';
        vehicleCount[vehicle] = (vehicleCount[vehicle] ?? 0) + 1;
      }
      String favoriteVehicle = vehicleCount.isEmpty
          ? 'None'
          : vehicleCount.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;

      return {
        'totalRides': totalRides,
        'completedRides': completedRides,
        'cancelledRides': cancelledRides,
        'upcomingRides': upcomingRides,
        'totalSpent': totalSpent,
        'averageSpent': averageSpent,
        'favoriteVehicle': favoriteVehicle,
      };
    } catch (e) {
      throw Exception('Failed to get ride stats: $e');
    }
  }

  /// Get paginated rides
  Future<List<QueryDocumentSnapshot>> getPaginatedRides({
    DocumentSnapshot? lastDocument,
    int limit = 10,
    String? filterStatus,
  }) async {
    try {
      final user = _getCurrentUser();

      Query query = _firestore
          .collection(_ridesCollection)
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (filterStatus != null && filterStatus != 'All') {
        query = _applyStatusFilter(query, filterStatus);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs;
    } catch (e) {
      throw Exception('Failed to get paginated rides: $e');
    }
  }

  // ==================== WRITE METHODS ====================

  /// Create a new ride
  Future<String> createRide({
    required String pickupAddress,
    required String destinationAddress,
    required double fare,
    required String vehicleType,
    double? distance,
    int? duration,
    Map<String, dynamic>? additionalDetails,
  }) async {
    try {
      final user = _getCurrentUser();

      final rideData = {
        'userId': user.uid,
        'userEmail': user.email,
        'userPhone': user.phoneNumber,
        'status': 'pending',
        'fare': fare,
        'vehicleType': vehicleType,
        'pickupAddress': pickupAddress,
        'destinationAddress': destinationAddress,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'rideId': 'RIDE${DateTime.now().millisecondsSinceEpoch}',
        if (distance != null) 'distance': distance,
        if (duration != null) 'duration': duration,
        ...?additionalDetails,
      };

      final docRef =
          await _firestore.collection(_ridesCollection).add(rideData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create ride: $e');
    }
  }

  /// Cancel a ride
  Future<void> cancelRide(String rideId) async {
    try {
      await _firestore.collection(_ridesCollection).doc(rideId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel ride: $e');
    }
  }

  /// Rate a completed ride
  Future<void> rateRide(String rideId, double rating, {String? review}) async {
    try {
      if (rating < 0 || rating > 5) {
        throw Exception('Rating must be between 0 and 5');
      }

      await _firestore.collection(_ridesCollection).doc(rideId).update({
        'rating': rating,
        'review': review ?? '',
        'ratedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to rate ride: $e');
    }
  }

  /// Update ride status
  Future<void> updateRideStatus(String rideId, String newStatus) async {
    try {
      final validStatuses = [
        'pending',
        'accepted',
        'ongoing',
        'completed',
        'cancelled'
      ];
      if (!validStatuses.contains(newStatus.toLowerCase())) {
        throw Exception('Invalid status: $newStatus');
      }

      await _firestore.collection(_ridesCollection).doc(rideId).update({
        'status': newStatus.toLowerCase(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update ride status: $e');
    }
  }

  /// Delete a ride (use with caution - maybe only for admins)
  Future<void> deleteRide(String rideId) async {
    try {
      await _firestore.collection(_ridesCollection).doc(rideId).delete();
    } catch (e) {
      throw Exception('Failed to delete ride: $e');
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// Get ride summary for a specific period
  Future<Map<String, dynamic>> getRideSummaryForPeriod(
      DateTime start, DateTime end) async {
    try {
      final user = _getCurrentUser();

      final snapshot = await _firestore
          .collection(_ridesCollection)
          .where('userId', isEqualTo: user.uid)
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .get();

      final rides = snapshot.docs;

      double totalEarnings = rides.fold(0.0, (double total, doc) {
        return total + (doc['fare'] ?? 0.0).toDouble();
      });

      int rideCount = rides.length;
      double averageFare = rideCount > 0 ? totalEarnings / rideCount : 0.0;

      return {
        'period':
            '${DateFormat('MMM d').format(start)} - ${DateFormat('MMM d').format(end)}',
        'rideCount': rideCount,
        'totalEarnings': totalEarnings,
        'averageFare': averageFare,
      };
    } catch (e) {
      throw Exception('Failed to get ride summary: $e');
    }
  }

  // ==================== HELPER METHODS ====================

  /// Get current authenticated user
  User _getCurrentUser() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }
    return currentUser;
  }

  /// Apply status filter to query
  Query _applyStatusFilter(Query query, String filterStatus) {
    final filterValue = filterStatus.toLowerCase();

    if (filterValue == 'upcoming') {
      return query.where('status', whereIn: ['pending', 'accepted']);
    } else {
      return query.where('status', isEqualTo: filterValue);
    }
  }

  /// Check if a ride exists by ID
  Future<bool> rideExists(String rideId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_ridesCollection)
          .doc(rideId)
          .get();
      return docSnapshot.exists;
    } catch (e) {
      // Using debugPrint instead of print for production code
      return false;
    }
  }

  /// Get total ride count for current user
  Future<int> getTotalRideCount() async {
    try {
      final user = _getCurrentUser();

      final QuerySnapshot snapshot = await _firestore
          .collection(_ridesCollection)
          .where('userId', isEqualTo: user.uid)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}