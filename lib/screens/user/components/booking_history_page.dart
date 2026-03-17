// lib/screens/user/components/booking_history_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return _buildNotLoggedInScreen();
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        // 🔥 FIXED: Using 'userId' (lowercase) to match your Firestore document
        stream: _firestore
            .collection('bookings')
            .where('userId', isEqualTo: user.uid) // ✅ Correct field name
            .orderBy('bookingDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B14F)),
              ),
            );
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading bookings',
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B14F),
                      ),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          // No bookings state
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Show bookings
          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final bookingDoc = bookings[index];
              final booking = bookingDoc.data() as Map<String, dynamic>;
              booking['id'] = bookingDoc.id;

              return _buildBookingCard(booking);
            },
          );
        },
      ),
    );
  }

  // 🔥 Booking Card - Display each booking
  Widget _buildBookingCard(Map<String, dynamic> booking) {
    // Get status
    final status = booking['bookingStatus']?.toString().toLowerCase() ??
        booking['status']?.toString().toLowerCase() ??
        'pending';

    final statusConfig = _getStatusConfig(status);

    // Format date
    final date = _getDateTime(booking['bookingDate'] ?? booking['travelDate']);
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);

    // Get fare
    final totalAmount =
        _getDoubleValue(booking['totalAmount'] ?? booking['totalFare'] ?? 0);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header with status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (statusConfig['color'] as Color).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color:
                        (statusConfig['color'] as Color).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    statusConfig['icon'] as IconData,
                    color: statusConfig['color'] as Color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Booking #${booking['bookingId'] ?? booking['id'].toString().substring(0, 6)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        (statusConfig['color'] as Color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusConfig['text'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusConfig['color'] as Color,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // From - To
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.trip_origin,
                              size: 14, color: Color(0xFF00B14F)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('FROM',
                                    style: TextStyle(
                                        fontSize: 9, color: Colors.grey)),
                                Text(
                                  booking['fromLocation'] ?? 'N/A',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward,
                        size: 12, color: Colors.grey),
                    Expanded(
                      child: Row(
                        children: [
                          const SizedBox(width: 4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('TO',
                                    style: TextStyle(
                                        fontSize: 9, color: Colors.grey)),
                                Text(
                                  booking['toLocation'] ?? 'N/A',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Details Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetailItem(Icons.calendar_today, 'Date',
                        formattedDate.split(',')[0]),
                    _buildDetailItem(
                        Icons.access_time, 'Time', formattedDate.split(',')[1]),
                    _buildDetailItem(Icons.directions_car, 'Vehicle',
                        booking['vehicleType'] ?? 'N/A'),
                  ],
                ),

                const Divider(height: 20),

                // Fare
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '₹${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00B14F),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // View Details Button
                OutlinedButton(
                  onPressed: () => _showBookingDetails(booking),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00B14F),
                    side: const BorderSide(color: Color(0xFF00B14F)),
                    minimumSize: const Size(double.infinity, 36),
                  ),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for detail items
  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
        Text(value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // Status configuration
  Map<String, dynamic> _getStatusConfig(String status) {
    switch (status) {
      case 'completed':
        return {
          'color': const Color(0xFF00B14F),
          'icon': Icons.check_circle,
          'text': 'Completed'
        };
      case 'cancelled':
        return {'color': Colors.red, 'icon': Icons.cancel, 'text': 'Cancelled'};
      case 'pending':
        return {
          'color': Colors.orange,
          'icon': Icons.pending,
          'text': 'Pending'
        };
      case 'confirmed':
        return {
          'color': Colors.blue,
          'icon': Icons.check_circle_outline,
          'text': 'Confirmed'
        };
      default:
        return {
          'color': Colors.grey,
          'icon': Icons.help,
          'text': status[0].toUpperCase() + status.substring(1)
        };
    }
  }

  // Show booking details dialog
  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Booking Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                    'Booking ID', booking['bookingId'] ?? booking['id']),
                _buildDetailRow('Customer', booking['customerName'] ?? 'N/A'),
                _buildDetailRow('Phone', booking['customerPhone'] ?? 'N/A'),
                _buildDetailRow('From', booking['fromLocation'] ?? 'N/A'),
                _buildDetailRow('To', booking['toLocation'] ?? 'N/A'),
                _buildDetailRow('Trip Type', booking['tripType'] ?? 'N/A'),
                _buildDetailRow(
                    'Date',
                    _formatDate(
                        booking['bookingDate'] ?? booking['travelDate'])),
                _buildDetailRow('Vehicle', booking['vehicleType'] ?? 'N/A'),
                _buildDetailRow(
                    'Vehicle No', booking['vehicleNumber'] ?? 'N/A'),
                _buildDetailRow('Passengers',
                    'Adults: ${booking['adults'] ?? 0}, Children: ${booking['children'] ?? 0}'),
                _buildDetailRow('Distance', booking['distanceText'] ?? 'N/A'),
                _buildDetailRow('Duration', booking['duration'] ?? 'N/A'),
                _buildDetailRow('Base Fare',
                    '₹${_getDoubleValue(booking['baseFare']).toStringAsFixed(2)}'),
                if (booking['tollCharges'] != null &&
                    _getDoubleValue(booking['tollCharges']) > 0)
                  _buildDetailRow('Toll Charges',
                      '₹${_getDoubleValue(booking['tollCharges']).toStringAsFixed(2)}'),
                const Divider(),
                _buildDetailRow(
                  'Total Amount',
                  '₹${_getDoubleValue(booking['totalAmount'] ?? booking['totalFare']).toStringAsFixed(2)}',
                  isBold: true,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B14F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.history, size: 60, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            const Text(
              'No bookings yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Your booked rides will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Not logged in screen
  Widget _buildNotLoggedInScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Please login to view bookings',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B14F),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods
  DateTime _getDateTime(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is Timestamp) return date.toDate();
    if (date is DateTime) return date;
    return DateTime.now();
  }

  String _formatDate(dynamic date) {
    try {
      if (date == null) return 'N/A';
      if (date is Timestamp) {
        return DateFormat('dd MMM yyyy, hh:mm a').format(date.toDate());
      } else if (date is DateTime) {
        return DateFormat('dd MMM yyyy, hh:mm a').format(date);
      }
    } catch (e) {
      return 'Invalid date';
    }
    return 'N/A';
  }

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
