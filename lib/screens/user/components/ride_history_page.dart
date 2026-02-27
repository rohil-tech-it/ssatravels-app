import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Completed', 'Cancelled', 'Upcoming'];

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ride History'),
          backgroundColor: const Color(0xFF00B14F),
        ),
        body: const Center(
          child: Text('Please login to view ride history'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ride History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF00B14F),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            color: Colors.white,
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: _selectedFilter == filter,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: const Color(0xFF00B14F),
                    labelStyle: TextStyle(
                      color: _selectedFilter == filter
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                );
              },
            ),
          ),

          // Ride History List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getRidesStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 80,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Error loading rides',
                          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          snapshot.error.toString(),
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'No rides found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Book your first ride!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final rides = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rides.length,
                  itemBuilder: (context, index) {
                    final rideDoc = rides[index];
                    final rideData = rideDoc.data() as Map<String, dynamic>;
                    // Add the document ID to the ride data
                    rideData['id'] = rideDoc.id;
                    return _buildRideCard(rideData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getRidesStream(String userId) {
    Query query = _firestore
        .collection('rides')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (_selectedFilter != 'All') {
      // Handle filter values (convert to lowercase for consistency)
      String filterValue = _selectedFilter.toLowerCase();
      if (filterValue == 'upcoming') {
        // You might want to handle upcoming differently based on your data structure
        query = query.where('status', isEqualTo: 'pending');
      } else {
        query = query.where('status', isEqualTo: filterValue);
      }
    }

    return query.snapshots();
  }

  Widget _buildRideCard(Map<String, dynamic> ride) {
    // Safely extract data with null checks
    final pickup = ride['pickup'] is Map ? ride['pickup'] as Map : {};
    final destination = ride['destination'] is Map ? ride['destination'] as Map : {};
    final status = ride['status']?.toString().toLowerCase() ?? 'unknown';
    final fare = (ride['fare'] ?? 0).toDouble();
    
    // Handle date parsing safely
    DateTime date;
    if (ride['createdAt'] != null) {
      if (ride['createdAt'] is Timestamp) {
        date = (ride['createdAt'] as Timestamp).toDate();
      } else if (ride['createdAt'] is DateTime) {
        date = ride['createdAt'] as DateTime;
      } else {
        date = DateTime.now();
      }
    } else {
      date = DateTime.now();
    }

    // Get ride ID safely
    String rideId = ride['rideId']?.toString() ?? 
                   ride['id']?.toString() ?? 
                   'N/A';
    if (rideId.length > 8) {
      rideId = rideId.substring(0, 8);
    }

    // Status colors and icons
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'completed':
        statusColor = const Color(0xFF00B14F);
        statusIcon = Icons.check_circle;
        statusText = 'Completed';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Cancelled';
        break;
      case 'pending':
      case 'upcoming':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        statusText = 'Upcoming';
        break;
      case 'ongoing':
      case 'accepted':
        statusColor = Colors.blue;
        statusIcon = Icons.directions_car;
        statusText = 'Ongoing';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = status[0].toUpperCase() + status.substring(1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Ride Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ride #$rideId',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(date),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ride Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Pickup
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B14F),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pickup',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            pickup['address']?.toString() ?? 'Unknown location',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Destination
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Destination',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            destination['address']?.toString() ?? 'Unknown location',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Divider
                Divider(color: Colors.grey[300]),

                // Fare and Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Fare',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '₹${fare.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00B14F),
                          ),
                        ),
                      ],
                    ),
                    if (status == 'completed')
                      ElevatedButton.icon(
                        onPressed: () {
                          _showRideDetails(ride);
                        },
                        icon: const Icon(Icons.receipt_long, size: 16),
                        label: const Text('Invoice'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF00B14F).withOpacity(0.1),
                          foregroundColor: const Color(0xFF00B14F),
                        ),
                      ),
                    if (status == 'pending' || status == 'upcoming')
                      ElevatedButton.icon(
                        onPressed: () {
                          _cancelRide(ride['id']);
                        },
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          foregroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Filter Rides',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ..._filters.map((filter) {
                  return RadioListTile<String>(
                    title: Text(filter),
                    value: filter,
                    groupValue: _selectedFilter,
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                      Navigator.pop(context);
                    },
                    activeColor: const Color(0xFF00B14F),
                  );
                }),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B14F),
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

  void _showRideDetails(Map<String, dynamic> ride) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ride Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                      'Ride ID', ride['rideId']?.toString() ?? 'N/A'),
                  _buildDetailRow(
                      'Date',
                      _formatDate(ride['createdAt'])),
                  _buildDetailRow(
                      'Time',
                      _formatTime(ride['createdAt'])),
                  _buildDetailRow('Status', ride['status']?.toString() ?? 'Unknown'),
                  _buildDetailRow(
                      'Vehicle Type', ride['vehicleType']?.toString() ?? 'Standard'),
                  _buildDetailRow('Distance', '${_getDoubleValue(ride['distance'])} km'),
                  _buildDetailRow('Duration', '${_getDoubleValue(ride['duration'])} mins'),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                  const Text(
                    'Fare Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildFareRow('Base Fare', _getDoubleValue(ride['baseFare'])),
                  _buildFareRow('Distance Charge', _getDoubleValue(ride['distanceCharge'])),
                  _buildFareRow('Time Charge', _getDoubleValue(ride['timeCharge'])),
                  if (_getDoubleValue(ride['tollCharge']) > 0)
                    _buildFareRow('Toll Charge', _getDoubleValue(ride['tollCharge'])),
                  if (_getDoubleValue(ride['waitingCharge']) > 0)
                    _buildFareRow('Waiting Charge', _getDoubleValue(ride['waitingCharge'])),
                  const Divider(),
                  _buildFareRow('Total', _getDoubleValue(ride['fare']), isTotal: true),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B14F),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    try {
      if (date == null) return 'N/A';
      if (date is Timestamp) {
        return DateFormat('MMMM dd, yyyy').format(date.toDate());
      } else if (date is DateTime) {
        return DateFormat('MMMM dd, yyyy').format(date);
      }
    } catch (e) {
      return 'Invalid date';
    }
    return 'N/A';
  }

  String _formatTime(dynamic date) {
    try {
      if (date == null) return 'N/A';
      if (date is Timestamp) {
        return DateFormat('hh:mm a').format(date.toDate());
      } else if (date is DateTime) {
        return DateFormat('hh:mm a').format(date);
      }
    } catch (e) {
      return 'Invalid time';
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? const Color(0xFF00B14F) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _cancelRide(String rideId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text('Are you sure you want to cancel this ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('rides').doc(rideId).update({
                  'status': 'cancelled',
                  'cancelledAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ride cancelled successfully'),
                      backgroundColor: Color(0xFF00B14F),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}