// lib/screens/admin/admin_booking_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ WhatsApp launcher

class AdminBookingScreen extends StatefulWidget {
  const AdminBookingScreen({Key? key}) : super(key: key);

  @override
  State<AdminBookingScreen> createState() => _AdminBookingScreenState();
}

class _AdminBookingScreenState extends State<AdminBookingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'All';
  DateTime? _selectedDate;
  Map<String, dynamic>? _adminData;

  // Admin Colors
  final Color _adminPrimaryColor = const Color(0xFF00C853); // Green
  final Color _adminAccentColor = const Color(0xFF00E676);
  final Color _adminBackground = const Color(0xFFF5FDF8);
  final Color _adminCardColor = Colors.white;

  final List<String> _statusOptions = [
    'All',
    'Pending',
    'Confirmed',
    'Processing',
    'Completed',
    'Cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _loadBookings();

    // Debug print
  }

  Future<void> _loadAdminData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot adminSnapshot =
            await _firestore.collection('admins').doc(user.uid).get();

        if (adminSnapshot.exists) {
          setState(() {
            _adminData = adminSnapshot.data() as Map<String, dynamic>;
          });
        } else {}
      } else {}
    } catch (e) {
      return;
    }
  }

  Future<void> _loadBookings() async {
    try {
      setState(() => _isLoading = true);

      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get();

      // Debug: Print all document IDs
      for (var doc in snapshot.docs) {}

      List<Map<String, dynamic>> bookings = [];

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // Calculate hours/days for display
        String hoursDays = '';
        if (data['isPackageTrip'] == true && data['packageHours'] != null) {
          hoursDays = '${data['packageHours']} hours';
        } else if (data['distance'] != null) {
          double distance = double.tryParse(data['distance'].toString()) ?? 0.0;
          if (distance > 200) {
            int days = (distance / 400).ceil();
            hoursDays = '$days days';
          } else {
            hoursDays = '1 day';
          }
        } else {
          hoursDays = '1 day';
        }

        // Get vehicle data if available
        String vehicleName = data['vehicleType'] ?? 'N/A';
        if (data['vehicleId'] != null) {
          try {
            DocumentSnapshot vehicleSnapshot = await _firestore
                .collection('vehicles')
                .doc(data['vehicleId'])
                .get();
            if (vehicleSnapshot.exists) {
              var vehicleData = vehicleSnapshot.data() as Map<String, dynamic>;
              vehicleName = vehicleData['name'] ?? vehicleName;
            }
          } catch (e) {
            return;
          }
        }

        // ✅ FIX: Handle both bookingStatus and status fields
        String status = data['bookingStatus'] ?? data['status'] ?? 'Pending';

        // ✅ FIXED: Handle distance formatting safely
        String distanceFormatted = '';
        if (data['distance'] != null) {
          double distance = double.tryParse(data['distance'].toString()) ?? 0.0;
          distanceFormatted = '${distance.toStringAsFixed(1)} km';
        } else {
          distanceFormatted = '0 km';
        }

        bookings.add({
          'id': doc.id,
          ...data,
          'displayDate': data['formattedDate'] ??
              data['pickupDate'] ??
              _formatDate(data['createdAt']),
          'displayTime': data['formattedTime'] ?? data['pickupTime'] ?? 'N/A',
          'hoursDays': data['hoursDays'] ?? hoursDays,
          'totalFareFormatted':
              _formatCurrency(data['totalFare'] ?? data['totalAmount'] ?? 0),
          'vehicleName': vehicleName,
          'status': status, // ✅ Use the resolved status
          'bookingStatus': status, // ✅ Add bookingStatus for compatibility
          'paymentStatus': data['paymentStatus'] ?? 'Unpaid',
          'createdAtFormatted': _formatDateTime(data['createdAt']),
          'updatedAtFormatted': _formatDateTime(data['updatedAt']),
          'distanceFormatted': distanceFormatted, // ✅ Added formatted distance
        });
      }

      setState(() {
        _bookings = bookings;
        _filteredBookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Error loading bookings. Please check your connection.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _bookings;

    // Status filter - use both bookingStatus and status fields
    if (_selectedStatus != 'All') {
      filtered = filtered.where((booking) {
        String status = booking['bookingStatus'] ?? booking['status'] ?? '';
        String searchStatus = _selectedStatus.toLowerCase();
        String bookingStatus = status.toLowerCase();
        return bookingStatus == searchStatus;
      }).toList();
    }

    // Date filter
    if (_selectedDate != null) {
      filtered = filtered.where((booking) {
        Timestamp? timestamp = booking['createdAt'];
        if (timestamp == null) return false;
        DateTime bookingDate = timestamp.toDate();
        return bookingDate.year == _selectedDate!.year &&
            bookingDate.month == _selectedDate!.month &&
            bookingDate.day == _selectedDate!.day;
      }).toList();
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((booking) {
        return (booking['customerName'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (booking['bookingId'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (booking['vehicleName'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (booking['customerPhone'] ?? '').contains(_searchQuery);
      }).toList();
    }

    setState(() {
      _filteredBookings = filtered;
    });
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(timestamp.toDate());
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('hh:mm a').format(timestamp.toDate());
  }

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
  }

  // ✅ FIXED: Handle currency formatting safely
  String _formatCurrency(dynamic amount) {
    try {
      if (amount == null) return '₹0';

      // Convert to double safely
      double value;
      if (amount is String) {
        value = double.tryParse(amount) ?? 0.0;
      } else if (amount is int) {
        value = amount.toDouble();
      } else if (amount is double) {
        value = amount;
      } else {
        value = 0.0;
      }

      // Format with commas
      String formatted = value.toStringAsFixed(0);
      if (formatted.contains('.')) {
        formatted = formatted.split('.')[0];
      }

      // Add commas for thousands
      final regExp = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      formatted = formatted.replaceAllMapped(regExp, (Match m) => '${m[1]},');

      return '₹$formatted';
    } catch (e) {
      return '₹0';
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return const Color(0xFF00B14F);
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    if (status == null) return Icons.question_mark;
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'processing':
        return Icons.refresh;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.question_mark;
    }
  }

  // ✅ WhatsApp Message Send Function
  Future<void> _sendWhatsAppNotification({
    required String customerPhone,
    required String customerName,
    required String bookingId,
    required String oldStatus,
    required String newStatus,
  }) async {
    try {
      // Clean phone number (remove +91, spaces, etc.)
      String cleanPhone = customerPhone
          .replaceAll('+91', '')
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .trim();

      // If phone doesn't start with country code, add it
      if (!cleanPhone.startsWith('91') && cleanPhone.length == 10) {
        cleanPhone = '91$cleanPhone';
      }

      // Create message
      String message = '''
Hi ${customerName},

Your booking status has been updated!

📋 *Booking ID:* ${bookingId.substring(0, 8)}
🔄 *Old Status:* $oldStatus
✅ *New Status:* $newStatus

Thank you for choosing our service!
For any queries, contact us :+91 9751867879.

Best regards,
SSA Travels Virudhhunagar 
      '''
          .trim();

      // Encode message for URL
      String encodedMessage = Uri.encodeComponent(message);

      // WhatsApp URL
      String whatsappUrl = 'https://wa.me/$cleanPhone?text=$encodedMessage';

      // Launch WhatsApp
      if (await canLaunch(whatsappUrl)) {
        await launch(whatsappUrl);
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening WhatsApp: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ WhatsApp Dialog
  Future<void> _showWhatsAppDialog(Map<String, dynamic> booking) async {
    String phone = booking['customerPhone'] ?? '';
    String name = booking['customerName'] ?? 'Customer';
    String bookingId = booking['bookingId'] ?? '';
    String currentStatus = booking['status'] ?? 'Pending';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          String? selectedStatus = currentStatus;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.chat, color: Colors.green),
                SizedBox(width: 10),
                Text('Send WhatsApp Update'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Send status update to $name ($phone)',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                const Text('Select new status:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ..._statusOptions
                    .where((status) => status != 'All')
                    .map((status) => RadioListTile<String>(
                          title: Text(status),
                          value: status,
                          groupValue: selectedStatus,
                          onChanged: (value) {
                            setState(() => selectedStatus = value);
                          },
                        ))
                    .toList(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: selectedStatus != null
                    ? () async {
                        Navigator.pop(context);

                        // First update status in Firestore
                        await _updateBookingStatus(
                            booking['id'], selectedStatus!);

                        // Then send WhatsApp message
                        await _sendWhatsAppNotification(
                          customerPhone: phone,
                          customerName: name,
                          bookingId: bookingId,
                          oldStatus: currentStatus,
                          newStatus: selectedStatus!,
                        );
                      }
                    : null,
                icon: const Icon(Icons.call, size: 18),
                label: const Text('Call & Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateBookingStatus(String bookingId, String newStatus) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin authentication required'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await _firestore.collection('bookings').doc(bookingId).update({
        'bookingStatus': newStatus,
        'status': newStatus, // ✅ Update both fields for compatibility
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
        'updatedByName': _adminData?['name'] ?? 'Admin',
      });

      // If status is completed, update revenue stats
      if (newStatus == 'Completed') {
        await _updateRevenueStats(bookingId);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking status updated to $newStatus'),
          backgroundColor: _adminPrimaryColor,
        ),
      );

      await _loadBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateRevenueStats(String bookingId) async {
    try {
      DocumentSnapshot bookingSnapshot =
          await _firestore.collection('bookings').doc(bookingId).get();

      if (bookingSnapshot.exists) {
        var bookingData = bookingSnapshot.data() as Map<String, dynamic>;

        // ✅ FIXED: Handle amount safely
        double amount = 0.0;
        dynamic fare = bookingData['totalFare'] ?? bookingData['totalAmount'];
        if (fare != null) {
          if (fare is String) {
            amount = double.tryParse(fare) ?? 0.0;
          } else if (fare is int) {
            amount = fare.toDouble();
          } else if (fare is double) {
            amount = fare;
          }
        }

        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);
        DateTime monthStart = DateTime(now.year, now.month, 1);

        // Update today's revenue
        DocumentReference todayRef = _firestore
            .collection('revenue')
            .doc('daily_${today.millisecondsSinceEpoch}');

        await todayRef.set({
          'date': today,
          'amount': FieldValue.increment(amount),
          'bookingsCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Update monthly revenue
        DocumentReference monthRef = _firestore
            .collection('revenue')
            .doc('monthly_${now.year}_${now.month}');

        await monthRef.set({
          'year': now.year,
          'month': now.month,
          'amount': FieldValue.increment(amount),
          'bookingsCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      return;
    }
  }

  Future<void> _showBookingDetails(Map<String, dynamic> booking) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _adminPrimaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: const Text(
            'Booking Details',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Booking ID', booking['bookingId'] ?? 'N/A'),
              _buildDetailRow('Customer', booking['customerName'] ?? 'N/A'),
              _buildDetailRow('Phone', booking['customerPhone'] ?? 'N/A'),
              _buildDetailRow('Email', booking['customerEmail'] ?? 'N/A'),
              _buildDetailRow('Vehicle', booking['vehicleName'] ?? 'N/A'),
              _buildDetailRow('Pickup', booking['pickupLocation'] ?? 'N/A'),
              _buildDetailRow('Drop', booking['dropLocation'] ?? 'N/A'),
              _buildDetailRow('Date', booking['displayDate'] ?? 'N/A'),
              _buildDetailRow('Time', booking['displayTime'] ?? 'N/A'),
              _buildDetailRow('Duration', booking['hoursDays'] ?? 'N/A'),
              // ✅ FIXED: Use the pre-formatted distance
              _buildDetailRow(
                  'Distance', booking['distanceFormatted'] ?? '0 km'),
              _buildDetailRow('Amount', booking['totalFareFormatted'] ?? '₹0'),
              _buildDetailRow('Payment', booking['paymentStatus'] ?? 'Unpaid'),
              _buildDetailRow('Status', booking['status'] ?? 'Pending'),
              _buildDetailRow(
                  'Booked On', booking['createdAtFormatted'] ?? 'N/A'),
              _buildDetailRow(
                  'Last Updated', booking['updatedAtFormatted'] ?? 'N/A'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.grey[700])),
          ),
          if (booking['status'] != 'Completed' &&
              booking['status'] != 'Cancelled')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showActionOptions(booking);
              },
              child: const Text('Actions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _adminPrimaryColor,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showActionOptions(Map<String, dynamic> booking) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Booking Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _adminPrimaryColor,
                ),
              ),
            ),
            // ✅ WhatsApp Action
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text('Send WhatsApp Update'),
              subtitle: const Text('Send status update via WhatsApp'),
              onTap: () {
                Navigator.pop(context);
                _showWhatsAppDialog(booking);
              },
            ),
            ListTile(
              leading: Icon(Icons.update, color: _adminPrimaryColor),
              title: const Text('Update Status'),
              subtitle: const Text('Change booking status only'),
              onTap: () {
                Navigator.pop(context);
                _showStatusUpdateDialog(booking['id'], booking['status']);
              },
            ),
            ListTile(
              leading: Icon(Icons.receipt, color: _adminPrimaryColor),
              title: const Text('Generate Invoice'),
              subtitle: const Text('Create invoice for this booking'),
              onTap: () {
                Navigator.pop(context);
                _generateInvoice(booking);
              },
            ),
            ListTile(
              leading: Icon(Icons.chat, color: _adminPrimaryColor),
              title: const Text('Contact Customer'),
              subtitle: const Text('Call or message the customer'),
              onTap: () {
                Navigator.pop(context);
                _contactCustomer(booking);
              },
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateInvoice(Map<String, dynamic> booking) async {
    // Implement invoice generation
    // You can integrate with a PDF generation library
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Invoice'),
        content: const Text('Invoice generation feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _contactCustomer(Map<String, dynamic> booking) {
    String phone = booking['customerPhone'] ?? '';
    String name = booking['customerName'] ?? 'Customer';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat, color: Colors.green),
              title: const Text('WhatsApp'),
              subtitle: const Text('Send WhatsApp message'),
              onTap: () {
                Navigator.pop(context);
                _sendWhatsAppNotification(
                  customerPhone: phone,
                  customerName: name,
                  bookingId: booking['bookingId'] ?? '',
                  oldStatus: booking['status'] ?? '',
                  newStatus: booking['status'] ?? '',
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.phone, color: _adminPrimaryColor),
              title: const Text('Call'),
              subtitle: Text(phone.isNotEmpty ? phone : 'No phone available'),
              onTap: () {
                Navigator.pop(context);
                // Implement phone call
                _makePhoneCall(phone);
              },
            ),
            ListTile(
              leading: Icon(Icons.message, color: _adminPrimaryColor),
              title: const Text('Send SMS'),
              subtitle: const Text('Send text message'),
              onTap: () {
                Navigator.pop(context);
                _sendSMS(phone, name, booking['bookingId'] ?? '');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ✅ Phone call function
  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // ✅ SMS function
  Future<void> _sendSMS(
      String phoneNumber, String name, String bookingId) async {
    final url = 'sms:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _showStatusUpdateDialog(
      String bookingId, String? currentStatus) async {
    String? selectedStatus = currentStatus ?? 'Pending';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Update Booking Status',
              style: TextStyle(
                color: _adminPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: _statusOptions
                  .where((status) => status != 'All')
                  .map((status) => RadioListTile<String>(
                        title: Text(status),
                        value: status,
                        groupValue: selectedStatus,
                        onChanged: (value) {
                          setState(() => selectedStatus = value);
                        },
                      ))
                  .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    Text('Cancel', style: TextStyle(color: Colors.grey[700])),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (selectedStatus != null) {
                    Navigator.pop(context);
                    _updateBookingStatus(bookingId, selectedStatus!);
                  }
                },
                icon: const Icon(Icons.update, size: 18),
                label: const Text('Update Only'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _adminPrimaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  if (selectedStatus != null) {
                    Navigator.pop(context);
                    // Get booking data first, then send WhatsApp
                    var booking = _bookings.firstWhere(
                      (b) => b['id'] == bookingId,
                      orElse: () => {},
                    );

                    if (booking.isNotEmpty) {
                      _updateBookingStatus(bookingId, selectedStatus!)
                          .then((_) {
                        _sendWhatsAppNotification(
                          customerPhone: booking['customerPhone'] ?? '',
                          customerName: booking['customerName'] ?? 'Customer',
                          bookingId: booking['bookingId'] ?? '',
                          oldStatus: currentStatus ?? 'Pending',
                          newStatus: selectedStatus!,
                        );
                      });
                    }
                  }
                },
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('Update & WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: _adminPrimaryColor,
            colorScheme: ColorScheme.light(primary: _adminPrimaryColor),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _adminBackground,
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar with Refresh Button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search bookings...',
                          prefixIcon:
                              Icon(Icons.search, color: _adminPrimaryColor),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: Colors.grey[600]),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _applyFilters();
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: _adminPrimaryColor, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: _adminPrimaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _loadBookings,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Refresh',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Filters Row
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_drop_down,
                                color: _adminPrimaryColor),
                            items: _statusOptions.map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(
                                  status,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value!;
                                _applyFilters();
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => _pickDate(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today,
                                size: 20, color: _adminPrimaryColor),
                            const SizedBox(width: 8),
                            Text(
                              _selectedDate == null
                                  ? 'All Dates'
                                  : DateFormat('dd MMM yyyy')
                                      .format(_selectedDate!),
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            if (_selectedDate != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedDate = null;
                                      _applyFilters();
                                    });
                                  },
                                  child: Icon(Icons.clear,
                                      size: 16, color: Colors.grey[500]),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats Summary
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: _adminPrimaryColor.withOpacity(0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                    'Total', '${_bookings.length}', _adminPrimaryColor),
                _buildStatItem(
                    'Pending',
                    '${_bookings.where((b) => (b['status'] ?? 'Pending') == 'Pending').length}',
                    Colors.orange),
                _buildStatItem(
                    'Confirmed',
                    '${_bookings.where((b) => (b['status'] ?? '') == 'Confirmed').length}',
                    const Color(0xFF00B14F)),
                _buildStatItem(
                    'Revenue',
                    _formatCurrency(_bookings
                        .where((b) => (b['status'] ?? '') == 'Completed')
                        .fold(0.0, (sum, b) {
                      // ✅ FIXED: Handle amount safely
                      dynamic fare = b['totalFare'] ?? b['totalAmount'];
                      double amount = 0.0;
                      if (fare != null) {
                        if (fare is String) {
                          amount = double.tryParse(fare) ?? 0.0;
                        } else if (fare is int) {
                          amount = fare.toDouble();
                        } else if (fare is double) {
                          amount = fare;
                        }
                      }
                      return sum + amount;
                    })),
                    const Color(0xFF00B14F)),
              ],
            ),
          ),

          // Bookings List
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: _adminPrimaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading bookings...',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredBookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No bookings found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_searchQuery.isNotEmpty ||
                                _selectedStatus != 'All' ||
                                _selectedDate != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedStatus = 'All';
                                    _selectedDate = null;
                                    _applyFilters();
                                  });
                                },
                                child: Text(
                                  'Clear filters',
                                  style: TextStyle(color: _adminPrimaryColor),
                                ),
                              ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        color: _adminPrimaryColor,
                        backgroundColor: _adminBackground,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _filteredBookings.length,
                          itemBuilder: (context, index) {
                            var booking = _filteredBookings[index];
                            return _buildBookingCard(booking);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    String status = booking['status'] ?? 'Pending';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: _adminCardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      size: 16,
                      color: _getStatusColor(status),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking['customerName'] ?? 'N/A',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking['bookingId'] ?? 'N/A',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        booking['totalFareFormatted'] ?? '₹0',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _adminPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Divider(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 12),

              // Booking Details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailItem(Icons.directions_car,
                            booking['vehicleName'] ?? 'N/A'),
                        const SizedBox(height: 8),
                        _buildDetailItem(
                            Icons.location_pin,
                            '${booking['pickupLocation']?.toString().split(',')[0] ?? 'N/A'}'
                                .replaceAll('null', '')
                                .trim()),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailItem(
                            Icons.date_range, booking['displayDate'] ?? 'N/A'),
                        const SizedBox(height: 8),
                        _buildDetailItem(Icons.access_time,
                            '${booking['displayTime'] ?? 'N/A'} • ${booking['distanceFormatted'] ?? '0 km'}'),
                      ],
                    ),
                  ),
                ],
              ),

             const SizedBox(height: 12),

              // Action Buttons
              if (status != 'Completed' && status != 'Cancelled')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showWhatsAppDialog(booking),
                        icon:const Icon(Icons.chat, size: 14, color: Colors.white),
                        label:const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                   const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _showStatusUpdateDialog(booking['id'], status),
                        icon:const Icon(Icons.update, size: 14),
                        label:const Text('Update Status'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _adminPrimaryColor,
                          side: BorderSide(color: _adminPrimaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _showBookingDetails(booking),
                      icon:
                        const Icon(Icons.visibility, size: 18, color: Colors.blue),
                      tooltip: 'View Details',
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _adminPrimaryColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
