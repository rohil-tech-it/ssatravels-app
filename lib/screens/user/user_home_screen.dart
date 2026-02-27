import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ⚠️ NOTE: These components must exist in the specified paths
import 'components/user_drawer.dart';
import 'components/profile_tab.dart';
import 'components/booking_tab.dart';
import 'components/payment_tab.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // ================ LOCATION VARIABLES ================
  LatLng? _currentLocation;
  String _currentAddress = "Detecting your location...";
  String _currentCity = "";
  String _currentArea = "";
  String _currentStreet = "";
  bool _isLoadingLocation = true;
  bool _isLocationPermissionGranted = false;
  bool _isLocationServiceEnabled = true;
  
  // Real-time location tracking
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isTrackingLocation = false;

  // ================ GOOGLE MAPS ================
  GoogleMapController? _mapController;
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(9.5879, 77.9616),
    zoom: 14.0,
  );
  
  // Map markers
  final Set<Marker> _markers = {};

  // ================ UI STATE ================
  int _currentIndex = 0;
  String _userName = "";
  String _userEmail = "";
  String _userPhone = "";
  bool _isUserDataLoading = true;
  
  // Responsive variables
  late double _screenWidth;
  late double _screenHeight;
  late bool _isSmallScreen;
  late bool _isMediumScreen;
  late bool _isLargeScreen;

  // ================ RIDE TYPES ================
  final List<Map<String, dynamic>> _rideTypes = [
    {'name': 'City Ride', 'icon': FontAwesomeIcons.route, 'color': 0xFF00B14F},
    {'name': 'Outstation', 'icon': FontAwesomeIcons.taxi, 'color': 0xFF2196F3},
    {
      'name': 'Airport',
      'icon': FontAwesomeIcons.planeArrival,
      'color': 0xFFFF9800
    },
    {'name': 'Rental', 'icon': FontAwesomeIcons.clock, 'color': 0xFF9C27B0},
  ];
  
  // ================ QUICK ACTIONS ================
  final List<Map<String, dynamic>> _quickActions = [
    {
      'icon': Icons.book_online,
      'label': 'Book Now',
      'color': 0xFF00B14F,
      'tab': 1
    },
    {'icon': Icons.history, 'label': 'History', 'color': 0xFF2196F3, 'tab': 2},
    {
      'icon': Icons.payment,
      'label': 'Payment',
      'color': 0xFFFF9800,
      'tab': 3
    },
    {
      'icon': Icons.support_agent,
      'label': 'Support',
      'color': 0xFF9C27B0,
      'tab': 4
    },
  ];

  // ================ TIMEOUT CONSTANTS ================
  static const int LOCATION_TIMEOUT = 15;
  static const int GEOCODING_TIMEOUT = 10;
  static const LocationAccuracy DESIRED_ACCURACY = LocationAccuracy.best;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _initializeLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateScreenSize();
  }

  void _updateScreenSize() {
    final size = MediaQuery.of(context).size;
    _screenWidth = size.width;
    _screenHeight = size.height;
    _isSmallScreen = _screenWidth < 360;
    _isMediumScreen = _screenWidth >= 360 && _screenWidth < 600;
    _isLargeScreen = _screenWidth >= 600;
  }

  // Get responsive font size
  double getResponsiveFontSize(double baseSize) {
    if (_isSmallScreen) return baseSize * 0.9;
    if (_isLargeScreen) return baseSize * 1.1;
    return baseSize;
  }

  // Get responsive padding
  double getResponsivePadding(double basePadding) {
    if (_isSmallScreen) return basePadding * 0.8;
    if (_isLargeScreen) return basePadding * 1.2;
    return basePadding;
  }

  // ================ LOAD USER DATA FROM FIREBASE ================
  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => _isUserDataLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get()
              .timeout(
                const Duration(seconds: 10),
                onTimeout: () => throw TimeoutException('Firestore timeout'),
              );

          if (userDoc.exists && mounted) {
            final userData = userDoc.data() as Map<String, dynamic>;
            setState(() {
              _userName = userData['fullName'] ?? user.displayName ?? 'User';
              _userEmail = userData['email'] ?? user.email ?? '';
              _userPhone = userData['phoneNumber'] ?? user.phoneNumber ?? '';
              _isUserDataLoading = false;
            });
          } else {
            setState(() {
              _userName = user.displayName ?? 'User';
              _userEmail = user.email ?? '';
              _userPhone = user.phoneNumber ?? '';
              _isUserDataLoading = false;
            });
          }
        } catch (e) {
          print('Firestore error: $e');
          if (mounted) {
            setState(() {
              _userName = user.displayName ?? 'User';
              _userEmail = user.email ?? '';
              _userPhone = user.phoneNumber ?? '';
              _isUserDataLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _userName = 'Guest';
            _userEmail = '';
            _userPhone = '';
            _isUserDataLoading = false;
          });
        }
      }
    } catch (e) {
      print('User data error: $e');
      if (mounted) {
        setState(() {
          _userName = 'User';
          _userEmail = '';
          _userPhone = '';
          _isUserDataLoading = false;
        });
      }
    }
  }

  // ================ LOCATION METHODS ================
  Future<void> _initializeLocation() async {
    if (!mounted) return;

    _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!_isLocationServiceEnabled) {
      if (mounted) {
        setState(() {
          _currentAddress = "Location services are disabled";
          _isLoadingLocation = false;
        });
      }
      _showLocationServiceDialog();
      return;
    }

    await _checkAndRequestPermissions();

    if (_isLocationPermissionGranted && mounted) {
      await _getCurrentLocation();
      _startRealTimeLocationTracking();
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!mounted) return;

    if (permission == LocationPermission.denied) {
      setState(() {
        _currentAddress = "Location permissions denied";
        _isLoadingLocation = false;
        _isLocationPermissionGranted = false;
      });
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _currentAddress = "Location permissions permanently denied";
        _isLoadingLocation = false;
        _isLocationPermissionGranted = false;
      });
      _showPermissionDialog();
      return;
    }

    _isLocationPermissionGranted = true;
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoadingLocation = true);

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: DESIRED_ACCURACY,
        timeLimit: Duration(seconds: LOCATION_TIMEOUT),
      );

      final newLocation = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentLocation = newLocation;
          _updateMarker(newLocation);
        });
      }

      await _updateAddressWithTimeout(position);
      _animateToUserLocation();
    } catch (e) {
      print("Location error: $e");
      if (mounted) {
        setState(() {
          _currentAddress = "Unable to get location";
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _updateMarker(LatLng position) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: "Your Location",
          snippet: _currentAddress,
        ),
      ),
    );
  }

  void _startRealTimeLocationTracking() {
    if (_isTrackingLocation) return;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: DESIRED_ACCURACY,
      distanceFilter: 10,
      timeLimit: null,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        if (!mounted) return;
        
        final newLocation = LatLng(position.latitude, position.longitude);
        
        if (_currentLocation == null || 
            _calculateDistance(_currentLocation!, newLocation) > 10) {
          
          setState(() {
            _currentLocation = newLocation;
            _updateMarker(newLocation);
          });
          
          _updateAddressSilently(position);
          _animateToUserLocation();
        }
      },
      onError: (error) {
        print("Location stream error: $error");
      },
    );

    _isTrackingLocation = true;
  }

  double _calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude, start.longitude,
      end.latitude, end.longitude
    );
  }

  Future<void> _updateAddressSilently(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String street = place.street ?? '';
        String locality = place.locality ?? '';
        String administrativeArea = place.administrativeArea ?? '';
        String subLocality = place.subLocality ?? '';
        String name = place.name ?? '';

        String city = locality.isNotEmpty ? locality : administrativeArea;
        String area = subLocality.isNotEmpty ? subLocality : name;
        
        String address = "";
        if (street.isNotEmpty && area.isNotEmpty) {
          address = "$street, $area";
        } else if (street.isNotEmpty) {
          address = street;
        } else if (area.isNotEmpty) {
          address = area;
        } else if (locality.isNotEmpty) {
          address = locality;
        } else {
          address = "Current Location";
        }

        if (mounted) {
          setState(() {
            _currentCity = city.isNotEmpty ? city : "Unknown";
            _currentArea = area;
            _currentStreet = street;
            _currentAddress = address;
          });
        }
      }
    } catch (e) {
      debugPrint("Silent address update error: $e");
    }
  }

  Future<void> _updateAddressWithTimeout(Position position) async {
    try {
      await Future.any([
        _updateAddress(position),
        Future.delayed(Duration(seconds: GEOCODING_TIMEOUT),
            () => throw TimeoutException('Geocoding timeout'))
      ]);
    } catch (e) {
      print('Address update timeout or error: $e');
      if (mounted) {
        setState(() {
          _currentAddress = "Location detected";
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _updateAddress(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        String street = place.street ?? '';
        String locality = place.locality ?? '';
        String administrativeArea = place.administrativeArea ?? '';
        String subLocality = place.subLocality ?? '';
        String name = place.name ?? '';

        String city = locality.isNotEmpty ? locality : administrativeArea;
        String area = subLocality.isNotEmpty ? subLocality : name;
        
        String address = "";
        if (street.isNotEmpty && area.isNotEmpty) {
          address = "$street, $area";
        } else if (street.isNotEmpty) {
          address = street;
        } else if (area.isNotEmpty) {
          address = area;
        } else if (locality.isNotEmpty) {
          address = locality;
        } else {
          address = "Current Location";
        }

        if (mounted) {
          setState(() {
            _currentCity = city.isNotEmpty ? city : "Unknown";
            _currentArea = area;
            _currentStreet = street;
            _currentAddress = address;
            _isLoadingLocation = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _currentAddress = "Current Location";
            _currentCity = "Unknown";
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Address update error: $e");
      if (mounted) {
        setState(() {
          _currentAddress = "Current Location";
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _animateToUserLocation() {
    final controller = _mapController;
    final location = _currentLocation;

    if (location != null && controller != null) {
      try {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: location,
              zoom: 18,
            ),
          ),
        );
      } catch (e) {
        print('Camera animation error: $e');
      }
    }
  }

  Future<void> _refreshLocation() async {
    if (_isLocationPermissionGranted) {
      await _getCurrentLocation();
    } else {
      await _checkAndRequestPermissions();
      if (_isLocationPermissionGranted && mounted) {
        await _getCurrentLocation();
      }
    }
  }

  Future<void> _getLocationWithGPS() async {
    try {
      bool isGpsEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (!isGpsEnabled) {
        _showLocationServiceDialog();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: LOCATION_TIMEOUT),
      );

      final newLocation = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentLocation = newLocation;
          _updateMarker(newLocation);
        });
      }

      await _updateAddressWithTimeout(position);
      _animateToUserLocation();
    } catch (e) {
      print("GPS error: $e");
    }
  }

  void _showLocationServiceDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Location Services Disabled"),
        content:
            const Text("Please enable location services (GPS) to find nearby cabs accurately."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B14F),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Location Permission Required"),
        content: const Text(
            "This app needs location permission to show nearby cabs. Please grant permission for accurate location."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _checkAndRequestPermissions();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B14F),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("Grant Permission"),
          ),
        ],
      ),
    );
  }

  // ================ NAVIGATION METHODS ================
  void _navigateToBooking() {
    setState(() {
      _currentIndex = 1;
    });
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Booking';
      case 2:
        return 'Payment';
      case 3:
        return 'Profile';
      default:
        return 'Home';
    }
  }

  // ================ DISPOSE ================
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ================ BUILD METHODS ================
  @override
  Widget build(BuildContext context) {
    _updateScreenSize();
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      drawer: UserDrawer(
        currentIndex: _currentIndex,
        userName: _userName,
        onIndexChanged: (i) {
          if (mounted) {
            setState(() => _currentIndex = i);
          }
        },
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    try {
      switch (_currentIndex) {
        case 0:
          return _buildHomeContent();
        case 1:
          return const BookingTab();
        case 2:
          return const PaymentScreen();
        case 3:
          return ProfileTab(
            userName: _userName,
          );
        default:
          return _buildHomeContent();
      }
    } catch (e) {
      print('Error building tab: $e');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading tab: $e'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            height: _isSmallScreen ? 40 : 50,
            width: _isSmallScreen ? 40 : 50,
            child: Image.asset(
              'assets/ssa-logo.png',
              height: _isSmallScreen ? 40 : 50,
              width: _isSmallScreen ? 40 : 50,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: _isSmallScreen ? 40 : 50,
                  width: _isSmallScreen ? 40 : 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: _isSmallScreen ? 22 : 28,
                  ),
                );
              },
            ),
          ),
          SizedBox(width: _isSmallScreen ? 8 : 12),
          Text(
            _getAppBarTitle(),
            style: TextStyle(
              fontSize: getResponsiveFontSize(20),
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF00B14F),
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: _isSmallScreen ? 8 : 12),
          child: IconButton(
            icon: Icon(
              Icons.notifications_none,
              size: _isSmallScreen ? 22 : 24,
            ),
            onPressed: () {},
            color: Colors.white,
          ),
        ),
      ],
      toolbarHeight: _isSmallScreen ? 60 : 70,
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _refreshLocation,
      color: const Color(0xFF00B14F),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildWelcomeBanner(),
          ),
          SliverToBoxAdapter(
            child: _buildSSABranding(),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: getResponsivePadding(16),
                vertical: getResponsivePadding(16),
              ),
              child: _buildRideTypeGrid(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: getResponsivePadding(16),
              ),
              child: _buildLocationCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(getResponsivePadding(16)),
              child: _buildBookRideButton(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: getResponsivePadding(16),
              ),
              child: _buildQuickActionsGrid(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                getResponsivePadding(16),
                getResponsivePadding(20),
                getResponsivePadding(16),
                12,
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(getResponsivePadding(6)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B14F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.map_rounded,
                      color: Color(0xFF00B14F),
                      size: 16,
                    ),
                  ),
                  SizedBox(width: _isSmallScreen ? 8 : 12),
                  Text(
                    'Live Location Map',
                    style: TextStyle(
                      fontSize: getResponsiveFontSize(16),
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                getResponsivePadding(16),
                0,
                getResponsivePadding(16),
                20,
              ),
              child: _buildMapCard(),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(getResponsivePadding(20)),
      decoration: BoxDecoration(
        color: const Color(0xFF00B14F),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B14F).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: _isSmallScreen ? 45 : 55,
            height: _isSmallScreen ? 45 : 55,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: _isSmallScreen ? 22 : 28,
            ),
          ),
          SizedBox(width: _isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    fontSize: getResponsiveFontSize(14),
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: _isSmallScreen ? 2 : 4),
                _isUserDataLoading
                    ? Container(
                        width: 100,
                        height: _isSmallScreen ? 20 : 24,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                    : Text(
                        _userName,
                        style: TextStyle(
                          fontSize: getResponsiveFontSize(22),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(getResponsivePadding(6)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              color: Colors.white,
              size: _isSmallScreen ? 18 : 22,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSSABranding() {
    return Container(
      margin: EdgeInsets.all(getResponsivePadding(16)),
      padding: EdgeInsets.all(getResponsivePadding(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00B14F), Color(0xFF008537)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B14F).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(getResponsivePadding(10)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: Colors.white,
                  size: _isSmallScreen ? 22 : 28,
                ),
              ),
              SizedBox(width: _isSmallScreen ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SSA Travels',
                      style: TextStyle(
                        fontSize: getResponsiveFontSize(20),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: _isSmallScreen ? 2 : 4),
                    Text(
                      'Safe • Secure • Reliable',
                      style: TextStyle(
                        fontSize: getResponsiveFontSize(12),
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: _isSmallScreen ? 12 : 16),
          Container(
            padding: EdgeInsets.symmetric(
              vertical: getResponsivePadding(8),
              horizontal: getResponsivePadding(16),
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              'Book Your Ride, Anytime, Anywhere!',
              style: TextStyle(
                fontSize: getResponsiveFontSize(12),
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(getResponsivePadding(18)),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(getResponsivePadding(8)),
              decoration: BoxDecoration(
                color: const Color(0xFF00B14F).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.my_location,
                color: Color(0xFF00B14F),
                size: 16,
              ),
            ),
            SizedBox(width: _isSmallScreen ? 12 : 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT LOCATION',
                    style: TextStyle(
                      fontSize: getResponsiveFontSize(11),
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: _isSmallScreen ? 2 : 4),
                  Text(
                    _isLoadingLocation
                        ? "Detecting your location..."
                        : (_currentStreet.isNotEmpty && _currentArea.isNotEmpty
                            ? "$_currentStreet, $_currentArea"
                            : (_currentCity.isNotEmpty
                                ? _currentCity
                                : _currentAddress)),
                    style: TextStyle(
                      fontSize: getResponsiveFontSize(14),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_currentCity.isNotEmpty && _currentArea.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: getResponsivePadding(2)),
                      child: Text(
                        _currentCity,
                        style: TextStyle(
                          fontSize: getResponsiveFontSize(11),
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(getResponsivePadding(6)),
              decoration: BoxDecoration(
                color: const Color(0xFF00B14F).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: Color(0xFF00B14F),
                  size: 16,
                ),
                onPressed: _getLocationWithGPS,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookRideButton() {
    return Container(
      width: double.infinity,
      height: _isSmallScreen ? 48 : 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Color(0xFF00B14F), Color(0xFF008537)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B14F).withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _navigateToBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_online,
              color: Colors.white,
              size: _isSmallScreen ? 18 : 22,
            ),
            SizedBox(width: _isSmallScreen ? 6 : 8),
            Text(
              'Book Ride',
              style: TextStyle(
                fontSize: getResponsiveFontSize(16),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideTypeGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: _rideTypes.map((ride) {
        return _buildRideTypeItem(
          ride['icon'],
          ride['name'],
          Color(ride['color']),
        );
      }).toList(),
    );
  }

  Widget _buildRideTypeItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: _isSmallScreen ? 50 : 60,
          height: _isSmallScreen ? 50 : 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Icon(
            icon,
            color: color,
            size: _isSmallScreen ? 22 : 28,
          ),
        ),
        SizedBox(height: _isSmallScreen ? 6 : 8),
        Text(
          label,
          style: TextStyle(
            fontSize: getResponsiveFontSize(11),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: _isSmallScreen ? 6 : 8,
        mainAxisSpacing: _isSmallScreen ? 6 : 8,
      ),
      itemCount: _quickActions.length,
      itemBuilder: (context, index) {
        final action = _quickActions[index];
        return _buildQuickActionCard(
          action['icon'],
          action['label'],
          Color(action['color']),
          () {
            if (mounted) {
              setState(() {
                _currentIndex = action['tab'];
              });
            }
          },
        );
      },
    );
  }

  Widget _buildQuickActionCard(IconData icon, String label, Color color,
      VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(getResponsivePadding(8)),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: _isSmallScreen ? 18 : 22,
                ),
              ),
              SizedBox(height: _isSmallScreen ? 4 : 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: getResponsiveFontSize(10),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapCard() {
    return Container(
      height: _isSmallScreen ? 200 : 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _currentLocation != null
                  ? CameraPosition(target: _currentLocation!, zoom: 18)
                  : _initialCameraPosition,
              onMapCreated: (controller) {
                _mapController = controller;
                if (_currentLocation != null) {
                  _animateToUserLocation();
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              markers: _markers,
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMapButton(
                    icon: Icons.add,
                    onPressed: () {
                      final controller = _mapController;
                      if (controller != null) {
                        try {
                          controller.animateCamera(
                            CameraUpdate.zoomIn(),
                          );
                        } catch (e) {
                          print('Zoom in error: $e');
                        }
                      }
                    },
                  ),
                  Container(
                    height: 1,
                    width: 25,
                    color: Colors.grey.shade300,
                  ),
                  _buildMapButton(
                    icon: Icons.remove,
                    onPressed: () {
                      final controller = _mapController;
                      if (controller != null) {
                        try {
                          controller.animateCamera(
                            CameraUpdate.zoomOut(),
                          );
                        } catch (e) {
                          print('Zoom out error: $e');
                        }
                      }
                    },
                  ),
                  Container(
                    height: 1,
                    width: 25,
                    color: Colors.grey.shade300,
                  ),
                  _buildMapButton(
                    icon: Icons.my_location,
                    onPressed: _animateToUserLocation,
                  ),
                  Container(
                    height: 1,
                    width: 25,
                    color: Colors.grey.shade300,
                  ),
                  _buildMapButton(
                    icon: Icons.gps_fixed,
                    onPressed: _getLocationWithGPS,
                  ),
                ],
              ),
            ),
          ),
          if (_isLoadingLocation)
            const Positioned.fill(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B14F)),
                ),
              ),
            ),
          if (!_isLoadingLocation && _currentLocation != null)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00B14F),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: const Color(0xFF00B14F), size: 20),
      onPressed: onPressed,
      padding: EdgeInsets.all(_isSmallScreen ? 8 : 10),
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (mounted) {
              setState(() => _currentIndex = index);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF00B14F),
          unselectedItemColor: Colors.grey.shade400,
          selectedFontSize: _isSmallScreen ? 11 : 12,
          unselectedFontSize: _isSmallScreen ? 11 : 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.home_outlined,
                size: _isSmallScreen ? 22 : 24,
              ),
              activeIcon: Icon(
                Icons.home,
                size: _isSmallScreen ? 22 : 24,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.directions_car_outlined,
                size: _isSmallScreen ? 22 : 24,
              ),
              activeIcon: Icon(
                Icons.directions_car,
                size: _isSmallScreen ? 22 : 24,
              ),
              label: 'Booking',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.payment_outlined,
                size: _isSmallScreen ? 22 : 24,
              ),
              activeIcon: Icon(
                Icons.payment,
                size: _isSmallScreen ? 22 : 24,
              ),
              label: 'Payment',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.person_outline,
                size: _isSmallScreen ? 22 : 24,
              ),
              activeIcon: Icon(
                Icons.person,
                size: _isSmallScreen ? 22 : 24,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}