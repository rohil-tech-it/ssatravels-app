import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import 'components/user_drawer.dart';
import 'components/profile_tab.dart';
import 'components/booking_tab.dart';
import 'components/wallet_tab.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  // Google Maps Controller
  Completer<GoogleMapController> _mapController = Completer();

  // Initial position (default to Virudhunagar)
  LatLng _initialPosition = const LatLng(11.0168, 76.9558);
  LatLng? _currentPosition;

  // UI State
  int _currentIndex = 0;
  String _currentAddress = "Detecting your location...";
  bool _isLoadingLocation = true;
  bool _followUser = true;
  bool _isLocationPermissionGranted = false;
  bool _isLocationServiceEnabled = true;

  // Markers
  Set<Marker> _markers = {};
  Marker? _userMarker;

  // Location Stream
  StreamSubscription<Position>? _positionStream;

  // Address cache
  final Map<String, String> _addressCache = {};
  String _lastKnownAddress = "";

  // Google Maps Configuration
  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(11.0168, 76.9558),
    zoom: 16.0,
  );

  // Google Maps API Key (Replace with your actual key)
  static const String GOOGLE_MAPS_API_KEY =
      'AIzaSyA3ElqlmQtIPePKOhQweCdcKADv0K2c3ww';

  // Tamil Nadu Temple & Tourist Places Data
  final List<TouristPlace> _popularPlaces = [
    TouristPlace(
      id: 'tiruchendur',
      name: 'Thiruchendur Murugan Temple',
      position: const LatLng(8.4960, 78.1205),
      type: PlaceType.temple,
      description: 'One of the Arupadaiveedu of Lord Murugan',
      distanceKm: 150,
    ),
    TouristPlace(
      id: 'madurai_meenakshi',
      name: 'Madurai Meenakshi Amman Temple',
      position: const LatLng(9.9196, 78.1193),
      type: PlaceType.temple,
      description: 'Historic Hindu temple dedicated to Goddess Meenakshi',
      distanceKm: 120,
    ),
    TouristPlace(
      id: 'thanjavur_brihadeeswarar',
      name: 'Brihadeeswarar Temple, Thanjavur',
      position: const LatLng(10.7828, 79.1318),
      type: PlaceType.temple,
      description: 'UNESCO World Heritage Site built by Raja Raja Chola',
      distanceKm: 220,
    ),
    TouristPlace(
      id: 'rameshwaram',
      name: 'Ramanathaswamy Temple, Rameshwaram',
      position: const LatLng(9.2881, 79.3173),
      type: PlaceType.temple,
      description: 'One of the Char Dham pilgrimage sites',
      distanceKm: 180,
    ),
    TouristPlace(
      id: 'kanyakumari',
      name: 'Kanyakumari Temple & Vivekananda Rock',
      position: const LatLng(8.0783, 77.5413),
      type: PlaceType.tourist,
      description: 'Southernmost tip of India with sunrise/sunset view',
      distanceKm: 250,
    ),
    TouristPlace(
      id: 'ooty',
      name: 'Ooty Hill Station',
      position: const LatLng(11.4102, 76.6950),
      type: PlaceType.tourist,
      description: 'Popular hill station with botanical gardens',
      distanceKm: 280,
    ),
    TouristPlace(
      id: 'kodaikanal',
      name: 'Kodaikanal Lake',
      position: const LatLng(10.2381, 77.4892),
      type: PlaceType.tourist,
      description: 'Star-shaped lake in Princess of Hill Stations',
      distanceKm: 160,
    ),
    TouristPlace(
      id: 'mahabalipuram',
      name: 'Mahabalipuram Shore Temple',
      position: const LatLng(12.6168, 80.1922),
      type: PlaceType.temple,
      description: 'UNESCO World Heritage Site by Pallava dynasty',
      distanceKm: 320,
    ),
    TouristPlace(
      id: 'kutralam',
      name: 'Kutralam Waterfalls',
      position: const LatLng(8.9272, 77.2751),
      type: PlaceType.tourist,
      description: 'Famous waterfalls known as Spa of South India',
      distanceKm: 140,
    ),
    TouristPlace(
      id: 'srirangam',
      name: 'Srirangam Ranganathaswamy Temple',
      position: const LatLng(10.8610, 78.6911),
      type: PlaceType.temple,
      description: 'Largest functioning Hindu temple in the world',
      distanceKm: 200,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocation();
      _addTouristPlaceMarkers();
    });
  }

  Future<void> _initializeLocation() async {
    // Check location service
    _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!_isLocationServiceEnabled) {
      setState(() {
        _currentAddress = "Location services are disabled";
        _isLoadingLocation = false;
      });
      _showLocationServiceDialog();
      return;
    }

    // Check and request permissions
    await _checkAndRequestPermissions();

    if (_isLocationPermissionGranted) {
      await _startLiveLocation();
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    var status = await Permission.location.request();

    if (status.isGranted) {
      setState(() {
        _isLocationPermissionGranted = true;
      });
    } else if (status.isDenied) {
      setState(() {
        _currentAddress = "Location permissions denied";
        _isLoadingLocation = false;
        _isLocationPermissionGranted = false;
      });
      _showPermissionDialog();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _currentAddress = "Location permissions permanently denied";
        _isLoadingLocation = false;
        _isLocationPermissionGranted = false;
      });
      _showPermissionDialog();
    }
  }

  Future<void> _startLiveLocation() async {
    try {
      // Get initial location
      await _refreshLocation();

      // Start listening to position stream
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 5, // Update every 5 meters
        ),
      ).listen((Position position) {
        _updateUserLocation(position);
      });
    } catch (e) {
      debugPrint("Error starting location stream: $e");
      setState(() {
        _currentAddress = "Error tracking location";
        _isLoadingLocation = false;
      });
    }
  }

  void _updateUserLocation(Position position) {
    final newPosition = LatLng(position.latitude, position.longitude);

    // Update current position
    setState(() {
      _currentPosition = newPosition;
      _isLoadingLocation = false;
    });

    // Update marker
    _updateMarker(newPosition);

    // Update map camera if following user
    if (_followUser) {
      _animateCameraToPosition(newPosition);
    }

    // Update address
    _updateAddressFromLatLng(newPosition);

    // Update distances for all places
    _updateAllPlaceDistances(newPosition);
  }

  void _updateAllPlaceDistances(LatLng userPosition) {
    setState(() {
      for (var place in _popularPlaces) {
        place.currentDistance =
            _calculateHaversineDistance(userPosition, place.position);
      }
    });
  }

  void _updateMarker(LatLng position) {
    final markerId = MarkerId('user_location');

    final marker = Marker(
      markerId: markerId,
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(
        title: 'Your Location',
        snippet: 'Live tracking active',
      ),
      rotation: 0,
      draggable: false,
      zIndex: 2,
      flat: true,
      consumeTapEvents: true,
      onTap: () {
        debugPrint('Marker tapped at: $position');
      },
    );

    setState(() {
      _markers.removeWhere((m) => m.markerId == markerId);
      _markers.add(marker);
      _userMarker = marker;
    });
  }

  Future<void> _animateCameraToPosition(LatLng position) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 16.0,
          bearing: 0,
          tilt: 0,
        ),
      ),
    );
  }

  void _addTouristPlaceMarkers() {
    for (var place in _popularPlaces) {
      final marker = Marker(
        markerId: MarkerId(place.id),
        position: place.position,
        icon: place.type == PlaceType.temple
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: place.name,
          snippet: place.description,
        ),
        onTap: () {
          _showPlaceDetails(place);
        },
      );

      setState(() {
        _markers.add(marker);
      });
    }
  }

  Future<void> _navigateToPlace(TouristPlace place) async {
    setState(() {
      _followUser = false;
    });

    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: place.position,
          zoom: 14.0,
          bearing: 0,
          tilt: 0,
        ),
      ),
    );

    // Show route details dialog
    _showNavigationDialog(place);
  }

  void _showPlaceDetails(TouristPlace place) {
    double distanceFromUser = _currentPosition != null
        ? _calculateHaversineDistance(_currentPosition!, place.position)
        : place.distanceKm.toDouble();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              place.type == PlaceType.temple
                  ? Icons.temple_hindu
                  : Icons.landscape,
              color: const Color(0xFF00B14F),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                place.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00B14F),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              place.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 10),
            Text(
              'Distance from your location: ${distanceFromUser.toStringAsFixed(1)} km',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Approximate travel time: ${_calculateTravelTime(distanceFromUser)}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToPlace(place);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B14F),
            ),
            child: const Text(
              'Navigate',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showNavigationDialog(TouristPlace place) {
    double distanceFromUser = _currentPosition != null
        ? _calculateHaversineDistance(_currentPosition!, place.position)
        : place.distanceKm.toDouble();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Start Navigation',
          style: TextStyle(
            color: Color(0xFF00B14F),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.navigation,
              color: Color(0xFF00B14F),
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              'Navigate to ${place.name}?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Distance: ${distanceFromUser.toStringAsFixed(1)} km',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Travel time: ${_calculateTravelTime(distanceFromUser)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Starting navigation to ${place.name}'),
                  backgroundColor: const Color(0xFF00B14F),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B14F),
            ),
            child: const Text(
              'Start Navigation',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Haversine formula for accurate distance calculation
  double _calculateHaversineDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371.0; // Earth radius in kilometers

    double lat1 = start.latitude * pi / 180.0;
    double lon1 = start.longitude * pi / 180.0;
    double lat2 = end.latitude * pi / 180.0;
    double lon2 = end.longitude * pi / 180.0;

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  String _calculateTravelTime(double distanceKm) {
    // Assuming average speed of 50 km/h for temples, 40 km/h for tourist spots
    double averageSpeed = 50.0; // km/h
    double hours = distanceKm / averageSpeed;

    if (hours < 1) {
      int minutes = (hours * 60).round();
      return '$minutes mins';
    } else {
      int hourPart = hours.floor();
      int minutePart = ((hours - hourPart) * 60).round();
      return '$hourPart hrs ${minutePart} mins';
    }
  }

  Future<void> _refreshLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 10),
      );

      _updateUserLocation(position);

      // Get address immediately
      await _updateAddressFromLatLng(
        LatLng(position.latitude, position.longitude),
      );
    } catch (e) {
      debugPrint("Error getting location: $e");
      setState(() {
        _currentAddress = "Error getting location";
        _isLoadingLocation = false;
      });
    }
  }

  Future<void> _updateAddressFromLatLng(LatLng position) async {
    final String cacheKey =
        "${position.latitude.toStringAsFixed(6)},${position.longitude.toStringAsFixed(6)}";

    // Check cache first
    if (_addressCache.containsKey(cacheKey)) {
      setState(() {
        _currentAddress = _addressCache[cacheKey]!;
      });
      return;
    }

    try {
      // Using Google Geocoding API for better accuracy
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$GOOGLE_MAPS_API_KEY',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          String formattedAddress = data['results'][0]['formatted_address'];

          // Cache the address
          _addressCache[cacheKey] = formattedAddress;
          _lastKnownAddress = formattedAddress;

          if (mounted) {
            setState(() {
              _currentAddress = formattedAddress;
            });
          }

          debugPrint("📍 Address updated: $formattedAddress");
        } else {
          _fallbackGeocoding(position);
        }
      } else {
        _fallbackGeocoding(position);
      }
    } catch (e) {
      debugPrint("Geocoding API error: $e");
      _fallbackGeocoding(position);
    }
  }

  Future<void> _fallbackGeocoding(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address = _getFormattedAddress(place);

        setState(() {
          _currentAddress = address;
        });
      } else {
        String fallbackAddress =
            "Live Location (${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)})";

        setState(() {
          _currentAddress = fallbackAddress;
        });
      }
    } catch (e) {
      debugPrint("Fallback geocoding error: $e");
      setState(() {
        _currentAddress = "Live Location Tracking";
      });
    }
  }

  String _getFormattedAddress(Placemark place) {
    List<String> addressParts = [];

    if (place.street != null && place.street!.isNotEmpty) {
      addressParts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      addressParts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      addressParts.add(place.postalCode!);
    }

    return addressParts.isNotEmpty ? addressParts.join(', ') : "Live Location";
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Location Services Required"),
        content: const Text(
            "Please enable location services to use live tracking features."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
              _initializeLocation();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Location Permission Required"),
        content: const Text(
            "This app needs location permission to provide live tracking and accurate navigation."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
              await Future.delayed(const Duration(seconds: 1));
              _initializeLocation();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController.complete(controller);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: UserDrawer(
        currentIndex: _currentIndex,
        onIndexChanged: (i) => setState(() => _currentIndex = i),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return BookingTab();
      case 2:
        return WalletTab();
      case 3:
        return const ProfileTab();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 600;
        final bool isMediumScreen =
            constraints.maxWidth >= 600 && constraints.maxWidth < 900;

        return Column(
          children: [
            // Google Map Section - Responsive height
            SizedBox(
              height: isSmallScreen
                  ? MediaQuery.of(context).size.height * 0.4
                  : MediaQuery.of(context).size.height * 0.45,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: _initialCameraPosition,
                    onMapCreated: _onMapCreated,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapType: MapType.normal,
                    markers: _markers,
                    onCameraMove: (CameraPosition position) {
                      if (position.target != _currentPosition) {
                        setState(() {
                          _followUser = false;
                        });
                      }
                    },
                  ),

                  // Top Location Card
                  Positioned(
                    top: 16,
                    left: isSmallScreen ? 8 : 16,
                    right: isSmallScreen ? 8 : 16,
                    child: _buildLocationCard(),
                  ),

                  // My Location Button
                  if (!_followUser && _currentPosition != null)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: FloatingActionButton(
                        onPressed: () {
                          setState(() {
                            _followUser = true;
                          });
                          _animateCameraToPosition(_currentPosition!);
                        },
                        backgroundColor: const Color(0xFF00B14F),
                        child:
                            const Icon(Icons.my_location, color: Colors.white),
                        mini: isSmallScreen,
                        elevation: 4,
                      ),
                    ),

                  // Loading Overlay
                  if (_isLoadingLocation)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black12,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00B14F),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom Content Section - Responsive layout
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Navigation CTA Button - Responsive
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(
                          Icons.navigation,
                          size: isSmallScreen ? 20 : 24,
                        ),
                        label: Text(
                          'Booking',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B14F),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: isSmallScreen ? 14 : 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(isSmallScreen ? 12 : 16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => BookingTab()),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // Quick Navigation - Responsive grid
                    const Text(
                      'Quick Navigation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),

                    isSmallScreen
                        ? _buildSmallQuickNavGrid()
                        : _buildLargeQuickNavGrid(),

                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // Popular Tamil Nadu Destinations
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Popular Tamil Nadu Destinations',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            _showAllPlaces();
                          },
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: Color(0xFF00B14F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Places List - Responsive height
                    SizedBox(
                      height: isSmallScreen ? 180 : 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _popularPlaces.length,
                        itemBuilder: (context, index) {
                          return _buildPlaceCard(
                              _popularPlaces[index], isSmallScreen);
                        },
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // Near You Section
                    if (_currentPosition != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Temples Near You',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildNearbyPlaces(isSmallScreen),
                        ],
                      ),

                    SizedBox(height: isSmallScreen ? 16 : 24),

                    // Why Explore Tamil Nadu? - Responsive
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9F0),
                        borderRadius:
                            BorderRadius.circular(isSmallScreen ? 12 : 16),
                        border: Border.all(
                            color: const Color(0xFF00B14F).withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Why Explore Tamil Nadu?',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00B14F),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildFeatureItem('Ancient Temples',
                              Icons.temple_hindu, isSmallScreen),
                          _buildFeatureItem(
                              'Rich Heritage', Icons.history, isSmallScreen),
                          _buildFeatureItem('Beautiful Landscapes',
                              Icons.landscape, isSmallScreen),
                          _buildFeatureItem('Spiritual Experience',
                              Icons.self_improvement, isSmallScreen),
                        ],
                      ),
                    ),

                    SizedBox(height: isSmallScreen ? 16 : 24),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSmallQuickNavGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.8,
      children: [
        _buildQuickNavCard(
          icon: Icons.temple_hindu,
          label: 'Temples',
          onTap: () => _filterPlacesByType(PlaceType.temple),
        ),
        _buildQuickNavCard(
          icon: Icons.landscape,
          label: 'Tourist',
          onTap: () => _filterPlacesByType(PlaceType.tourist),
        ),
        _buildQuickNavCard(
          icon: Icons.water,
          label: 'Waterfalls',
          onTap: () => _filterPlacesByName('Waterfalls'),
        ),
        _buildQuickNavCard(
          icon: Icons.terrain,
          label: 'Hills',
          onTap: () => _filterPlacesByName('Hill'),
        ),
      ],
    );
  }

  Widget _buildLargeQuickNavGrid() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildQuickNavCard(
          icon: Icons.temple_hindu,
          label: 'Temples',
          onTap: () => _filterPlacesByType(PlaceType.temple),
        ),
        _buildQuickNavCard(
          icon: Icons.landscape,
          label: 'Tourist Places',
          onTap: () => _filterPlacesByType(PlaceType.tourist),
        ),
        _buildQuickNavCard(
          icon: Icons.water,
          label: 'Waterfalls',
          onTap: () => _filterPlacesByName('Waterfalls'),
        ),
        _buildQuickNavCard(
          icon: Icons.terrain,
          label: 'Hill Stations',
          onTap: () => _filterPlacesByName('Hill'),
        ),
      ],
    );
  }

  void _showTempleSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            const Text(
              'Select a Temple to Navigate',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00B14F),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _popularPlaces
                    .where((p) => p.type == PlaceType.temple)
                    .length,
                itemBuilder: (context, index) {
                  final temple = _popularPlaces
                      .where((p) => p.type == PlaceType.temple)
                      .toList()[index];
                  final distance = _currentPosition != null
                      ? _calculateHaversineDistance(
                          _currentPosition!, temple.position)
                      : temple.distanceKm.toDouble();

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B14F).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.temple_hindu,
                          color: Color(0xFF00B14F)),
                    ),
                    title: Text(temple.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(temple.description,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} km away',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    trailing:
                        const Icon(Icons.navigation, color: Color(0xFF00B14F)),
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToPlace(temple);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllPlaces() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            const Text(
              'All Places',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00B14F),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _popularPlaces.length,
                itemBuilder: (context, index) {
                  final place = _popularPlaces[index];
                  final distance = _currentPosition != null
                      ? _calculateHaversineDistance(
                          _currentPosition!, place.position)
                      : place.distanceKm.toDouble();

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00B14F).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        place.type == PlaceType.temple
                            ? Icons.temple_hindu
                            : Icons.landscape,
                        color: const Color(0xFF00B14F),
                      ),
                    ),
                    title: Text(place.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.description,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} km away',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFF00B14F)),
                    onTap: () {
                      Navigator.pop(context);
                      _showPlaceDetails(place);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _filterPlacesByType(PlaceType type) {
    final filtered = _popularPlaces.where((p) => p.type == type).toList();
    _showFilteredPlaces(
        filtered, type == PlaceType.temple ? 'Temples' : 'Tourist Places');
  }

  void _filterPlacesByName(String keyword) {
    final filtered = _popularPlaces
        .where((p) =>
            p.name.toLowerCase().contains(keyword.toLowerCase()) ||
            p.description.toLowerCase().contains(keyword.toLowerCase()))
        .toList();

    _showFilteredPlaces(filtered, keyword);
  }

  void _showFilteredPlaces(List<TouristPlace> places, String title) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00B14F),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: places.length,
                itemBuilder: (context, index) {
                  final place = places[index];
                  final distance = _currentPosition != null
                      ? _calculateHaversineDistance(
                          _currentPosition!, place.position)
                      : place.distanceKm.toDouble();

                  return ListTile(
                    leading: Icon(
                      place.type == PlaceType.temple
                          ? Icons.temple_hindu
                          : Icons.landscape,
                      color: const Color(0xFF00B14F),
                    ),
                    title: Text(place.name),
                    subtitle: Text('${distance.toStringAsFixed(1)} km away'),
                    trailing: const Icon(Icons.chevron_right,
                        color: Color(0xFF00B14F)),
                    onTap: () {
                      Navigator.pop(context);
                      _showPlaceDetails(place);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceCard(TouristPlace place, bool isSmallScreen) {
    double distance = _currentPosition != null
        ? _calculateHaversineDistance(_currentPosition!, place.position)
        : place.distanceKm.toDouble();

    return Container(
      width: isSmallScreen ? 140 : 160,
      margin: EdgeInsets.only(right: isSmallScreen ? 8 : 12),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
        ),
        child: InkWell(
          onTap: () => _showPlaceDetails(place),
          borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: isSmallScreen ? 36 : 40,
                  height: isSmallScreen ? 36 : 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B14F).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    place.type == PlaceType.temple
                        ? Icons.temple_hindu
                        : Icons.landscape,
                    color: const Color(0xFF00B14F),
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 10),
                Text(
                  place.name,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 12 : 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmallScreen ? 4 : 5),
                Text(
                  place.description,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: isSmallScreen ? 10 : 12, color: Colors.green),
                    SizedBox(width: isSmallScreen ? 2 : 4),
                    Expanded(
                      child: Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNearbyPlaces(bool isSmallScreen) {
    if (_currentPosition == null) return const SizedBox();

    final nearby = _popularPlaces
        .map((place) {
          final distance =
              _calculateHaversineDistance(_currentPosition!, place.position);
          return (place: place, distance: distance);
        })
        .where((item) => item.distance < 200)
        .toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));

    if (nearby.isEmpty) {
      return const Text('No temples found nearby');
    }

    return Column(
      children: nearby.take(3).map((item) {
        return Card(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 6 : 8),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
          ),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
              decoration: BoxDecoration(
                color: const Color(0xFF00B14F).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                item.place.type == PlaceType.temple
                    ? Icons.temple_hindu
                    : Icons.landscape,
                color: const Color(0xFF00B14F),
                size: isSmallScreen ? 18 : 20,
              ),
            ),
            title: Text(
              item.place.name,
              style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
            ),
            subtitle: Text(
              '${item.distance.toStringAsFixed(1)} km away',
              style: TextStyle(fontSize: isSmallScreen ? 12 : 13),
            ),
            trailing: ElevatedButton(
              onPressed: () => _navigateToPlace(item.place),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B14F),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 10 : 12,
                  vertical: isSmallScreen ? 4 : 6,
                ),
                minimumSize: Size.zero,
              ),
              child: Text(
                'Go',
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: Colors.white,
                ),
              ),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: isSmallScreen ? 4 : 8,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuickNavCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 600;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B14F).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00B14F).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF00B14F),
                    size: isSmallScreen ? 20 : 24,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF00B14F),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeatureItem(String text, IconData icon, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 4 : 6),
      child: Row(
        children: [
          Icon(icon,
              color: const Color(0xFF00B14F), size: isSmallScreen ? 18 : 20),
          SizedBox(width: isSmallScreen ? 10 : 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 15,
                color: const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 600;

        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isSmallScreen ? 10 : 12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 5 : 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00B14F).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  color: const Color(0xFF00B14F),
                  size: isSmallScreen ? 18 : 20,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentAddress,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_currentPosition != null && !_isLoadingLocation)
                      Text(
                        "GPS: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}",
                        style: TextStyle(
                          fontSize: isSmallScreen ? 9 : 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (_isLoadingLocation)
                SizedBox(
                  width: isSmallScreen ? 14 : 16,
                  height: isSmallScreen ? 14 : 16,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF00B14F),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(2),
            child: Image.asset(
              'assets/ssa-logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _getAppBarTitle(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF00B14F),
      elevation: 4,
      iconTheme: const IconThemeData(color: Colors.white),
      centerTitle: true,
      actions: _buildAppBarActions(),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_currentIndex == 0) {
      return [
        IconButton(
          icon: const Icon(Icons.notifications_none, size: 26),
          onPressed: () {},
          color: Colors.white,
        ),
        IconButton(
          icon: const Icon(Icons.refresh, size: 24),
          onPressed: _refreshLocation,
          tooltip: 'Refresh Location',
          color: Colors.white,
        ),
        const SizedBox(width: 8),
      ];
    } else {
      return [
        IconButton(
          icon: const Icon(Icons.notifications_none, size: 26),
          onPressed: () {},
          color: Colors.white,
        ),
        const SizedBox(width: 8),
      ];
    }
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Home';
      case 1:
        return 'Book Ride';
      case 2:
        return 'Wallet';
      case 3:
        return 'Profile';
      default:
        return 'TN Travel Guide';
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF00B14F),
          unselectedItemColor: Colors.grey.shade600,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_car_outlined),
              activeIcon: Icon(Icons.directions_car),
              label: 'Booking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// New data models
enum PlaceType { temple, tourist }

class TouristPlace {
  final String id;
  final String name;
  final LatLng position;
  final PlaceType type;
  final String description;
  final int distanceKm;
  double? currentDistance;

  TouristPlace({
    required this.id,
    required this.name,
    required this.position,
    required this.type,
    required this.description,
    required this.distanceKm,
    this.currentDistance,
  });
}
