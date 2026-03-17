// lib/screens/admin/admin_booking_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';

class AdminBookingScreen extends StatefulWidget {
  const AdminBookingScreen({super.key});

  @override
  State<AdminBookingScreen> createState() => _AdminBookingScreenState();
}

class _AdminBookingScreenState extends State<AdminBookingScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ---------- Static variables ----------
  static String? _cachedUserId;
  static bool _isAdminVerified = false;
  static bool _isCheckingAdmin = false;
  static List<Map<String, dynamic>>? _cachedBookings;
  static DateTime? _lastLoadTime;
  static bool _isRedirecting = false;
  static bool _isInitialized = false;
  static int _loadAttempts = 0;

  // ---------- Instance variables ----------
  bool _isLoading = true;
  bool _isDataLoading = true;
  bool _hasLoadError = false;
  String _errorMessage = '';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _filteredBookings = [];

  String _searchQuery = '';
  String _selectedStatus = 'All';
  DateTime? _selectedDate;
  Map<String, dynamic>? _adminData;

  final String _googleMapsApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  final String _companyGSTIN = "33DJJPS1207L1";
  final String _companyName = "S.S.A AGENCY";
  final String _companyAddress = "Virudhunagar";
  final String _companyPhone = "+91 63740 49582";

  final Color _adminPrimaryColor = const Color(0xFF00C853);
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

  final String _sacCode = "9966";
  int _invoiceCounter = 0;

  // ---------- Auth state listener ----------
  late Stream<User?> _authStateChanges;
  late StreamSubscription<User?> _authSubscription;
  Timer? _sessionCheckTimer;

  @override
  void initState() {
    super.initState();

    print('🟢 AdminBookingScreen - initState');

    _setupAuthListener();
    WidgetsBinding.instance.addObserver(this);
    _startSessionCheckTimer();

    Future.microtask(() {
      _initializeScreen();
    });
  }

  void _setupAuthListener() {
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (!mounted) return;

      if (user == null) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && FirebaseAuth.instance.currentUser == null) {
            _redirectToLogin();
          }
        });
      }
    });
  }

  void _startSessionCheckTimer() {
    _sessionCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _checkSessionQuietly();
      }
    });
  }

  Future<void> _checkSessionQuietly() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        // wait and re-check to avoid temporary logout
        await Future.delayed(const Duration(seconds: 2));

        if (FirebaseAuth.instance.currentUser == null &&
            mounted &&
            !_isRedirecting) {
          print("⚠️ User really logged out");
          _handleLogout();
        }

        return;
      }

      // Check token silently
      await user.getIdToken(false);
    } catch (e) {
      print('⚠️ Session check error: $e');
    }
  }

  void _handleLogout() {
    if (_isRedirecting) return;

    if (FirebaseAuth.instance.currentUser != null) {
      return; // avoid false logout
    }

    print("🔴 Logging out user");

    _redirectToLogin();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSessionQuietly();
    }
  }

  @override
  void dispose() {
    print('🔴 AdminBookingScreen - dispose');
    _authSubscription.cancel();
    _sessionCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _redirectToLogin() {
    if (!mounted || _isRedirecting) return;

    _isRedirecting = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login').then((_) {
          _isRedirecting = false;
        }).catchError((_) {
          _isRedirecting = false;
        });
      } else {
        _isRedirecting = false;
      }
    });
  }

  Future<void> _initializeScreen() async {
    print('🟢 _initializeScreen started');

    if (_isInitialized && _isAdminVerified) {
      print('✅ Already initialized and verified');
      return;
    }

    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      print('⚠️ User null, rechecking...');

      await Future.delayed(const Duration(seconds: 2));

      currentUser = _auth.currentUser;

      if (currentUser == null) {
        print('❌ User really logged out');
        _redirectToLogin();
        return;
      }
    }

    await _checkAdminAccess();

    if (_isAdminVerified && mounted) {
      try {
        await Future.wait([
          _loadAdminData(),
          _loadBookings(),
          _loadInvoiceCounter(),
        ]);

        if (mounted) {
          setState(() {
            _isInitialized = true;
            _hasLoadError = false;
          });
        }
        print('✅ Screen initialized successfully');
      } catch (e) {
        print('❌ Error during initialization: $e');
        setState(() {
          _hasLoadError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant AdminBookingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_isInitialized && _isAdminVerified) {
      _checkSessionQuietly();
    }
  }

  Future<void> _checkAdminAccess() async {
    if (_isCheckingAdmin) return;

    setState(() {
      _isCheckingAdmin = true;
      _isLoading = true;
    });

    User? user = _auth.currentUser;
    if (user == null) {
      _redirectToLogin();
      return;
    }

    bool isAdmin = false;
    try {
      // Check by UID
      DocumentSnapshot adminDoc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));

      if (adminDoc.exists) {
        isAdmin = true;
        print('✅ Admin verified by UID');
      }

      // Check by phone number
      if (!isAdmin && user.phoneNumber != null) {
        String phone = user.phoneNumber!.replaceAll('+91', '').trim();
        DocumentSnapshot phoneDoc =
            await _firestore.collection('admins').doc('admin_$phone').get();
        if (phoneDoc.exists) {
          isAdmin = true;
          print('✅ Admin verified by phone: $phone');
        }
      }

      // Check in users collection
      if (!isAdmin) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        var data = userDoc.data() as Map<String, dynamic>?;
        if (data != null && data['isAdmin'] == true) {
          isAdmin = true;
          print('✅ Admin verified in users collection');
        }
      }

      if (!isAdmin) {
        throw Exception('Admin access required');
      }

      setState(() {
        _cachedUserId = user.uid;
        _isAdminVerified = true;
        _isLoading = false;
        _isCheckingAdmin = false;
      });
    } catch (e) {
      print('❌ Admin check failed: $e');
      setState(() {
        _isLoading = false;
        _isCheckingAdmin = false;
        _hasLoadError = true;
        _errorMessage = e.toString();
      });

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Access Denied'),
          content:
              Text('You need admin privileges to access this page.\nError: $e'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _auth.signOut();
                _redirectToLogin();
              },
              child: const Text('Logout'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/user-home');
              },
              child: const Text('Go to User Home'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _checkAdminAccess();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _loadBookings({bool forceRefresh = false}) async {
    if (!mounted || !_isAdminVerified) {
      print('⚠️ Cannot load bookings - not verified');
      return;
    }

    _loadAttempts++;

    // Cached data check
    if (!forceRefresh && _cachedBookings != null && _lastLoadTime != null) {
      final now = DateTime.now();
      final diff = now.difference(_lastLoadTime!);

      if (diff.inMinutes < 5) {
        print('✅ Using cached bookings (${diff.inMinutes} min old)');
        if (mounted) {
          setState(() {
            _bookings = List.from(_cachedBookings!);
            _filteredBookings = List.from(_cachedBookings!);
            _isDataLoading = false;
            _hasLoadError = false;
          });
        }
        return;
      }
    }

    try {
      setState(() {
        _isDataLoading = true;
        _hasLoadError = false;
      });

      print('🟢 Loading bookings from Firestore...');

      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 30)); // Increased timeout

      List<Map<String, dynamic>> bookings = [];

      for (var doc in snapshot.docs) {
        try {
          var data = doc.data() as Map<String, dynamic>;

          String hoursDays = await _calculateDuration(data);
          String vehicleName = await _getVehicleName(data);
          String status = data['bookingStatus'] ?? data['status'] ?? 'Pending';
          String distanceFormatted = _formatDistance(data['distance']);
          String bookedOn = _formatDateTime(data['createdAt']);
          String updatedOn = _formatDateTime(data['updatedAt']);

          String userId =
              data['userid'] ?? data['userId'] ?? data['customerId'] ?? '';

          bookings.add({
            'id': doc.id,
            ...data,
            'userId': userId,
            'displayDate': _formatDisplayDate(data),
            'displayTime': data['formattedTime'] ?? data['pickupTime'] ?? 'N/A',
            'hoursDays': hoursDays,
            'totalFareFormatted':
                _formatCurrency(data['totalFare'] ?? data['totalAmount'] ?? 0),
            'vehicleName': vehicleName,
            'status': status,
            'bookingStatus': status,
            'paymentStatus': data['paymentStatus'] ?? 'Unpaid',
            'createdAtFormatted': bookedOn,
            'updatedAtFormatted': updatedOn,
            'distanceFormatted': distanceFormatted,
            'pickupLocation':
                data['pickupLocation']?.toString().trim() ?? 'Not specified',
            'dropLocation':
                data['dropLocation']?.toString().trim() ?? 'Not specified',
            'pickupCoordinates': data['pickupCoordinates'],
            'dropCoordinates': data['dropCoordinates'],
          });
        } catch (e) {
          print('⚠️ Error processing booking ${doc.id}: $e');
          continue;
        }
      }

      if (!mounted) return;

      _cachedBookings = List.from(bookings);
      _lastLoadTime = DateTime.now();
      _loadAttempts = 0;

      setState(() {
        _bookings = bookings;
        _filteredBookings = bookings;
        _isDataLoading = false;
        _hasLoadError = false;
      });

      print('✅ Loaded ${bookings.length} bookings successfully');
    } catch (e) {
      print('❌ Error loading bookings: $e');

      if (!mounted) return;

      // Show error but keep cached data if available
      if (_cachedBookings != null && mounted) {
        setState(() {
          _bookings = List.from(_cachedBookings!);
          _filteredBookings = List.from(_cachedBookings!);
          _isDataLoading = false;
          _hasLoadError = true;
          _errorMessage = e.toString();
        });

        _showSnackBar('⚠️ Using cached data. Network error: ${e.toString()}',
            Colors.orange);
      } else {
        setState(() {
          _isDataLoading = false;
          _hasLoadError = true;
          _errorMessage = e.toString();
        });

        _showSnackBar('❌ Error loading bookings: ${e.toString()}', Colors.red);
      }

      // Don't logout on error, just show retry option
      if (_loadAttempts < 3) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _hasLoadError) {
            _loadBookings(forceRefresh: true);
          }
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<String> _calculateDuration(Map<String, dynamic> data) async {
    if (data['isPackageTrip'] == true && data['packageHours'] != null) {
      return '${data['packageHours']} hours';
    } else if (data['distance'] != null) {
      try {
        double distance = double.tryParse(data['distance'].toString()) ?? 0.0;
        if (distance > 200) {
          int days = (distance / 400).ceil();
          return '$days days';
        } else {
          return '1 day';
        }
      } catch (e) {
        return '1 day';
      }
    }
    return '1 day';
  }

  Future<String> _getVehicleName(Map<String, dynamic> data) async {
    String vehicleName = data['vehicleType'] ?? 'N/A';
    if (data['vehicleId'] != null) {
      try {
        DocumentSnapshot vehicleSnapshot = await _firestore
            .collection('vehicles')
            .doc(data['vehicleId'])
            .get()
            .timeout(const Duration(seconds: 5));
        if (vehicleSnapshot.exists) {
          var vehicleData = vehicleSnapshot.data() as Map<String, dynamic>;
          vehicleName = vehicleData['name'] ?? vehicleName;
        }
      } catch (e) {
        print('Error getting vehicle name: $e');
      }
    }
    return vehicleName;
  }

  String _formatDistance(dynamic distance) {
    if (distance == null) return '0 km';
    try {
      double dist = double.tryParse(distance.toString()) ?? 0.0;
      return '${dist.toStringAsFixed(1)} km';
    } catch (e) {
      return '0 km';
    }
  }

  String _formatDisplayDate(Map<String, dynamic> data) {
    if (data['formattedDate'] != null) {
      return data['formattedDate'];
    }
    if (data['pickupDate'] != null) {
      return data['pickupDate'];
    }
    return _formatDate(data['createdAt']);
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _bookings;

    if (_selectedStatus != 'All') {
      filtered = filtered.where((booking) {
        String status = booking['status']?.toLowerCase() ?? '';
        return status == _selectedStatus.toLowerCase();
      }).toList();
    }

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

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((booking) {
        return (booking['customerName'] ?? '')
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            (booking['bookingId'] ?? '')
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

  String _formatDateTime(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate());
  }

  String _formatCurrency(dynamic amount) {
    try {
      if (amount == null) return '₹0';

      double value;
      if (amount is String) {
        String cleanAmount = amount.replaceAll('₹', '').replaceAll(',', '');
        value = double.tryParse(cleanAmount) ?? 0.0;
      } else if (amount is int) {
        value = amount.toDouble();
      } else if (amount is double) {
        value = amount;
      } else {
        value = 0.0;
      }

      NumberFormat format = NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      );
      return format.format(value);
    } catch (e) {
      return '₹0';
    }
  }

  Future<void> _loadInvoiceCounter() async {
    if (!mounted || !_isAdminVerified) return;

    try {
      DocumentSnapshot counterDoc = await _firestore
          .collection('settings')
          .doc('invoiceCounter')
          .get()
          .timeout(const Duration(seconds: 10));

      if (counterDoc.exists && mounted) {
        setState(() {
          _invoiceCounter = counterDoc['count'] ?? 0;
        });
      } else {
        await _firestore.collection('settings').doc('invoiceCounter').set({
          'count': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error loading invoice counter: $e');
    }
  }

  Future<String> _getNextInvoiceNumber() async {
    try {
      final settingsRef =
          _firestore.collection('settings').doc('invoiceCounter');

      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(settingsRef);

        int currentCount = snapshot.exists ? (snapshot['count'] ?? 0) : 0;
        int nextCount = currentCount + 1;

        transaction.set(
            settingsRef,
            {
              'count': nextCount,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));

        String year = DateFormat('yyyy').format(DateTime.now());
        String number = nextCount.toString().padLeft(3, '0');

        return 'SSA/$year/$number';
      });
    } catch (e) {
      String year = DateFormat('yyyy').format(DateTime.now());
      _invoiceCounter++;
      return 'SSA/$year/${_invoiceCounter.toString().padLeft(3, '0')}';
    }
  }

  Future<void> _loadAdminData() async {
    if (!mounted || !_isAdminVerified) return;

    try {
      User? user = _auth.currentUser;
      if (user != null && mounted) {
        DocumentSnapshot adminSnapshot = await _firestore
            .collection('admins')
            .doc(user.uid)
            .get()
            .timeout(const Duration(seconds: 10));

        if (adminSnapshot.exists && mounted) {
          setState(() {
            _adminData = adminSnapshot.data() as Map<String, dynamic>;
          });
        } else if (mounted) {
          await _firestore.collection('admins').doc(user.uid).set({
            'name': user.displayName ?? 'Admin',
            'email': user.email,
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
          });

          if (mounted) {
            setState(() {
              _adminData = {
                'name': user.displayName ?? 'Admin',
                'email': user.email,
              };
            });
          }
        }
      }
    } catch (e) {
      print('Error loading admin data: $e');
    }
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return const Color(0xFF00B14F);
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    if (status == null) return Icons.help_outline;
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'pending':
        return Icons.hourglass_empty;
      case 'processing':
        return Icons.refresh;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  bool _isCoordinate(String text) {
    final regex = RegExp(r'^-?\d+\.?\d*,\s*-?\d+\.?\d*$');
    return regex.hasMatch(text.replaceAll(' ', ''));
  }

  LatLng? _parseCoordinate(String text) {
    try {
      List<String> parts = text.replaceAll(' ', '').split(',');
      if (parts.length == 2) {
        double lat = double.parse(parts[0]);
        double lng = double.parse(parts[1]);
        return LatLng(lat, lng);
      }
    } catch (e) {
      print('Error parsing coordinate: $e');
    }
    return null;
  }

  Future<Map<String, LatLng?>> _getCoordinatesForRoute(
      String pickup, String drop) async {
    try {
      LatLng? pickupLatLng;
      LatLng? dropLatLng;

      if (_isCoordinate(pickup)) {
        pickupLatLng = _parseCoordinate(pickup);
      } else {
        String cleanPickup = pickup.replaceAll('Not specified', '').trim();
        if (cleanPickup.isNotEmpty) {
          List<Location> locations = await locationFromAddress(cleanPickup);
          if (locations.isNotEmpty) {
            pickupLatLng = LatLng(
              locations.first.latitude,
              locations.first.longitude,
            );
          }
        }
      }

      if (_isCoordinate(drop)) {
        dropLatLng = _parseCoordinate(drop);
      } else {
        String cleanDrop = drop.replaceAll('Not specified', '').trim();
        if (cleanDrop.isNotEmpty) {
          List<Location> locations = await locationFromAddress(cleanDrop);
          if (locations.isNotEmpty) {
            dropLatLng = LatLng(
              locations.first.latitude,
              locations.first.longitude,
            );
          }
        }
      }

      return {
        'pickup': pickupLatLng,
        'drop': dropLatLng,
      };
    } catch (e) {
      print('Error getting coordinates: $e');
      return {'pickup': null, 'drop': null};
    }
  }

  Future<List<LatLng>> _getRoutePolyline(
      LatLng origin, LatLng destination) async {
    List<LatLng> polylinePoints = [];

    if (_googleMapsApiKey.isEmpty) {
      return [origin, destination];
    }

    try {
      final String url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$_googleMapsApiKey';

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;
          if (routes.isNotEmpty) {
            final legs = routes[0]['legs'] as List;
            if (legs.isNotEmpty) {
              final steps = legs[0]['steps'] as List;

              for (var step in steps) {
                final polyline = step['polyline']['points'];
                polylinePoints.addAll(_decodePolyline(polyline));
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error getting route polyline: $e');
    }

    if (polylinePoints.isEmpty) {
      polylinePoints = [origin, destination];
    }

    return polylinePoints;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  Widget _buildLocationPreview(String pickup, String drop, bool hasError) {
    String displayPickup = _isCoordinate(pickup) ? 'Selected Location' : pickup;
    String displayDrop = _isCoordinate(drop) ? 'Selected Location' : drop;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasError ? Icons.error_outline : Icons.map,
              size: 64,
              color: hasError ? Colors.red : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              hasError ? 'Error loading map' : 'Coordinates not available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: hasError ? Colors.red : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasError
                  ? 'Unable to fetch location coordinates'
                  : 'Click below to open in Google Maps',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pickup: $displayPickup',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Drop: $displayDrop',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openInGoogleMaps(pickup, drop),
              icon: const Icon(Icons.map),
              label: const Text('Open in Google Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _adminPrimaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRouteMap(Map<String, dynamic> booking) async {
    String pickup = booking['pickupLocation'] ?? '';
    String drop = booking['dropLocation'] ?? '';
    String bookingId = booking['bookingId'] ?? '';

    if (pickup.isEmpty ||
        drop.isEmpty ||
        pickup == 'Not specified' ||
        drop == 'Not specified') {
      _showSnackBar('Pickup or Drop location not available', Colors.orange);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _adminPrimaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.map, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Route Map - ${bookingId.length > 8 ? bookingId.substring(0, 8) : bookingId}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<Map<String, LatLng?>>(
                  future: _getCoordinatesForRoute(pickup, drop),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading map...'),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildLocationPreview(pickup, drop, true);
                    }

                    final coordinates = snapshot.data ?? {};
                    final pickupLatLng = coordinates['pickup'];
                    final dropLatLng = coordinates['drop'];

                    if (pickupLatLng == null || dropLatLng == null) {
                      return _buildLocationPreview(pickup, drop, false);
                    }

                    return FutureBuilder<List<LatLng>>(
                      future: _getRoutePolyline(pickupLatLng, dropLatLng),
                      builder: (context, routeSnapshot) {
                        if (routeSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Loading route...'),
                              ],
                            ),
                          );
                        }

                        final routePoints =
                            routeSnapshot.data ?? [pickupLatLng, dropLatLng];
                        final bool hasRealRoute = routePoints.length > 2;

                        return Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: pickupLatLng,
                                zoom: 10,
                              ),
                              markers: {
                                Marker(
                                  markerId: const MarkerId('pickup'),
                                  position: pickupLatLng,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueGreen,
                                  ),
                                  infoWindow: InfoWindow(
                                    title: 'Pickup Location',
                                    snippet: _truncateString(pickup, 30),
                                  ),
                                ),
                                Marker(
                                  markerId: const MarkerId('drop'),
                                  position: dropLatLng,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueRed,
                                  ),
                                  infoWindow: InfoWindow(
                                    title: 'Drop Location',
                                    snippet: _truncateString(drop, 30),
                                  ),
                                ),
                              },
                              polylines: {
                                Polyline(
                                  polylineId: PolylineId(
                                    hasRealRoute
                                        ? 'real_route'
                                        : 'direct_route',
                                  ),
                                  points: routePoints,
                                  color:
                                      hasRealRoute ? Colors.blue : Colors.grey,
                                  width: hasRealRoute ? 5 : 3,
                                ),
                              },
                              zoomControlsEnabled: true,
                              myLocationButtonEnabled: false,
                              compassEnabled: true,
                              mapToolbarEnabled: true,
                            ),
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: FloatingActionButton.small(
                                onPressed: () =>
                                    _openInGoogleMaps(pickup, drop),
                                backgroundColor: _adminPrimaryColor,
                                child: const Icon(Icons.directions,
                                    color: Colors.white),
                              ),
                            ),
                            if (!hasRealRoute)
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Direct Route (No API)',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pickup: ${_truncateString(pickup, 40)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Drop: ${_truncateString(drop, 40)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _truncateString(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Future<void> _openInGoogleMaps(String pickup, String drop) async {
    String origin;
    String destination;

    if (_isCoordinate(pickup)) {
      LatLng? coord = _parseCoordinate(pickup);
      if (coord != null) {
        origin = '${coord.latitude},${coord.longitude}';
      } else {
        origin = Uri.encodeComponent(pickup);
      }
    } else {
      origin = Uri.encodeComponent(pickup);
    }

    if (_isCoordinate(drop)) {
      LatLng? coord = _parseCoordinate(drop);
      if (coord != null) {
        destination = '${coord.latitude},${coord.longitude}';
      } else {
        destination = Uri.encodeComponent(drop);
      }
    } else {
      destination = Uri.encodeComponent(drop);
    }

    final String url =
        'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination';

    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackBar('Could not open Google Maps', Colors.red);
    }
  }

  Future<void> _sendWhatsAppNotification({
    required String customerPhone,
    required String customerName,
    required String bookingId,
    required String oldStatus,
    required String newStatus,
  }) async {
    try {
      String cleanPhone = customerPhone
          .replaceAll('+91', '')
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .replaceAll('(', '')
          .replaceAll(')', '')
          .trim();

      if (cleanPhone.length == 10) {
        cleanPhone = '91$cleanPhone';
      } else if (cleanPhone.startsWith('0')) {
        cleanPhone = '91${cleanPhone.substring(1)}';
      }

      String message = '''
Hi $customerName,

Your booking status has been updated!

📋 *Booking ID:* ${bookingId.length > 8 ? bookingId.substring(0, 8) : bookingId}
🔄 *Old Status:* $oldStatus
✅ *New Status:* $newStatus

Thank you for choosing SSA Travels!
For any queries, contact us: +91 6374049582

Best regards,
SSA Travels Virudhunagar
      '''
          .trim();

      String encodedMessage = Uri.encodeComponent(message);
      String whatsappUrl = 'https://wa.me/$cleanPhone?text=$encodedMessage';
      final Uri uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      _showSnackBar('Error opening WhatsApp: ${e.toString()}', Colors.red);
    }
  }

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
                  'Send status update to $name',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  phone,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text('Select new status:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: SingleChildScrollView(
                    child: Column(
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
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed:
                    selectedStatus != null && selectedStatus != currentStatus
                        ? () async {
                            Navigator.pop(context);
                            await _updateBookingStatus(
                                booking['id'], selectedStatus!);
                            await _sendWhatsAppNotification(
                              customerPhone: phone,
                              customerName: name,
                              bookingId: bookingId,
                              oldStatus: currentStatus,
                              newStatus: selectedStatus!,
                            );
                          }
                        : null,
                icon: const Icon(Icons.send, size: 18),
                label: const Text('Send Update'),
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
        _showSnackBar('Admin authentication required', Colors.red);
        return;
      }

      if (!_isAdminVerified) {
        _showSnackBar('Admin privileges required', Colors.red);
        return;
      }

      DocumentSnapshot bookingSnapshot = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (!bookingSnapshot.exists) {
        _showSnackBar('Booking not found', Colors.red);
        return;
      }

      var bookingData = bookingSnapshot.data() as Map<String, dynamic>;
      String userId = bookingData['userid'] ??
          bookingData['userId'] ??
          bookingData['customerId'] ??
          '';

      await _firestore.collection('bookings').doc(bookingId).update({
        'bookingStatus': newStatus,
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user.uid,
        'updatedByName': _adminData?['name'] ?? 'Admin',
      });

      if (userId.isNotEmpty) {
        QuerySnapshot rideSnapshot = await _firestore
            .collection('rides')
            .where('bookingId', isEqualTo: bookingId)
            .limit(1)
            .get();

        if (rideSnapshot.docs.isNotEmpty) {
          await rideSnapshot.docs.first.reference.update({
            'status': newStatus.toLowerCase(),
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': user.uid,
          });
        } else {
          await _firestore.collection('rides').add({
            'userid': userId,
            'bookingId': bookingId,
            'status': newStatus.toLowerCase(),
            'createdAt':
                bookingData['createdAt'] ?? FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
            'pickupAddress': bookingData['pickupLocation'] ?? '',
            'destinationAddress': bookingData['dropLocation'] ?? '',
            'fare': bookingData['totalFare'] ?? bookingData['totalAmount'] ?? 0,
            'vehicleType': bookingData['vehicleType'] ?? 'Standard',
            'rideId': bookingData['bookingId'] ?? bookingId,
          });
        }
      }

      if (newStatus == 'Completed') {
        await _updateRevenueStats(bookingId);
      }

      await _loadBookings(forceRefresh: true);
      _showSnackBar('Booking status updated to $newStatus', _adminPrimaryColor);
    } catch (e) {
      print('Error updating status: $e');
      _showSnackBar('Error updating status: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _updateRevenueStats(String bookingId) async {
    try {
      DocumentSnapshot bookingSnapshot = await _firestore
          .collection('bookings')
          .doc(bookingId)
          .get()
          .timeout(const Duration(seconds: 10));

      if (bookingSnapshot.exists) {
        var bookingData = bookingSnapshot.data() as Map<String, dynamic>;

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

        DocumentReference todayRef = _firestore
            .collection('revenue')
            .doc('daily_${today.millisecondsSinceEpoch}');

        await todayRef.set({
          'date': today,
          'amount': FieldValue.increment(amount),
          'bookingsCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

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
      print('Error updating revenue: $e');
    }
  }

  Map<String, double> _calculateGST(double amount) {
    double cgst = amount * 0.025;
    double sgst = amount * 0.025;
    double totalGST = cgst + sgst;
    double totalWithGST = amount + totalGST;

    return {
      'cgst': cgst,
      'sgst': sgst,
      'totalGST': totalGST,
      'totalWithGST': totalWithGST,
    };
  }

  Future<void> _showBookingDetails(Map<String, dynamic> booking) async {
    // ... (keep your existing _showBookingDetails method)
  }

  Future<File?> _generatePDFBill(
      Map<String, dynamic> booking, String invoiceNumber) async {
    if (kIsWeb) {
      _showSnackBar('PDF generation is not available on web', Colors.orange);
      return null;
    }

    try {
      double baseAmount = 0;
      try {
        String amountStr = booking['totalFareFormatted'] ?? '₹0';
        String cleanAmount = amountStr.replaceAll('₹', '').replaceAll(',', '');
        baseAmount = double.parse(cleanAmount);
      } catch (e) {
        baseAmount = 0;
      }

      Map<String, double> gstDetails = _calculateGST(baseAmount);

      String baseFormatted = '₹${_formatNumber(baseAmount)}';
      String cgstFormatted = '₹${_formatNumber(gstDetails['cgst']!)}';
      String sgstFormatted = '₹${_formatNumber(gstDetails['sgst']!)}';
      String totalGSTFormatted = '₹${_formatNumber(gstDetails['totalGST']!)}';
      String totalWithGSTFormatted =
          '₹${_formatNumber(gstDetails['totalWithGST']!)}';

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Column(
                  children: [
                    pw.Text(
                      _companyName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      _companyAddress,
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      _companyPhone,
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'GSTIN: $_companyGSTIN',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    pw.Container(
                      height: 1,
                      color: PdfColors.grey300,
                    ),
                    pw.SizedBox(height: 16),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'TAX INVOICE',
                              style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'Invoice No: $invoiceNumber',
                              style: pw.TextStyle(fontSize: 12),
                            ),
                            pw.Text(
                              'Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                              style: pw.TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Bill To:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text('Name: ${booking['customerName'] ?? 'N/A'}'),
                    pw.Text('Phone: ${booking['customerPhone'] ?? 'N/A'}'),
                    if (booking['customerEmail'] != null)
                      pw.Text('Email: ${booking['customerEmail']}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(4),
                          topRight: pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Expanded(
                            flex: 3,
                            child: pw.Text(
                              'Description',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              'SAC Code',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              'Amount',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      child: pw.Column(
                        children: [
                          pw.Row(
                            children: [
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  'Car Rental – ${booking['pickupLocation']?.toString().split(',').first ?? 'N/A'} to ${booking['dropLocation']?.toString().split(',').first ?? 'N/A'}',
                                  style: pw.TextStyle(fontSize: 11),
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  _sacCode,
                                  style: pw.TextStyle(fontSize: 11),
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  baseFormatted,
                                  textAlign: pw.TextAlign.right,
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            children: [
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  'Vehicle: ${booking['vehicleName'] ?? 'N/A'}',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(''),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  booking['hoursDays'] ?? '1 day',
                                  textAlign: pw.TextAlign.right,
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          pw.Row(
                            children: [
                              pw.Expanded(
                                flex: 3,
                                child: pw.Text(
                                  'Distance: ${booking['distanceFormatted'] ?? '0 km'}',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(''),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Base Amount:',
                            style: pw.TextStyle(fontSize: 12)),
                        pw.Text(baseFormatted,
                            style: pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('CGST (2.5%):',
                            style: pw.TextStyle(
                                fontSize: 12, color: PdfColors.blue700)),
                        pw.Text(cgstFormatted,
                            style: pw.TextStyle(
                                fontSize: 12, color: PdfColors.blue700)),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('SGST (2.5%):',
                            style: pw.TextStyle(
                                fontSize: 12, color: PdfColors.green700)),
                        pw.Text(sgstFormatted,
                            style: pw.TextStyle(
                                fontSize: 12, color: PdfColors.green700)),
                      ],
                    ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Total GST (5%):',
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(totalGSTFormatted,
                            style:
                                pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green700, width: 1),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'GRAND TOTAL',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        pw.Text(
                          totalWithGSTFormatted,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 18,
                            color: PdfColors.green700,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '(Inclusive of GST)',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey50,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Declaration:',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'We declare that this invoice shows the actual price of the services described.',
                      style: pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'For $_companyName',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Authorized Signature',
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 16),
                    pw.Divider(),
                    pw.SizedBox(height: 4),
                    pw.Center(
                      child: pw.Text(
                        'This is a computer generated invoice',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Center(
                child: pw.Text(
                  'Thank you for choosing SSA Travels!',
                  style: pw.TextStyle(
                    color: PdfColors.green700,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ];
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/SSA_Bill_${booking['bookingId']}.pdf');
      await file.writeAsBytes(await pdf.save());

      return file;
    } catch (e) {
      print('Error generating PDF: $e');
      return null;
    }
  }

  String _formatNumber(double number) {
    NumberFormat format = NumberFormat('#,##,###', 'en_IN');
    return format.format(number.round());
  }

  Future<void> _sendPDFViaWhatsApp(File pdfFile, String phoneNumber) async {
    try {
      String cleanPhone = phoneNumber
          .replaceAll('+91', '')
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .replaceAll('(', '')
          .replaceAll(')', '')
          .trim();

      if (cleanPhone.length == 10) {
        cleanPhone = '91$cleanPhone';
      } else if (cleanPhone.startsWith('0')) {
        cleanPhone = '91${cleanPhone.substring(1)}';
      }

      final xFile = XFile(pdfFile.path);
      await Share.shareXFiles(
        [xFile],
        text: 'Here is your invoice from SSA Travels',
      );

      String message = '''
Hi, 

Your invoice from SSA Travels is attached below.

Thank you for choosing SSA Travels!
For any queries, contact us: +91 63740 49582
      '''
          .trim();

      String encodedMessage = Uri.encodeComponent(message);
      String whatsappUrl = 'https://wa.me/$cleanPhone?text=$encodedMessage';
      final Uri uri = Uri.parse(whatsappUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error sending PDF: $e');
      _showSnackBar('Error sending PDF: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _showGenerateBillDialog(Map<String, dynamic> booking) async {
    // ... (keep your existing _showGenerateBillDialog method)
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: _adminPrimaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
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
            ListTile(
              leading: const Icon(Icons.map, color: Colors.blue),
              title: const Text('View Route Map'),
              subtitle: const Text('See pickup and drop locations on map'),
              onTap: () {
                Navigator.pop(context);
                _showRouteMap(booking);
              },
            ),
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
              leading: const Icon(Icons.phone, color: Colors.blue),
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
              leading: const Icon(Icons.phone, color: Colors.blue),
              title: const Text('Call'),
              subtitle: Text(phone.isNotEmpty ? phone : 'No phone available'),
              onTap: () {
                Navigator.pop(context);
                _makePhoneCall(phone);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: Colors.purple),
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnackBar('Could not make phone call', Colors.red);
    }
  }

  Future<void> _sendSMS(
      String phoneNumber, String name, String bookingId) async {
    final url = 'sms:$phoneNumber';
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showSnackBar('Could not send SMS', Colors.red);
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
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    Text('Cancel', style: TextStyle(color: Colors.grey[700])),
              ),
              ElevatedButton.icon(
                onPressed:
                    selectedStatus != null && selectedStatus != currentStatus
                        ? () {
                            Navigator.pop(context);
                            _updateBookingStatus(bookingId, selectedStatus!);
                          }
                        : null,
                icon: const Icon(Icons.update, size: 18),
                label: const Text('Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _adminPrimaryColor,
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
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
    super.build(context);

    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && FirebaseAuth.instance.currentUser == null) {
          _redirectToLogin();
        }
      });

      return Scaffold(
        backgroundColor: _adminBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _adminPrimaryColor),
              const SizedBox(height: 16),
              Text(
                'Checking session...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: _adminBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _adminPrimaryColor),
              const SizedBox(height: 16),
              Text(
                'Verifying admin access...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isAdminVerified) {
      return Scaffold(
        backgroundColor: _adminBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have admin privileges',
                style: TextStyle(color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  _auth.signOut();
                  _redirectToLogin();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _adminPrimaryColor,
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasLoadError && _bookings.isEmpty) {
      return Scaffold(
        backgroundColor: _adminBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
                const SizedBox(height: 16),
                const Text(
                  'Failed to load bookings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage.isNotEmpty
                      ? _errorMessage
                      : 'Network error occurred',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _loadBookings(forceRefresh: true),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _adminPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _adminBackground,
      body: Column(
        children: [
          // Search bar and filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
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
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
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
                        onPressed: () => _loadBookings(forceRefresh: true),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Refresh',
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filters
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width > 600
                          ? 200
                          : MediaQuery.of(context).size.width * 0.45,
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

          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: _adminPrimaryColor.withOpacity(0.05),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                      'Total', '${_bookings.length}', _adminPrimaryColor),
                  const SizedBox(width: 24),
                  _buildStatItem(
                    'Pending',
                    '${_bookings.where((b) => (b['status'] ?? '') == 'Pending').length}',
                    Colors.orange,
                  ),
                  const SizedBox(width: 24),
                  _buildStatItem(
                    'Confirmed',
                    '${_bookings.where((b) => (b['status'] ?? '') == 'Confirmed').length}',
                    Colors.blue,
                  ),
                  const SizedBox(width: 24),
                  _buildStatItem(
                    'Revenue',
                    _formatCurrency(
                      _bookings
                          .where((b) => (b['status'] ?? '') == 'Completed')
                          .fold(0.0, (sum, b) {
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
                      }),
                    ),
                    const Color(0xFF00B14F),
                  ),
                ],
              ),
            ),
          ),

          // Bookings list
          Expanded(
            child: _isDataLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: _adminPrimaryColor),
                        const SizedBox(height: 16),
                        Text(
                          'Loading bookings...',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : _filteredBookings.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long,
                                  size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No bookings found',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.grey[500]),
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
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadBookings(forceRefresh: true),
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
          style: TextStyle(color: Colors.grey[600], fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    String status = booking['status'] ?? 'Pending';
    String pickup =
        booking['pickupLocation']?.toString().split(',').first ?? 'N/A';
    String drop = booking['dropLocation']?.toString().split(',').first ?? 'N/A';

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
      child: GestureDetector(
        onTap: () => _showBookingDetails(booking),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
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
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _getStatusColor(status).withOpacity(0.3)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.directions_car,
                            size: 12, color: _adminPrimaryColor),
                        const SizedBox(width: 4),
                        Text(
                          booking['vehicleName'] ?? 'N/A',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    booking['totalFareFormatted'] ?? '₹0',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _adminPrimaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: MediaQuery.of(context).size.width > 500
                    ? Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        pickup,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700]),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        drop,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700]),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 30,
                            width: 1,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 10, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    booking['displayDate'] ?? 'N/A',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 10, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    booking['displayTime'] ?? 'N/A',
                                    style: TextStyle(
                                        fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking['distanceFormatted'] ?? '0 km',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  pickup,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[700]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  drop,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[700]),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 14, color: Colors.grey[500]),
                                  const SizedBox(height: 2),
                                  Text(
                                    booking['displayDate'] ?? 'N/A',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Icon(Icons.access_time,
                                      size: 14, color: Colors.grey[500]),
                                  const SizedBox(height: 2),
                                  Text(
                                    booking['displayTime'] ?? 'N/A',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  Icon(Icons.straighten,
                                      size: 14, color: Colors.grey[500]),
                                  const SizedBox(height: 2),
                                  Text(
                                    booking['distanceFormatted'] ?? '0 km',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              MediaQuery.of(context).size.width > 400
                  ? Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showRouteMap(booking),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.map,
                                      size: 14, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text(
                                    'Route',
                                    style: TextStyle(
                                        color: Colors.green, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showBookingDetails(booking),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: _adminPrimaryColor),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.receipt,
                                      size: 14, color: _adminPrimaryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Details',
                                    style: TextStyle(
                                        color: _adminPrimaryColor,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        GestureDetector(
                          onTap: () => _showRouteMap(booking),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.green),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.map, size: 14, color: Colors.green),
                                SizedBox(width: 4),
                                Text(
                                  'Route',
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showBookingDetails(booking),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: _adminPrimaryColor),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt,
                                    size: 14, color: _adminPrimaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Details',
                                  style: TextStyle(
                                      color: _adminPrimaryColor, fontSize: 12),
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
      ),
    );
  }
}
