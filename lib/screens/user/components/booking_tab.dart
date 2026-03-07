// lib/screens/user/components/booking_tab.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ssatravels_app/services/booking_service.dart';
import 'package:ssatravels_app/services/toll_service.dart';
import 'package:ssatravels_app/services/route_service.dart';
import 'package:ssatravels_app/screens/user/components/place_search_widget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class BookingTab extends StatefulWidget {
  final Color themeColor;

  const BookingTab({super.key, this.themeColor = const Color(0xFF00C853)});

  @override
  State<BookingTab> createState() => _BookingTabState();
}

class _BookingTabState extends State<BookingTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        Expanded(
          child: OutstationCabBookingScreen(themeColor: widget.themeColor),
        ),
      ],
    );
  }
}

class OutstationCabBookingScreen extends StatefulWidget {
  final Color themeColor;

  const OutstationCabBookingScreen(
      {super.key, this.themeColor = const Color(0xFF00C853)});

  @override
  State<OutstationCabBookingScreen> createState() =>
      _OutstationCabBookingScreenState();
}

class _OutstationCabBookingScreenState extends State<OutstationCabBookingScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ========== SERVICES ==========
  final BookingService _bookingService = BookingService();
  final TollService _tollService = TollService();
  late final RouteService _routeService;
  late PolylinePoints polylinePoints;

  // 🔥 TRACK INITIALIZATION STATE
  bool _isInitialized = false;

  // ========== CONTROLLERS ==========
  final TextEditingController _minutesInputController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _customerEmailController =
      TextEditingController();
  final TextEditingController _specialInstructionsController =
      TextEditingController();
  final TextEditingController _vehicleNumberController =
      TextEditingController();

  // ========== DATE & TIME ==========
  DateTime _pickupDate = DateTime.now();
  TimeOfDay _pickupTime = TimeOfDay.now();
  DateTime? _returnDate;

  // ========== VEHICLE SELECTION ==========
  String? _selectedVehicleType;
  String? _selectedModel;
  List<Map<String, dynamic>> _vehicleTypes = [];
  Map<String, Map<String, dynamic>> _rateCard = {};
  List<String> _availableModels = [];

  // ========== PASSENGER DETAILS ==========
  int _adults = 1;
  int _children = 0;
  int _luggage = 0;

  // ========== DISTANCE & FARE ==========
  double _distance = 0.0;
  double _totalFare = 0.0;
  double _tollCharges = 0.0;
  double _kmCharges = 0.0;
  double _driverAllowance = 0.0;
  double _driverFoodCharges = 0.0;
  double _nightHaltCharges = 0.0;
  double _extraHourCharges = 0.0;
  double _extraKmCharges = 0.0;
  double _extraHourRate = 0.0;
  String _tollInfo = "Select vehicle for toll calculation";
  bool _tollCalculated = false;
  List<Map<String, dynamic>> _tollDetails = [];

  // ========== TRIP DURATION ==========
  int _tripDurationMinutes = 0;
  int _tripDurationHours = 0;
  int _estimatedTripMinutes = 0;
  int _baseHours = 8;
  int _selectedHours = 8;
  int _selectedMinutes = 0;
  bool _isManualHours = true;
  int _extraHours = 0;
  bool _showExtraHoursWarning = false;
  String _extraHoursMessage = '';

  // ========== FLAGS ==========
  bool _isNightTravel = false;
  bool _isSaving = false;
  bool _loadingVehicles = false;
  bool _loadingData = false;
  bool _calculatingToll = false;
  bool _showRouteInfo = false;
  bool _isMapMoving = false;
  Timer? _mapMoveTimer;

  // ========== GOOGLE MAPS STATE ==========
  GoogleMapController? _mapController;
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng _center = const LatLng(9.5850, 77.9570);
  bool _isLoadingLocation = false;
  double _currentZoom = 14.0;
  CameraPosition? _lastCameraPosition;

  // ========== SEARCH FUNCTIONALITY ==========
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounceTimer;
  FocusNode _searchFocusNode = FocusNode();

  // ========== DATA STORAGE ==========
  List<String> _citySuggestions = [];
  final Map<String, LocationPoint> _cityCoordinates = {};

  // ========== TOLL MARKERS ==========
  List<Map<String, dynamic>> _tollMarkers = [];
  List<LatLng> _routePoints = [];
  LatLng? _temporarySelectedLatLng;
  bool _isPickupSelection = true;

  // ========== ROUTE INFO ==========
  String _routeDuration = '';
  String _routeDistance = '';
  List<Map<String, dynamic>> _routeSteps = [];

  // ========== POLYLINE DECODING ==========
  List<LatLng> _decodedPolylinePoints = [];

  // ========== API KEYS ==========
  String _googleMapsApiKey = '';

  // WhatsApp number for sharing booking details
  final String _whatsappNumber = '9751867879';

  // Animation controllers for smooth transitions
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _routeService = RouteService();
    polylinePoints = PolylinePoints();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Initialize immediately
    _initializeData();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _mapMoveTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pickupController.dispose();
    _dropController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _specialInstructionsController.dispose();
    _vehicleNumberController.dispose();
    _fadeController.dispose();

    if (_mapController != null) {
      try {
        _mapController!.dispose();
      } catch (e) {
        print('Map controller dispose error: $e');
      }
    }

    super.dispose();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    print('📦 Initializing data...');

    setState(() {
      _isInitialized = true;
    });

    await _initializeApiKeys();
    await _loadCitySuggestions();
    await _loadVehicleData();

    if (mounted) {
      _checkNightTravel();
      await _setDefaultLocation();
      _fadeController.forward();
    }

    print('✅ Data initialized successfully!');
  }

  Future<void> _initializeApiKeys() async {
    try {
      await dotenv.load(fileName: ".env");
      _googleMapsApiKey = dotenv.get('GOOGLE_MAPS_API_KEY', fallback: '');
    } catch (e) {
      print('API key initialization error: $e');
    }
  }

  Future<void> _loadVehicleData() async {
    try {
      if (mounted) {
        setState(() => _loadingVehicles = true);
      }

      _vehicleTypes.clear();
      _rateCard.clear();

      try {
        final modelsSnapshot = await _firestore
            .collection('vehicleModels')
            .where('isActive', isEqualTo: true)
            .get();

        if (modelsSnapshot.docs.isNotEmpty) {
          for (var doc in modelsSnapshot.docs) {
            try {
              Map<String, dynamic> data = doc.data();
              String vehicleType = doc.id;
              String displayName = data['vehicleType'] ?? vehicleType;
              int seatingCapacity = data['seatingCapacity'] ?? 4;
              List<String> models = List<String>.from(data['models'] ?? []);

              _vehicleTypes.add({
                'id': vehicleType,
                'displayName': displayName,
                'seatingCapacity': seatingCapacity,
                'models': models,
              });
            } catch (e) {
              print('Error parsing vehicle model: $e');
            }
          }
        }
      } catch (e) {
        print('Error loading vehicle models: $e');
      }

      try {
        final vehiclesSnapshot = await _firestore
            .collection('vehicles')
            .where('isActive', isEqualTo: true)
            .get();

        if (vehiclesSnapshot.docs.isNotEmpty) {
          for (var doc in vehiclesSnapshot.docs) {
            try {
              Map<String, dynamic> vehicleData = doc.data();
              String vehicleId = doc.id;

              _rateCard[vehicleId] = {
                'below200': vehicleData['below200'] ?? {},
                'above200': vehicleData['above200'] ?? {},
              };
            } catch (e) {
              print('Error parsing rate card: $e');
            }
          }
        }
      } catch (e) {
        print('Error loading rate card: $e');
      }

      if (_vehicleTypes.isEmpty) {
        _useFallbackVehicleData();
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Vehicle data loading error: $e');
      _useFallbackVehicleData();
    } finally {
      if (mounted) {
        setState(() => _loadingVehicles = false);
      }
    }
  }

  void _useFallbackVehicleData() {
    _vehicleTypes = [
      {
        'id': 'hatchback',
        'displayName': 'Hatchback',
        'seatingCapacity': 5,
        'models': [
          'Tata Tiago',
          'Swift Dzire',
          'Hyundai Santro',
          'Tata Zest',
        ],
      },
      {
        'id': 'sedan',
        'displayName': 'Sedan',
        'seatingCapacity': 5,
        'models': ['Honda City', 'Toyota Yaris', 'Hyundai Verna'],
      },
      {
        'id': 'innova',
        'displayName': 'Innova',
        'seatingCapacity': 7,
        'models': [
          'Toyota Innova Crysta',
          'Toyota Innova',
        ],
      },
      {
        'id': 'ertiga',
        'displayName': 'Ertiga',
        'seatingCapacity': 7,
        'models': ['Maruti Ertiga', 'Maruti Ertiga ZXI'],
      },
    ];

    _rateCard = {
      'hatchback': {
        'below200': {
          'perKm': 9.0,
          'driverFood': 100.0,
          'nightHalt': 100.0,
          'minHours': 8,
          'extraHourRate': 100.0
        },
        'above200': {
          'perKm': 10.0,
          'driverAllowance': 300.0,
          'driverFood': 100.0,
          'nightHalt': 100.0,
          'extraHourRate': 100.0
        },
      },
      'sedan': {
        'below200': {
          'perKm': 9.0,
          'driverFood': 100.0,
          'nightHalt': 100.0,
          'minHours': 8,
          'extraHourRate': 100.0
        },
        'above200': {
          'perKm': 11.0,
          'driverAllowance': 300.0,
          'driverFood': 100.0,
          'nightHalt': 100.0,
          'extraHourRate': 100.0
        },
      },
      'innova': {
        'below200': {
          'perKm': 12.0,
          'driverFood': 100.0,
          'nightHalt': 100.0,
          'minHours': 8,
          'extraHourRate': 150.0
        },
        'above200': {
          'perKm': 15.0,
          'driverAllowance': 300.0,
          'driverFood': 100.0,
          'nightHalt': 100.0,
          'extraHourRate': 150.0
        },
      },
    };
  }

  Future<void> _loadCitySuggestions() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/city_suggestions.json');
      final Map<String, dynamic> jsonData = jsonDecode(jsonString);

      if (jsonData.containsKey('cities') && jsonData['cities'] is List) {
        List<dynamic> citiesList = jsonData['cities'];

        if (mounted) {
          setState(() {
            _citySuggestions.clear();
            _cityCoordinates.clear();

            for (var cityData in citiesList) {
              if (cityData is Map<String, dynamic>) {
                String cityName = cityData['name'] ?? '';
                double lat = (cityData['latitude'] as num?)?.toDouble() ?? 0.0;
                double lng = (cityData['longitude'] as num?)?.toDouble() ?? 0.0;

                if (cityName.isNotEmpty && lat != 0.0 && lng != 0.0) {
                  _citySuggestions.add(cityName);
                  _cityCoordinates[cityName] = LocationPoint(lat, lng);
                }
              }
            }

            _citySuggestions.sort();
          });
        }
      } else {
        _useFallbackCitySuggestions();
      }
    } catch (e) {
      print('City suggestions loading error: $e');
      _useFallbackCitySuggestions();
    }
  }

  void _useFallbackCitySuggestions() {
    final fallbackCities = {
      'Chennai, Tamil Nadu': LocationPoint(13.0827, 80.2707),
      'Coimbatore, Tamil Nadu': LocationPoint(11.0168, 76.9558),
      'Madurai, Tamil Nadu': LocationPoint(9.9252, 78.1198),
      'Trichy, Tamil Nadu': LocationPoint(10.7905, 78.7047),
      'Salem, Tamil Nadu': LocationPoint(11.6643, 78.1460),
      'Bengaluru, Karnataka': LocationPoint(12.9716, 77.5946),
      'Kochi, Kerala': LocationPoint(9.9312, 76.2673),
    };

    if (mounted) {
      setState(() {
        _citySuggestions = fallbackCities.keys.toList();
        _cityCoordinates.addAll(fallbackCities);
      });
    }
  }

  LatLng? _getCityCoordinates(String cityName) {
    if (_cityCoordinates.containsKey(cityName)) {
      final point = _cityCoordinates[cityName];
      if (point != null) {
        return LatLng(point.lat, point.lng);
      }
    }
    return null;
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty || query.length < 2) {
      if (mounted) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });
      }
      return;
    }

    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        if (mounted) {
          setState(() => _isSearching = true);
        }

        List<Map<String, dynamic>> allResults = [];

        if (_googleMapsApiKey.isNotEmpty) {
          try {
            final String url =
                'https://maps.googleapis.com/maps/api/place/autocomplete/json'
                '?input=$query'
                '&components=country:in'
                '&key=$_googleMapsApiKey';

            final response = await http.get(Uri.parse(url));

            if (response.statusCode == 200) {
              final data = json.decode(response.body);

              if (data['status'] == 'OK' && data['predictions'] != null) {
                for (var prediction in data['predictions']) {
                  allResults.add({
                    'name': prediction['structured_formatting']['main_text'] ??
                        prediction['description'].split(',').first,
                    'address': prediction['description'],
                    'place_id': prediction['place_id'],
                    'type': 'google_places',
                  });
                }
              }
            }
          } catch (e) {
            print('Places API error: $e');
          }
        }

        final queryLower = query.toLowerCase();
        for (var city in _citySuggestions) {
          if (city.toLowerCase().contains(queryLower)) {
            LatLng? coordinates = _getCityCoordinates(city);
            if (coordinates != null) {
              allResults.add({
                'name': city.split(',').first,
                'address': city,
                'lat': coordinates.latitude,
                'lng': coordinates.longitude,
                'type': 'json_city',
              });
            }
          }
        }

        final uniqueResults = <Map<String, dynamic>>[];
        final seenAddresses = <String>{};

        for (var result in allResults) {
          final address = result['address'] ?? '';
          if (!seenAddresses.contains(address)) {
            seenAddresses.add(address);
            uniqueResults.add(result);
          }
        }

        if (mounted) {
          setState(() {
            _searchResults = uniqueResults.take(10).toList();
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _searchResults = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    if (_googleMapsApiKey.isEmpty) return null;

    try {
      final String url =
          'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=name,formatted_address,geometry'
          '&key=$_googleMapsApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'];
          final location = result['geometry']['location'];

          return {
            'name': result['name'] ?? '',
            'address': result['formatted_address'] ?? '',
            'lat': location['lat'],
            'lng': location['lng'],
          };
        }
      }
    } catch (e) {
      print('Place details error: $e');
    }
    return null;
  }

  Future<void> _onPlaceSelected(
      Map<String, dynamic> place, bool isPickup) async {
    if (place.isEmpty) return;

    try {
      if (mounted) {
        setState(() {
          _isLoadingLocation = true;
          _searchResults.clear();
          _searchController.clear();
          _searchFocusNode.unfocus();
        });
      }

      LatLng? selectedLatLng;
      String displayText = place['address'] ?? place['name'] ?? '';

      if (place['type'] == 'google_places' && place.containsKey('place_id')) {
        final details = await _getPlaceDetails(place['place_id']);
        if (details != null) {
          selectedLatLng = LatLng(details['lat'], details['lng']);
          displayText = details['address'] ?? details['name'] ?? displayText;
        }
      } else if (place.containsKey('lat') && place.containsKey('lng')) {
        selectedLatLng = LatLng(place['lat'], place['lng']);
        displayText = place['address'] ?? place['name'] ?? '';
      }

      if (selectedLatLng == null) {
        try {
          final locations = await locationFromAddress(displayText);
          if (locations.isNotEmpty) {
            selectedLatLng =
                LatLng(locations.first.latitude, locations.first.longitude);
          }
        } catch (e) {
          print('Geocoding error: $e');
        }
      }

      if (selectedLatLng == null) {
        throw Exception('Could not get coordinates');
      }

      if (isPickup) {
        _pickupLatLng = selectedLatLng;
        _pickupController.text = displayText;
      } else {
        _dropLatLng = selectedLatLng;
        _dropController.text = displayText;
      }

      if (mounted) {
        setState(() {
          _temporarySelectedLatLng = null;
          _isLoadingLocation = false;
        });
      }

      _updateMarkers();

      if (_mapController != null && mounted) {
        await _moveCameraToLocation(selectedLatLng, zoom: 16.0);
      }

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      _showSnackBar(
        '${isPickup ? 'Pickup' : 'Drop'} location set',
        widget.themeColor,
      );

      if (_pickupLatLng != null && _dropLatLng != null) {
        await _fetchRealRoadRoute();
      }
    } catch (e) {
      _showSnackBar('Error: Could not set location', Colors.orange);
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _fetchRealRoadRoute() async {
    if (_pickupLatLng == null || _dropLatLng == null) return;

    if (mounted) {
      setState(() {
        _loadingData = true;
        _showRouteInfo = false;
        _routePoints.clear();
        _polylines.clear();
      });
    }

    try {
      if (_googleMapsApiKey.isEmpty) {
        _useFallbackRoute();
        return;
      }

      final String origin =
          '${_pickupLatLng!.latitude},${_pickupLatLng!.longitude}';
      final String destination =
          '${_dropLatLng!.latitude},${_dropLatLng!.longitude}';

      final String url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=$origin'
          '&destination=$destination'
          '&mode=driving'
          '&alternatives=true'
          '&key=$_googleMapsApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          _distance = leg['distance']['value'] / 1000.0;
          _routeDistance = leg['distance']['text'];
          _routeDuration = leg['duration']['text'];

          _tripDurationMinutes = leg['duration']['value'] ~/ 60;
          _tripDurationHours = (_tripDurationMinutes / 60).ceil();
          _estimatedTripMinutes = _tripDurationMinutes;

          final points = route['overview_polyline']['points'];
          _routePoints = _decodePolyline(points);

          _routeSteps = [];
          for (var step in leg['steps']) {
            _routeSteps.add({
              'instruction': _stripHtmlTags(step['html_instructions']),
              'distance': step['distance']['text'],
              'duration': step['duration']['text'],
            });
          }

          _calculateExtraHours();

          if (mounted) {
            setState(() {
              _showRouteInfo = true;
              _loadingData = false;
            });
          }

          _updateMarkers();
          _updateRoutePolyline();

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _mapController != null && _routePoints.isNotEmpty) {
              _fitCameraToRoute();
            }
          });

          _showSnackBar(
            'Route loaded: $_routeDistance • $_routeDuration',
            Colors.green,
          );
        } else {
          throw Exception('Directions API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Route fetch error: $e');
      _useFallbackRoute();

      if (mounted) {
        setState(() => _loadingData = false);
      }
    }
  }

  void _calculateExtraHours() {
    if (_selectedVehicleType == null) return;

    var carRates = _rateCard[_selectedVehicleType];
    if (carRates == null) return;

    double effectiveDistance = _getEffectiveDistanceForCharges();
    bool isBelow200 = effectiveDistance <= 200;
    var rateData = isBelow200 ? carRates['below200'] : carRates['above200'];

    if (rateData == null) return;

    _baseHours = rateData['minHours'] ?? 8;
    _extraHourRate = (rateData['extraHourRate'] as num?)?.toDouble() ?? 0.0;

    int userSelectedMinutes = (_selectedHours * 60) + _selectedMinutes;

    if (userSelectedMinutes > _tripDurationMinutes) {
      _extraHours = ((userSelectedMinutes - _tripDurationMinutes) / 60).ceil();
      _extraHoursMessage =
          '⚠️ Extended trip duration: $_extraHours extra hours will be charged at ₹$_extraHourRate/hour';
      _showExtraHoursWarning = true;

      // Calculate extra hour charges
      _extraHourCharges = _extraHours * _extraHourRate;
    } else {
      _extraHours = 0;
      _extraHourCharges = 0.0;
      _showExtraHoursWarning = false;
      _extraHoursMessage = '';
    }

    _calculateFare();
  }

  double _getEffectiveDistanceForCharges() {
    return _distance;
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

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }

  String _stripHtmlTags(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  void _updateRoutePolyline() {
    if (_routePoints.isEmpty) return;

    final newPolylines = Set<Polyline>.from(_polylines.where((p) =>
        p.polylineId.value != 'route' && p.polylineId.value != 'route_glow'));

    newPolylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: Colors.blue,
        width: 5,
        jointType: JointType.round,
        geodesic: true,
      ),
    );

    newPolylines.add(
      Polyline(
        polylineId: const PolylineId('route_glow'),
        points: _routePoints,
        color: Colors.blue.withOpacity(0.3),
        width: 9,
        visible: true,
        geodesic: true,
      ),
    );

    if (mounted) {
      setState(() {
        _polylines = newPolylines;
      });
    }
  }

  void _useFallbackRoute() {
    if (_pickupLatLng == null || _dropLatLng == null) return;

    double distance = Geolocator.distanceBetween(
          _pickupLatLng!.latitude,
          _pickupLatLng!.longitude,
          _dropLatLng!.latitude,
          _dropLatLng!.longitude,
        ) /
        1000;

    distance = distance * 1.3;
    int minutes = (distance * 1.5).round();
    String duration =
        minutes >= 60 ? '${minutes ~/ 60}h ${minutes % 60}m' : '${minutes}m';

    if (mounted) {
      setState(() {
        _distance = distance;
        _routeDuration = duration;
        _routeDistance = '${distance.toStringAsFixed(1)} km';
        _routePoints = _generateFallbackRoutePoints();
        _tripDurationMinutes = minutes;
        _tripDurationHours = (minutes / 60).ceil();
        _estimatedTripMinutes = minutes;
      });
    }

    _calculateExtraHours();
    _updateMarkers();
    _updateRoutePolyline();
  }

  List<LatLng> _generateFallbackRoutePoints() {
    List<LatLng> points = [];
    if (_pickupLatLng == null || _dropLatLng == null) return points;

    points.add(_pickupLatLng!);
    int steps = 20;

    for (int i = 1; i < steps; i++) {
      double t = i / steps;
      double lat = _pickupLatLng!.latitude +
          (_dropLatLng!.latitude - _pickupLatLng!.latitude) * t;
      double lng = _pickupLatLng!.longitude +
          (_dropLatLng!.longitude - _pickupLatLng!.longitude) * t;

      double offset = math.sin(t * math.pi) * 0.05;
      lat += offset;
      lng += offset * 0.5;

      points.add(LatLng(lat, lng));
    }

    points.add(_dropLatLng!);
    return points;
  }

  void _updateMarkers() {
    final newMarkers = <Marker>{};

    if (_pickupLatLng != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: _pickupController.text.isNotEmpty
                ? _pickupController.text
                : 'Pickup point',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    if (_dropLatLng != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: _dropLatLng!,
          infoWindow: InfoWindow(
            title: 'Drop Location',
            snippet: _dropController.text.isNotEmpty
                ? _dropController.text
                : 'Drop point',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    if (_temporarySelectedLatLng != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('temp_selection'),
          position: _temporarySelectedLatLng!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _isPickupSelection
                ? BitmapDescriptor.hueAzure
                : BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: _isPickupSelection ? 'Select Pickup' : 'Select Drop',
            snippet: 'Tap confirm to set',
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  void _fitCameraToRoute() {
    if (_mapController == null) return;
    if (_pickupLatLng == null || _dropLatLng == null) return;

    try {
      if (_routePoints.isNotEmpty) {
        double minLat = _routePoints.first.latitude;
        double maxLat = _routePoints.first.latitude;
        double minLng = _routePoints.first.longitude;
        double maxLng = _routePoints.first.longitude;

        for (var point in _routePoints) {
          minLat = math.min(minLat, point.latitude);
          maxLat = math.max(maxLat, point.latitude);
          minLng = math.min(minLng, point.longitude);
          maxLng = math.max(maxLng, point.longitude);
        }

        double latPadding = (maxLat - minLat) * 0.2;
        double lngPadding = (maxLng - minLng) * 0.2;

        if (latPadding < 0.05) latPadding = 0.05;
        if (lngPadding < 0.05) lngPadding = 0.05;

        LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(minLat - latPadding, minLng - lngPadding),
          northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
        );

        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50),
        );
      }
    } catch (e) {
      print('Camera fit error: $e');
    }
  }

  Widget _buildMapSelectionSheet(bool isPickup) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.themeColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isPickup
                            ? 'Select Pickup Location'
                            : 'Select Drop Location',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: isPickup
                              ? 'Search pickup location...'
                              : 'Search drop location...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _isSearching
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear,
                                          color: Colors.grey),
                                      onPressed: () {
                                        setState(() {
                                          _searchController.clear();
                                          _searchResults.clear();
                                        });
                                      },
                                    )
                                  : null,
                        ),
                        onChanged: (value) {
                          _searchLocation(value);
                        },
                      ),
                    ),
                    if (_searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final result = _searchResults[index];
                            return GestureDetector(
                              onTap: () {
                                _onPlaceSelected(result, isPickup);
                              },
                              child: ListTile(
                                leading: Icon(
                                  result['type'] == 'google_places'
                                      ? Icons.place
                                      : Icons.location_city,
                                  color: widget.themeColor,
                                ),
                                title: Text(
                                  result['name'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  result['address'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _center,
                        zoom: _currentZoom,
                      ),
                      onMapCreated: (GoogleMapController controller) {
                        _mapController = controller;
                        if (_routePoints.isNotEmpty) {
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (mounted) {
                              _fitCameraToRoute();
                            }
                          });
                        }
                      },
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      compassEnabled: true,
                      mapToolbarEnabled: false,
                      onTap: (latLng) => _onMapTap(latLng, isPickup),
                      onCameraMove: (position) {
                        setState(() {
                          _currentZoom = position.zoom;
                          _center = position.target;
                          _isMapMoving = true;
                        });

                        _mapMoveTimer?.cancel();
                        _mapMoveTimer =
                            Timer(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            setState(() {
                              _isMapMoving = false;
                            });
                            _getAddressForCenter(isPickup);
                          }
                        });
                      },
                      onCameraIdle: () {
                        if (mounted) {
                          setState(() {
                            _isMapMoving = false;
                          });
                        }
                      },
                      mapType: MapType.normal,
                      minMaxZoomPreference:
                          const MinMaxZoomPreference(3.0, 20.0),
                      gestureRecognizers: const <Factory<
                          OneSequenceGestureRecognizer>>{
                        Factory<OneSequenceGestureRecognizer>(
                            EagerGestureRecognizer.new),
                      },
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_pin,
                            color: isPickup ? Colors.green : Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 4),
                          if (!_isMapMoving)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                isPickup ? 'Pickup' : 'Drop',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isPickup ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_isMapMoving)
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Move map to select location...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 16,
                      bottom: 100,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(Icons.add, color: widget.themeColor),
                              onPressed: _zoomIn,
                              iconSize: 24,
                              splashRadius: 24,
                              tooltip: 'Zoom In',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon:
                                  Icon(Icons.remove, color: widget.themeColor),
                              onPressed: _zoomOut,
                              iconSize: 24,
                              splashRadius: 24,
                              tooltip: 'Zoom Out',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 100,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Zoom: ${_currentZoom.toStringAsFixed(1)}x',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: ElevatedButton(
                        onPressed: _temporarySelectedLatLng == null
                            ? null
                            : _saveSelectedLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _temporarySelectedLatLng == null
                              ? Colors.grey.shade400
                              : widget.themeColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                          elevation: 3,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              'Confirm ${isPickup ? 'Pickup' : 'Drop'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getAddressForCenter(bool isPickup) async {
    if (_temporarySelectedLatLng == null) return;

    try {
      String address =
          await _routeService.getAddressFromLatLng(_temporarySelectedLatLng!);

      if (mounted && address.isNotEmpty) {
        setState(() {
          _searchController.text = address;
        });
      }
    } catch (e) {
      print('Address fetch error: $e');
    }
  }

  Future<void> _onMapTap(LatLng latLng, bool isPickup) async {
    try {
      setState(() {
        _temporarySelectedLatLng = latLng;
        _isPickupSelection = isPickup;
        _isLoadingLocation = true;
      });

      String address = await _routeService.getAddressFromLatLng(latLng);

      if (mounted) {
        setState(() {
          _searchController.text = address;
          _isLoadingLocation = false;
        });
      }

      _updateMarkers();
      await _moveCameraToLocation(latLng, zoom: 16.0);
    } catch (e) {
      if (mounted) {
        setState(() {
          _searchController.text =
              '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}';
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _saveSelectedLocation() async {
    if (_temporarySelectedLatLng == null) {
      _showSnackBar('Please select a location first', Colors.orange);
      return;
    }

    try {
      setState(() => _isLoadingLocation = true);

      String address = _searchController.text;
      bool isCoordinates = RegExp(r'^\d+\.\d+,\s*\d+\.\d+$').hasMatch(address);

      if (address.isEmpty || isCoordinates) {
        address =
            await _routeService.getAddressFromLatLng(_temporarySelectedLatLng!);
      }

      if (_isPickupSelection) {
        _pickupLatLng = _temporarySelectedLatLng;
        _pickupController.text = address;
      } else {
        _dropLatLng = _temporarySelectedLatLng;
        _dropController.text = address;
      }

      if (mounted) {
        setState(() {
          _temporarySelectedLatLng = null;
          _searchController.clear();
          _isLoadingLocation = false;
        });
      }

      _updateMarkers();
      Navigator.pop(context);

      _showSnackBar(
        '${_isPickupSelection ? 'Pickup' : 'Drop'} location saved',
        widget.themeColor,
      );

      if (_pickupLatLng != null && _dropLatLng != null) {
        await _fetchRealRoadRoute();
      }
    } catch (e) {
      _showSnackBar('Error saving location', Colors.orange);
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _setDefaultLocation() async {
    if (mounted) {
      setState(() {
        _center = const LatLng(9.5850, 77.9570);
        _pickupLatLng = _center;
        _pickupController.text = 'Virudhunagar, Tamil Nadu';
      });
    }
    _updateMarkers();
    await _moveCameraToLocation(_center);
    _showSnackBar('Default location set as pickup', widget.themeColor);
  }

  Future<void> _zoomIn() async {
    try {
      if (_mapController != null) {
        double newZoom = _currentZoom + 1;
        if (newZoom <= 20) {
          await _mapController!.animateCamera(CameraUpdate.zoomTo(newZoom));
          if (mounted) {
            setState(() => _currentZoom = newZoom);
          }
          HapticFeedback.lightImpact();
        }
      }
    } catch (e) {
      print('Zoom in error: $e');
    }
  }

  Future<void> _zoomOut() async {
    try {
      if (_mapController != null) {
        double newZoom = _currentZoom - 1;
        if (newZoom >= 3) {
          await _mapController!.animateCamera(CameraUpdate.zoomTo(newZoom));
          if (mounted) {
            setState(() => _currentZoom = newZoom);
          }
          HapticFeedback.lightImpact();
        }
      }
    } catch (e) {
      print('Zoom out error: $e');
    }
  }

  Future<void> _moveCameraToLocation(LatLng location,
      {double zoom = 15.0}) async {
    try {
      if (_mapController == null) {
        if (mounted) {
          setState(() {
            _center = location;
            _currentZoom = zoom;
          });
        }
        return;
      }

      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: location,
            zoom: zoom,
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _center = location;
          _currentZoom = zoom;
        });
      }
    } catch (e) {
      print('Camera move error: $e');
    }
  }

  void _showMapSelection(bool isPickup) {
    try {
      if (mounted) {
        setState(() {
          _isPickupSelection = isPickup;
          _temporarySelectedLatLng = null;
          _searchController.clear();
          _searchResults.clear();
          _showRouteInfo = false;
        });
      }

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildMapSelectionSheet(isPickup),
      );
    } catch (e) {
      print('Map selection error: $e');
    }
  }

  Future<void> _calculateDistanceAndToll() async {
    if (_pickupLatLng == null || _dropLatLng == null) {
      _showSnackBar('Please select both locations', Colors.orange);
      return;
    }

    if (mounted) {
      setState(() {
        _calculatingToll = true;
        _showRouteInfo = false;
        _tollCalculated = false;
      });
    }

    try {
      await _fetchRealRoadRoute();

      final tollResult = await _tollService.calculateToll(
        source: _pickupController.text,
        destination: _dropController.text,
      );

      if (mounted) {
        setState(() {
          if (tollResult['success'] == true) {
            _tollCharges = tollResult['totalAmount'] ?? 0.0;
            _tollDetails =
                List<Map<String, dynamic>>.from(tollResult['plazas'] ?? []);
            _tollInfo =
                '${_tollDetails.length} toll plaza(s) • ₹${_tollCharges.toStringAsFixed(0)}';
            _tollCalculated = true;
          } else {
            _tollCharges = 0.0;
            _tollDetails = [];
            _tollInfo = tollResult['message'] ?? 'No toll plazas found';
            _tollCalculated = false;
          }
        });
      }

      _calculateFare();

      _showSnackBar(
        'Route: $_routeDistance • $_routeDuration',
        widget.themeColor,
      );
    } catch (e) {
      print('Calculation error: $e');
      _showSnackBar('Error calculating route', Colors.orange);
    } finally {
      if (mounted) {
        setState(() => _calculatingToll = false);
      }
    }
  }

  void _calculateFare() {
    if (_selectedVehicleType == null) {
      if (mounted) {
        setState(() => _totalFare = 0);
      }
      return;
    }

    var carRates = _rateCard[_selectedVehicleType];
    if (carRates == null) {
      if (mounted) {
        setState(() => _totalFare = 0);
      }
      return;
    }

    _kmCharges = 0.0;
    _driverAllowance = 0.0;
    _driverFoodCharges = 0.0;
    _nightHaltCharges = 0.0;
    _extraHourCharges = 0.0;
    _extraKmCharges = 0.0;
    double totalFare = 0.0;

    double effectiveDistance = _getEffectiveDistanceForCharges();
    bool isBelow200 = effectiveDistance <= 200;
    var rateData = isBelow200 ? carRates['below200'] : carRates['above200'];

    if (rateData == null) return;

    _kmCharges = effectiveDistance * (rateData['perKm'] ?? 0.0);

    if (!isBelow200 && rateData['driverAllowance'] != null) {
      _driverAllowance = rateData['driverAllowance'] as double;
    }

    if (rateData['driverFood'] != null) {
      _driverFoodCharges = rateData['driverFood'] as double;
    }

    if (_isNightTravel && rateData['nightHalt'] != null) {
      _nightHaltCharges = rateData['nightHalt'] as double;
    }

    // Calculate extra hour charges if applicable
    if (_extraHours > 0 && rateData['extraHourRate'] != null) {
      _extraHourCharges = _extraHours * (rateData['extraHourRate'] as double);
    }

    totalFare = _kmCharges +
        _driverAllowance +
        _driverFoodCharges +
        _nightHaltCharges +
        _tollCharges +
        _extraHourCharges +
        _extraKmCharges;

    if (mounted) {
      setState(() => _totalFare = totalFare);
    }
  }

  void _checkNightTravel() {
    if (mounted) {
      setState(() =>
          _isNightTravel = _pickupTime.hour >= 22 || _pickupTime.hour < 6);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.themeColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _pickupDate && mounted) {
      setState(() => _pickupDate = picked);
    }
  }

  Future<void> _selectReturnDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? _pickupDate.add(const Duration(days: 1)),
      firstDate: _pickupDate,
      lastDate: _pickupDate.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.themeColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _returnDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _pickupTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.themeColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteColor: widget.themeColor.withOpacity(0.1),
              hourMinuteTextColor: widget.themeColor,
              dialHandColor: widget.themeColor,
              dialBackgroundColor: widget.themeColor.withOpacity(0.1),
              dialTextColor: Colors.black,
              entryModeIconColor: widget.themeColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _pickupTime && mounted) {
      setState(() {
        _pickupTime = picked;
        _checkNightTravel();
      });
    }
  }

  List<String> _getModelsForSelectedVehicle() {
    if (_selectedVehicleType == null) return [];

    final vehicle = _vehicleTypes.firstWhere(
      (v) => v['id'] == _selectedVehicleType,
      orElse: () => {'models': <String>[]},
    );

    return List<String>.from(vehicle['models'] ?? []);
  }

  int _getSeatingCapacity(String vehicleType) {
    final vehicle = _vehicleTypes.firstWhere(
      (v) => v['id'] == vehicleType,
      orElse: () => {'seatingCapacity': 4},
    );
    return vehicle['seatingCapacity'] ?? 4;
  }

  Widget _buildHoursSelection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: widget.themeColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'SELECT DURATION',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hours',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedHours,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down,
                              color: widget.themeColor),
                          items: List.generate(24, (index) {
                            return DropdownMenuItem<int>(
                              value: index,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child:
                                    Text('$index hour${index != 1 ? 's' : ''}'),
                              ),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedHours = value;
                                _isManualHours = true;
                                _calculateExtraHours();
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Add this controller at the top with other controllers

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Minutes',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          // Minus button
                          IconButton(
                            icon: Icon(Icons.remove, color: widget.themeColor),
                            onPressed: () {
                              setState(() {
                                if (_selectedMinutes > 0) {
                                  _selectedMinutes = _selectedMinutes - 1;
                                  _calculateExtraHours();
                                }
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          // Minutes display
                          Expanded(
                            child: Text(
                              '$_selectedMinutes min',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Plus button
                          IconButton(
                            icon: Icon(Icons.add, color: widget.themeColor),
                            onPressed: () {
                              setState(() {
                                if (_selectedMinutes < 59) {
                                  _selectedMinutes = _selectedMinutes + 1;
                                  _calculateExtraHours();
                                }
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // Quick minute buttons
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [0, 15, 30, 36, 45, 46, 50, 55].map((min) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMinutes = min;
                              _calculateExtraHours();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _selectedMinutes == min
                                  ? widget.themeColor
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$min',
                              style: TextStyle(
                                fontSize: 11,
                                color: _selectedMinutes == min
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_extraHours > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Extra Hours: $_extraHours hour${_extraHours > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'Extra Charges: ₹${_extraHourCharges.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: widget.themeColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
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

  void _validateAndSaveBooking() {
    if (_customerNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter customer name', Colors.orange);
      return;
    }

    if (_customerPhoneController.text.trim().isEmpty) {
      _showSnackBar('Please enter customer phone number', Colors.orange);
      return;
    }

    if (_distance == 0) {
      _showSnackBar('Please calculate distance first', Colors.orange);
      return;
    }

    if (_selectedVehicleType == null) {
      _showSnackBar('Please select a vehicle type', Colors.orange);
      return;
    }

    if (_selectedHours == 0 && _selectedMinutes == 0) {
      _showSnackBar('Please select trip duration', Colors.orange);
      return;
    }

    // Return date is optional now - no validation needed

    _showBookingConfirmation();
  }

  void _showBookingConfirmation() {
    String durationText = _tripDurationHours > 0
        ? '$_tripDurationHours h (${_tripDurationMinutes} m)'
        : '${_tripDurationMinutes} m';

    String selectedDurationText = '$_selectedHours h $_selectedMinutes m';

    String billedDistance = '${_distance.toStringAsFixed(1)} km';

    String tripTypeText = _returnDate != null ? 'ROUND TRIP' : 'ONE WAY';
    String returnDateText = _returnDate != null
        ? 'Return: ${DateFormat('dd/MM/yyyy').format(_returnDate!)}'
        : 'Trip Type: One Way';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Booking'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${_customerNameController.text}'),
              const SizedBox(height: 8),
              Text('Phone: ${_customerPhoneController.text}'),
              const SizedBox(height: 8),
              Text('From: ${_pickupController.text}'),
              const SizedBox(height: 8),
              Text('To: ${_dropController.text}'),
              const SizedBox(height: 8),
              Text(
                  'Pickup: ${DateFormat('dd/MM/yyyy').format(_pickupDate)} at ${_pickupTime.format(context)}'),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(returnDateText),
              ),
              const SizedBox(height: 8),
              Text('Trip Type: $tripTypeText'),
              const SizedBox(height: 8),
              Text('Distance: $billedDistance'),
              Text('Est. Duration: $durationText'),
              Text('Selected Duration: $selectedDurationText',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (_tollCalculated)
                Text('Toll Charges: ₹${_tollCharges.toStringAsFixed(0)}'),
              if (_extraHours > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Extra Hours: $_extraHours h',
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Extra Charges: ₹${_extraHourCharges.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: widget.themeColor),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: widget.themeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Fare:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹${_totalFare.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.themeColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveBookingAndShareToWhatsApp();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.themeColor,
            ),
            child: const Text('Confirm & Share'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareToWhatsApp(String bookingId, double totalAmount) async {
    try {
      String durationText = _tripDurationHours > 0
          ? '$_tripDurationHours h (${_tripDurationMinutes} m)'
          : '${_tripDurationMinutes} m';

      String selectedDurationText = '$_selectedHours h $_selectedMinutes m';

      String extraHoursText = _extraHours > 0
          ? '\n*Extra Hours:* $_extraHours h (₹${_extraHourCharges.toStringAsFixed(0)})'
          : '';

      String billedDistance = '${_distance.toStringAsFixed(1)} km';

      String tripTypeText = _returnDate != null ? 'ROUND TRIP' : 'ONE WAY';
      String returnDateText = _returnDate != null
          ? '\n*Return:* ${DateFormat('dd/MM/yyyy').format(_returnDate!)}'
          : '';

      String message = '''
*🚗 SSA Travels - Booking Confirmation*

*Booking ID:* $bookingId
*Customer:* ${_customerNameController.text}
*Phone:* ${_customerPhoneController.text}
${_customerEmailController.text.isNotEmpty ? '*Email:* ${_customerEmailController.text}\n' : ''}

*📍 Trip Details*
*Type:* $tripTypeText
*From:* ${_pickupController.text}
*To:* ${_dropController.text}
*Pickup:* ${DateFormat('dd/MM/yyyy').format(_pickupDate)} at ${_pickupTime.format(context)}$returnDateText

*🚙 Vehicle Details*
*Type:* $_selectedVehicleType
*Model:* ${_selectedModel ?? 'Not specified'}

*⏱️ Trip Duration*
*Estimated Duration:* $durationText
*Selected Duration:* $selectedDurationText
*Distance:* $billedDistance$extraHoursText

*💰 Fare Details*
*Base Fare:* ₹${(_kmCharges + _driverAllowance + _driverFoodCharges + _nightHaltCharges).toStringAsFixed(0)}
${_tollCalculated ? '*Toll Charges:* ₹${_tollCharges.toStringAsFixed(0)}\n' : ''}${_extraHours > 0 ? '*Extra Hour Charges:* ₹${_extraHourCharges.toStringAsFixed(0)}\n' : ''}
*Total Fare:* ₹${totalAmount.toStringAsFixed(0)}

*👥 Passenger Details*
*Adults:* $_adults
*Children:* $_children
*Total:* ${_adults + _children}
*Luggage:* $_luggage

${_specialInstructionsController.text.isNotEmpty ? '*Special Instructions:* ${_specialInstructionsController.text}\n' : ''}

Thank you for choosing SSA Travels! 🎉
      ''';

      String encodedMessage = Uri.encodeComponent(message);
      String whatsappUrl =
          "https://wa.me/$_whatsappNumber?text=$encodedMessage";

      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl));
        _showSnackBar('Opening WhatsApp...', widget.themeColor);
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      print('WhatsApp share error: $e');
      _showSnackBar(
          'Could not open WhatsApp. Please install WhatsApp.', Colors.orange);

      await Clipboard.setData(ClipboardData(
          text:
              'Booking ID: $bookingId\nTotal: ₹${totalAmount.toStringAsFixed(0)}'));
      _showSnackBar('Booking ID copied to clipboard', Colors.blue);
    }
  }

  Future<void> _saveBookingAndShareToWhatsApp() async {
    try {
      if (mounted) {
        setState(() => _isSaving = true);
      }

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showSnackBar('Please login to book a ride', Colors.orange);
        return;
      }

      double baseFare = _kmCharges +
          _driverAllowance +
          _driverFoodCharges +
          _nightHaltCharges;
      int passengers = _adults + _children;

      DateTime travelDateTime = DateTime(
        _pickupDate.year,
        _pickupDate.month,
        _pickupDate.day,
        _pickupTime.hour,
        _pickupTime.minute,
      );

      print('📝 Creating booking with:');
      print('   From: ${_pickupController.text}');
      print('   To: ${_dropController.text}');
      print('   Vehicle: $_selectedVehicleType');
      print('   Base Fare: $baseFare');
      print('   Extra Hours: $_extraHours');
      print('   Extra Hour Charges: $_extraHourCharges');
      print('   Total Fare: $_totalFare');
      print('   Distance: $_distance km');
      print('   Trip Type: ${_returnDate != null ? "ROUND TRIP" : "ONE WAY"}');

      final result = await _bookingService.createBookingWithToll(
        fromLocation: _pickupController.text.trim(),
        toLocation: _dropController.text.trim(),
        travelDate: travelDateTime,
        vehicleType: _selectedVehicleType ?? 'sedan',
        vehicleNumber: _vehicleNumberController.text.trim().isEmpty
            ? 'Not specified'
            : _vehicleNumberController.text.trim(),
        passengers: passengers,
        baseFare: baseFare,
        paymentMethod: 'Cash',
        returnDate: _returnDate,
        adults: _adults,
        children: _children,
        luggage: _luggage,
        specialInstructions: _specialInstructionsController.text.trim(),
        tripType: _returnDate != null ? 'ROUND TRIP' : 'ONE WAY',
      );

      print('📦 Booking result: $result');

      if (result['success'] == true) {
        String bookingId = result['bookingId'];

        _showSnackBar(
          '✅ Booking confirmed! ID: $bookingId',
          widget.themeColor,
        );

        await _shareToWhatsApp(bookingId, _totalFare);

        _resetForm();
      } else {
        _showSnackBar(
          'Failed: ${result['message']}',
          Colors.red,
        );
      }
    } catch (e) {
      print('❌ Save booking error: $e');
      _showSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _randomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
      ),
    );
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _pickupController.clear();
        _dropController.clear();
        _customerNameController.clear();
        _customerPhoneController.clear();
        _customerEmailController.clear();
        _specialInstructionsController.clear();
        _vehicleNumberController.clear();
        _pickupDate = DateTime.now();
        _pickupTime = TimeOfDay.now();
        _returnDate = null;
        _selectedVehicleType = null;
        _selectedModel = null;
        _adults = 1;
        _children = 0;
        _luggage = 0;
        _distance = 0.0;
        _tollCharges = 0.0;
        _tollDetails = [];
        _tollCalculated = false;
        _totalFare = 0.0;
        _pickupLatLng = null;
        _dropLatLng = null;
        _routePoints.clear();
        _markers.clear();
        _polylines.clear();
        _tollMarkers.clear();
        _routeDuration = '';
        _routeDistance = '';
        _routeSteps.clear();
        _showRouteInfo = false;
        _tripDurationMinutes = 0;
        _tripDurationHours = 0;
        _selectedHours = 8;
        _selectedMinutes = 0;
        _isManualHours = true;
        _extraHours = 0;
        _extraHourCharges = 0.0;
        _showExtraHoursWarning = false;
        _extraHoursMessage = '';
        _checkNightTravel();
      });
    }

    _setDefaultLocation();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        widget.themeColor.withOpacity(0.1),
                        Colors.white
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.all(isMobile ? 12 : 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildLocationSection(isMobile),
                            const Divider(height: 0),
                            Padding(
                              padding: EdgeInsets.all(isMobile ? 16 : 20),
                              child: _buildHoursSelection(),
                            ),
                            const Divider(height: 0),
                            _buildDateTimeSection(isMobile),
                            const Divider(height: 0),
                            _buildVehicleTypeSection(isMobile),
                            if (_selectedVehicleType != null)
                              _buildVehicleModelsSection(isMobile),
                            const Divider(height: 0),
                            _buildFareSection(isMobile),
                            const Divider(height: 0),
                            _buildPassengerSection(isMobile),
                            const Divider(height: 0),
                            _buildCustomerDetailsSection(isMobile),
                          ],
                        ),
                      ),
                      _buildConfirmButton(isMobile),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              if (!_isInitialized)
                Container(
                  color: Colors.white.withOpacity(0.9),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading booking form...',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_showRouteInfo && _routeDuration.isNotEmpty && _distance > 0)
                _buildRouteInfoCard(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    String durationText = _tripDurationHours > 0
        ? '$_tripDurationHours h'
        : '${_tripDurationMinutes} m';

    String distanceText = '${_distance.toStringAsFixed(1)} km';

    String tripTypeText = _returnDate != null
        ? 'Round trip with return on ${DateFormat('dd/MM/yyyy').format(_returnDate!)}'
        : 'One way trip';

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Icon(Icons.directions_car,
                        color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fastest route',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.green),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              durationText,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_right_alt,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              distanceText,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey.shade800),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          tripTypeText,
                          style: TextStyle(
                              fontSize: 11,
                              color: widget.themeColor,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    if (mounted) {
                      setState(() => _showRouteInfo = false);
                    }
                  },
                ),
              ],
            ),
            if (_extraHours > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Extra $_extraHours h - ₹${_extraHourCharges.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: widget.themeColor),
              const SizedBox(width: 8),
              Text(
                'JOURNEY DETAILS',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _buildLocationField(
                title: 'PICKUP LOCATION',
                controller: _pickupController,
                isPickup: true,
                isMobile: isMobile,
              ),
              const SizedBox(height: 16),
              _buildLocationField(
                title: 'DROP LOCATION',
                controller: _dropController,
                isPickup: false,
                isMobile: isMobile,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _calculatingToll ? null : _calculateDistanceAndToll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _calculatingToll
                      ? Colors.grey.shade400
                      : widget.themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                  elevation: 3,
                ),
                child: _calculatingToll
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('CALCULATING...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.route, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'GET ROUTE & FARE',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
              if (_distance > 0 && !_showRouteInfo)
                _buildDistanceInfo(isMobile),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required String title,
    required TextEditingController controller,
    required bool isPickup,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showMapSelection(isPickup),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Text(
                      controller.text.isEmpty
                          ? 'Tap to select location'
                          : controller.text,
                      style: TextStyle(
                        color: controller.text.isEmpty
                            ? Colors.grey.shade500
                            : Colors.black87,
                        fontSize: isMobile ? 14 : 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.map, color: widget.themeColor),
                  onPressed: () => _showMapSelection(isPickup),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceInfo(bool isMobile) {
    String selectedText = _selectedHours > 0 || _selectedMinutes > 0
        ? 'Selected: $_selectedHours h $_selectedMinutes m'
        : 'Select duration below';

    String distanceText = '${_distance.toStringAsFixed(1)} km';

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.themeColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.themeColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.route, color: widget.themeColor),
                    const SizedBox(width: 8),
                    Text(
                      'Distance:',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Text(
                    distanceText,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 15,
                      fontWeight: FontWeight.bold,
                      color: widget.themeColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer, color: Colors.blue, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: widget.themeColor),
              const SizedBox(width: 8),
              Text(
                'DATE & TIME',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDateTimeField(
            title: 'PICKUP DATE',
            value: DateFormat('dd/MM/yyyy').format(_pickupDate),
            icon: Icons.calendar_today,
            onTap: _selectDate,
            isMobile: isMobile,
          ),
          const SizedBox(height: 16),
          _buildDateTimeField(
            title: 'PICKUP TIME',
            value: _pickupTime.format(context),
            icon: Icons.access_time,
            onTap: () {
              _selectTime();
              _checkNightTravel();
            },
            isMobile: isMobile,
          ),
          const SizedBox(height: 16),
          _buildDateTimeField(
            title: 'RETURN DATE (Optional)',
            value: _returnDate != null
                ? DateFormat('dd/MM/yyyy').format(_returnDate!)
                : 'Tap to add return date',
            icon: Icons.calendar_today,
            onTap: _selectReturnDate,
            isMobile: isMobile,
            isRequired: false,
          ),
          const SizedBox(height: 16),
          if (_showExtraHoursWarning && _extraHours > 0) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber,
                          color: Colors.orange[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _extraHoursMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[800],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 32),
                    child: Text(
                      'Extra hour charges: ₹${_extraHourCharges.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.themeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isNightTravel
                  ? widget.themeColor.withOpacity(0.1)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isNightTravel
                    ? widget.themeColor.withOpacity(0.3)
                    : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.nightlight_round,
                  color: _isNightTravel ? widget.themeColor : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isNightTravel
                        ? 'Night Travel (10 PM - 6 AM)'
                        : 'Day Travel',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _isNightTravel
                          ? Colors.grey.shade800
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeField({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required bool isMobile,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(icon, color: widget.themeColor, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleTypeSection(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: widget.themeColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'SELECT VEHICLE',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              if (_loadingVehicles)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(widget.themeColor),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingVehicles)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_vehicleTypes.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No vehicle types available',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: isMobile ? 44 : 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _vehicleTypes.length,
                itemBuilder: (context, index) {
                  final vehicle = _vehicleTypes[index];
                  String displayName = vehicle['displayName'] ?? vehicle['id'];
                  bool isSelected = _selectedVehicleType == vehicle['id'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedVehicleType = vehicle['id'];
                        _selectedModel = null;
                        _availableModels =
                            List<String>.from(vehicle['models'] ?? []);
                        _calculateFare();
                        _calculateExtraHours();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? widget.themeColor
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? widget.themeColor
                              : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Text(
                        displayName,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : Colors.grey.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 13 : 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_selectedVehicleType != null && !_loadingVehicles)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildCapacityWarning(),
            ),
        ],
      ),
    );
  }

  Widget _buildVehicleModelsSection(bool isMobile) {
    if (_selectedVehicleType == null) return const SizedBox();

    List<String> models = _getModelsForSelectedVehicle();

    if (models.isEmpty) return const SizedBox();

    return Padding(
      padding: EdgeInsets.only(
        left: isMobile ? 16 : 20,
        right: isMobile ? 16 : 20,
        bottom: 16,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car_filled,
                    color: widget.themeColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Available Models:',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: models.map((model) {
                bool isSelected = _selectedModel == model;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedModel = model);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 12,
                      vertical: isMobile ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.themeColor.withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? widget.themeColor
                            : widget.themeColor.withOpacity(0.3),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      model,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: isSelected
                            ? widget.themeColor
                            : Colors.grey.shade800,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityWarning() {
    int seats = _getSeatingCapacity(_selectedVehicleType!);
    int totalPassengers = _adults + _children;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: totalPassengers <= seats
            ? widget.themeColor.withOpacity(0.1)
            : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: totalPassengers <= seats
              ? widget.themeColor.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            totalPassengers <= seats ? Icons.check_circle : Icons.warning,
            color: totalPassengers <= seats ? widget.themeColor : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              totalPassengers <= seats
                  ? 'Capacity: $seats seats | Selected: $totalPassengers'
                  : 'Capacity exceeded! Max: $seats | Selected: $totalPassengers',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareSection(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.currency_rupee, color: widget.themeColor),
              const SizedBox(width: 8),
              Text(
                'FARE ESTIMATION',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedVehicleType != null && _distance > 0)
            Column(
              children: [
                _buildDetailedFareBreakdown(isMobile),
                if (_tollCalculated && _tollDetails.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.toll,
                                  color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Toll Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._tollDetails.map((toll) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          toll['name'] ?? 'Toll Plaza',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${toll['district'] ?? ''} • ${toll['highway'] ?? ''}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₹${toll['rate']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Toll Charges:',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '₹${_tollCharges.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.themeColor,
                        widget.themeColor.withOpacity(0.8)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.account_balance_wallet,
                              color: Colors.white),
                          const SizedBox(width: 8),
                          const Text(
                            'Total Amount:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${_totalFare.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(Icons.money_off, color: Colors.grey.shade400, size: 50),
                  const SizedBox(height: 10),
                  const Text(
                    'Select vehicle and calculate distance\nto see fare estimate',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailedFareBreakdown(bool isMobile) {
    final carRates = _rateCard[_selectedVehicleType];
    if (carRates == null) return const SizedBox();

    final double effectiveDistance = _getEffectiveDistanceForCharges();
    final bool isBelow200 = effectiveDistance <= 200;
    final Map<String, dynamic> rateData = (isBelow200
        ? carRates['below200']
        : carRates['above200']) as Map<String, dynamic>;

    String distanceDisplay = '${_distance.toStringAsFixed(1)} km';
    double baseFare =
        _kmCharges + _driverAllowance + _driverFoodCharges + _nightHaltCharges;

    return Column(
      children: [
        _buildFareDetailRow('Vehicle Type', _selectedVehicleType!, ''),
        _buildFareDetailRow('Distance', distanceDisplay, ''),
        if (_routeDuration.isNotEmpty)
          _buildFareDetailRow('Est. Time', _routeDuration, ''),
        _buildFareDetailRow('Rate per km', '₹${rateData['perKm']}/km',
            '₹${_kmCharges.toStringAsFixed(0)}'),
        if (_driverAllowance > 0)
          _buildFareDetailRow('Driver Allowance', '',
              '₹${_driverAllowance.toStringAsFixed(0)}'),
        if (_driverFoodCharges > 0)
          _buildFareDetailRow(
              'Driver Food', '', '₹${_driverFoodCharges.toStringAsFixed(0)}'),
        if (_nightHaltCharges > 0)
          _buildFareDetailRow('Night Halt Charges', '',
              '₹${_nightHaltCharges.toStringAsFixed(0)}'),
        _buildFareDetailRow('Base Fare', '', '₹${baseFare.toStringAsFixed(0)}',
            isBold: true),
        if (_tollCharges > 0)
          _buildFareDetailRow(
              'Toll Charges', '', '₹${_tollCharges.toStringAsFixed(0)}'),
        if (_extraHours > 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      const Icon(Icons.timer, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Extra Hours',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    '$_extraHours h',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    '₹${_extraHourCharges.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: widget.themeColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        const Divider(thickness: 2),
      ],
    );
  }

  Widget _buildFareDetailRow(String label, String value, String amount,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          if (amount.isNotEmpty)
            SizedBox(
              width: 70,
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.bold,
                  color: widget.themeColor,
                ),
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPassengerSection(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: widget.themeColor),
              const SizedBox(width: 8),
              Text(
                'PASSENGER DETAILS',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildCounter(
                  'Adults',
                  _adults,
                  (value) {
                    setState(() => _adults = value);
                  },
                  isMobile: isMobile,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCounter(
                  'Children',
                  _children,
                  (value) {
                    setState(() => _children = value);
                  },
                  isMobile: isMobile,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCounter(
                  'Luggage',
                  _luggage,
                  (value) {
                    setState(() => _luggage = value);
                  },
                  isMobile: isMobile,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(String label, int value, Function(int) onChanged,
      {required bool isMobile}) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 8),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon:
                    Icon(Icons.remove_circle_outline, color: widget.themeColor),
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                splashRadius: 20,
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: widget.themeColor),
                onPressed: () => onChanged(value + 1),
                splashRadius: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDetailsSection(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: widget.themeColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'CUSTOMER DETAILS',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _buildCustomerTextField(
                label: 'Full Name',
                controller: _customerNameController,
                icon: Icons.person_outline,
                isRequired: true,
                keyboardType: TextInputType.name,
                hintText: 'Enter customer full name',
              ),
              const SizedBox(height: 12),
              _buildCustomerTextField(
                label: 'Phone Number',
                controller: _customerPhoneController,
                icon: Icons.phone,
                isRequired: true,
                keyboardType: TextInputType.phone,
                hintText: 'Enter 10-digit mobile number',
              ),
              const SizedBox(height: 12),
              _buildCustomerTextField(
                label: 'Email Address',
                controller: _customerEmailController,
                icon: Icons.email_outlined,
                isRequired: false,
                keyboardType: TextInputType.emailAddress,
                hintText: 'Enter email address (optional)',
              ),
              const SizedBox(height: 12),
              _buildCustomerTextField(
                label: 'Special Instructions',
                controller: _specialInstructionsController,
                icon: Icons.note_add_outlined,
                isRequired: false,
                keyboardType: TextInputType.multiline,
                hintText: 'Any special requests or instructions',
                maxLines: 3,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isRequired,
    required TextInputType keyboardType,
    required String hintText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Icon(icon, color: widget.themeColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: widget.themeColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _validateAndSaveBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isSaving ? Colors.grey.shade400 : widget.themeColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size(double.infinity, 55),
            elevation: 0,
          ),
          child: _isSaving
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'SAVING...',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'CONFIRM & SAVE BOOKING',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class LocationPoint {
  final double lat;
  final double lng;

  LocationPoint(this.lat, this.lng);
}
