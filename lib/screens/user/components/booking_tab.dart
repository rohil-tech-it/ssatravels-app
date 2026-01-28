import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:math' as math;

class BookingTab extends StatefulWidget {
  @override
  _BookingTabState createState() => _BookingTabState();
}

class _BookingTabState extends State<BookingTab> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: OutstationCabBookingScreen(),
        ),
      ],
    );
  }
}

class OutstationCabBookingScreen extends StatefulWidget {
  @override
  _OutstationCabBookingScreenState createState() =>
      _OutstationCabBookingScreenState();
}

class _OutstationCabBookingScreenState
    extends State<OutstationCabBookingScreen> {
  // ========== TRIP TYPE ==========
  String _selectedTripType = 'DROP TRIP';

  // ========== CONTROLLERS ==========
  TextEditingController _pickupController = TextEditingController();
  TextEditingController _dropController = TextEditingController();
  TextEditingController _customerNameController = TextEditingController();
  TextEditingController _customerPhoneController = TextEditingController();
  TextEditingController _customerEmailController = TextEditingController();
  TextEditingController _specialInstructionsController =
      TextEditingController();

  // ========== DATE & TIME ==========
  DateTime _pickupDate = DateTime.now();
  TimeOfDay _pickupTime = TimeOfDay.now();

  // ========== TRIP DURATION ==========
  int _tripHours = 1;
  int _packageHours = 8;

  // ========== VEHICLE SELECTION ==========
  String? _selectedCarType;
  String? _selectedVehicleModel;

  // ========== PASSENGER DETAILS ==========
  int _adults = 1;
  int _children = 0;
  int _luggage = 0;

  // ========== DISTANCE & FARE ==========
  double _distance = 0.0;
  double _totalFare = 0.0;
  double _tollCharges = 0.0;
  double _kmCharges = 0.0;
  double _waitingCharges = 0.0;
  double _driverAllowance = 0.0;
  double _driverFoodCharges = 0.0;
  double _nightHaltCharges = 0.0;
  String _tollInfo = "Select vehicle for toll calculation";
  bool _tollCalculated = false;
  List<Map<String, dynamic>> _tollDetails = [];

  // ========== FLAGS ==========
  bool _isNightTravel = false;
  bool _isSaving = false;
  bool _loadingVehicles = false;
  bool _loadingData = false;
  bool _calculatingToll = false;

  // ========== GOOGLE MAPS STATE ==========
  Completer<GoogleMapController> _mapController = Completer();
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng _center = LatLng(9.5850, 77.9570);
  bool _isLoadingLocation = false;
  double _currentZoom = 14.0;

  // ========== SEARCH FUNCTIONALITY ==========
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounceTimer;

  // ========== FIRESTORE ==========
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== DATA STORAGE ==========
  List<String> _citySuggestions = [];
  Map<String, LocationPoint> _cityCoordinates = {};
  List<String> _carTypes = [];
  final Map<String, List<String>> _vehicleModels = {};
  Map<String, Map<String, dynamic>> _rateCard = {};

  // ========== TOLL MARKERS ==========
  List<Map<String, dynamic>> _tollMarkers = [];
  List<LatLng> _routePoints = [];
  LatLng? _temporarySelectedLatLng;
  bool _isPickupSelection = true;

  // ========== API KEYS ==========
  final String _googleMapsApiKey = 'AIzaSyA3ElqlmQtIPePKOhQweCdcKADv0K2c3ww';
  final String _googlePlacesApiKey = 'AIzaSyA3ElqlmQtIPePKOhQweCdcKADv0K2c3ww';

  // ========== OPENROUTESERVICE API ==========
  final String _orsApiKey =
      'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6Ijc1ZjBmZmM4ZDM1OTQ2NTg5MjA0ZjA3M2I2ZjhlOTE1IiwiaCI6Im11cm11cjY0In0=';
  final String _orsApiUrl = 'https://api.openrouteservice.org/v2';

  // ========== VEHICLE MODELS DATABASE ==========
  final Map<String, List<String>> _vehicleModelDatabase = {
    'Hatchback': [
      'Maruti Swift Dzire',
      'Hyundai i20',
      'Tata Tiago',
      'Ford Figo',
      'Maruti Swift',
      'Hyundai i10',
      'Tata Altroz'
    ],
    'Sedan': [
      'Honda City',
      'Toyota Yaris',
      'Hyundai Verna',
      'Maruti Ciaz',
      'Honda Amaze',
      'Toyota Etios',
      'Hyundai Aura'
    ],
    'Innova': [
      'Toyota Innova Crysta',
      'Toyota Innova',
      'Toyota Innova HyCross'
    ],
    'Tavera': [
      'Chevrolet Tavera',
      'Chevrolet Tavera LS',
      'Chevrolet Tavera Neo'
    ],
    'Ertiga': [
      'Maruti Suzuki Ertiga',
      'Maruti Ertiga VXI',
      'Maruti Ertiga ZXI'
    ],
    'Tempo Traveller': [
      'Force Traveller 14S',
      'Tempo Traveller 14 Seater',
      'Tempo Traveller 12S'
    ],
    'Tourist Van': ['Toyota Hiace', 'Mahindra Tourister', 'Tata Winger'],
    'Van 407': ['Tata 407', 'Ashok Leyland Dost', 'Mahindra Bolero Pickup'],
  };

  // ========== INDIAN TOLL RATES DATABASE ==========
  final Map<String, Map<String, dynamic>> _indianTollRates = {
    'Hatchback': {
      'base_toll': 45.0,
      'per_km_rate': 0.25,
      'min_toll': 20.0,
      'max_toll': 200.0,
    },
    'Sedan': {
      'base_toll': 60.0,
      'per_km_rate': 0.30,
      'min_toll': 30.0,
      'max_toll': 250.0,
    },
    'Innova': {
      'base_toll': 90.0,
      'per_km_rate': 0.40,
      'min_toll': 50.0,
      'max_toll': 350.0,
    },
    'Tavera': {
      'base_toll': 110.0,
      'per_km_rate': 0.45,
      'min_toll': 60.0,
      'max_toll': 400.0,
    },
    'Ertiga': {
      'base_toll': 85.0,
      'per_km_rate': 0.35,
      'min_toll': 45.0,
      'max_toll': 300.0,
    },
    'Tempo Traveller': {
      'base_toll': 150.0,
      'per_km_rate': 0.55,
      'min_toll': 80.0,
      'max_toll': 500.0,
    },
    'Tourist Van': {
      'base_toll': 180.0,
      'per_km_rate': 0.65,
      'min_toll': 100.0,
      'max_toll': 600.0,
    },
    'Van 407': {
      'base_toll': 220.0,
      'per_km_rate': 0.75,
      'min_toll': 120.0,
      'max_toll': 750.0,
    },
  };

  // ========== FALLBACK RATE CARD ==========
  final Map<String, Map<String, dynamic>> _fallbackRateCard = {
    'Hatchback': {
      'seats': 5,
      'below200': {
        'hourlyRate': 100.0,
        'perKm': 9.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
        'minHours': 8,
      },
      'above200': {
        'perKm': 10.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      },
    },
    'Sedan': {
      'seats': 5,
      'below200': {
        'hourlyRate': 150.0,
        'perKm': 9.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
        'minHours': 8,
      },
      'above200': {
        'perKm': 11.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      },
    },
    'Innova': {
      'seats': 7,
      'below200': {
        'hourlyRate': 240.0,
        'perKm': 40.0,
        'driverFood': 0.0,
        'nightHalt': 100.0,
        'minHours': 8,
      },
      'above200': {
        'perKm': 15.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      },
    },
    'Tavera': {
      'seats': 9,
      'below200': {
        'hourlyRate': 240.0,
        'perKm': 90.0,
        'driverFood': 0.0,
        'nightHalt': 100.0,
        'minHours': 8,
      },
      'above200': {
        'perKm': 15.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      },
    },
    'Ertiga': {
      'seats': 7,
      'below200': {
        'hourlyRate': 270.0,
        'perKm': 9.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
        'minHours': 8,
      },
      'above200': {
        'perKm': 18.0,
        'driverAllowance': 350.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      },
    },
    'Tempo Traveller': {
      'seats': 14,
      'below200': {
        'hourlyRate': 320.0,
        'perKm': 50.0,
        'driverFood': 100.0,
        'nightHalt': 150.0,
        'minHours': 8,
      },
      'above200': {
        'perKm': 20.0,
        'driverAllowance': 400.0,
        'driverFood': 100.0,
        'nightHalt': 150.0,
      },
    },
    'Tourist Van': {
      'seats': 18,
      'below200': {
        'hourlyRate': 380.0,
        'perKm': 55.0,
        'driverFood': 100.0,
        'nightHalt': 150.0,
        'minHours': 8,
      },
      'above200': {
        'perKm': 22.0,
        'driverAllowance': 450.0,
        'driverFood': 100.0,
        'nightHalt': 150.0,
      },
    },
    'Van 407': {
      'seats': 25,
      'below200': {
        'hourlyRate': 450.0,
        'perKm': 60.0,
        'driverFood': 150.0,
        'nightHalt': 200.0,
        'minHours': 8,
      },
      'above200': {
        'perKm': 25.0,
        'driverAllowance': 500.0,
        'driverFood': 150.0,
        'nightHalt': 200.0,
      },
    },
  };

  @override
  void initState() {
    super.initState();
    _checkNightTravel();
    _loadJsonData();
    _loadVehiclesFromFirebase();
    _getCurrentLocation();
    _initializeApiKeys();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    _pickupController.dispose();
    _dropController.dispose();
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerEmailController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  // ========== INITIALIZE API KEYS ==========
  Future<void> _initializeApiKeys() async {
    // Load API keys from secure storage or config
  }

  // ========== FIXED: PROPER ADDRESS FORMATTING ==========
  Future<String> _getFormattedAddress(LatLng latLng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
        localeIdentifier: 'en_IN',
      ).catchError((e) {
        print('Geocoding error: $e');
        return <Placemark>[];
      });

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        List<String> parts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          parts.add(place.street!);
        } else if (place.name != null && place.name!.isNotEmpty) {
          parts.add(place.name!);
        }

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        } else if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }

        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }

        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          String state = place.administrativeArea!
              .split(' ')
              .map((word) =>
                  word[0].toUpperCase() + word.substring(1).toLowerCase())
              .join(' ')
              .replaceAll('Tamil Nadu', 'Tamil Nadu')
              .replaceAll('TAMIL NADU', 'Tamil Nadu');
          parts.add(state);
        }

        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          parts.add(place.postalCode!);
        }

        return parts.isNotEmpty ? parts.join(', ') : 'Location selected';
      }
    } catch (e) {
      print('Address formatting error: $e');
    }

    return '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}';
  }

  // ========== FIXED: IMPROVED SEARCH LOCATION FUNCTION ==========
  Future<void> _searchLocation(String query) async {
    if (query.isEmpty || query.length < 2) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(Duration(milliseconds: 500), () async {
      try {
        setState(() => _isSearching = true);

        List<Map<String, dynamic>> allResults = [];

        // 1. Local city search
        for (var entry in _cityCoordinates.entries) {
          if (entry.key.toLowerCase().contains(query.toLowerCase())) {
            allResults.add({
              'name': entry.key,
              'address': entry.key,
              'lat': entry.value.lat,
              'lng': entry.value.lng,
              'type': 'city',
            });
          }
        }

        // 2. Google Places API search (if API key is available and query is substantial)
        if (_googlePlacesApiKey.isNotEmpty && query.length >= 3) {
          try {
            final url =
                'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
                'input=${Uri.encodeComponent(query)}&'
                'key=$_googlePlacesApiKey&'
                'components=country:in&'
                'language=en&'
                'location=${_center.latitude},${_center.longitude}&'
                'radius=100000';

            final response =
                await http.get(Uri.parse(url)).timeout(Duration(seconds: 5));
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              if (data['status'] == 'OK') {
                for (var prediction in data['predictions']) {
                  allResults.add({
                    'name': prediction['description'],
                    'address': prediction['description'],
                    'place_id': prediction['place_id'],
                    'type': 'google_place',
                  });
                }
              }
            }
          } catch (e) {
            print('Places API error: $e');
          }
        }

        // 3. Geocoding fallback
        if (allResults.isEmpty || allResults.length < 5) {
          try {
            List<Location> locations =
                await locationFromAddress(query, localeIdentifier: 'en_IN')
                    .timeout(Duration(seconds: 3))
                    .catchError((e) {
              print('Geocoding error: $e');
              return <Location>[];
            });

            for (var location in locations.take(3)) {
              allResults.add({
                'name': query,
                'address': 'Approximate location for "$query"',
                'lat': location.latitude,
                'lng': location.longitude,
                'type': 'geocoded',
              });
            }
          } catch (e) {
            print('Geocoding fallback error: $e');
          }
        }

        setState(() {
          _searchResults = allResults.take(10).toList();
          _isSearching = false;
        });
      } catch (e) {
        print('Search error: $e');
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    });
  }

  // ========== FIXED: IMPROVED MAP ZOOM CONTROLS ==========
  Future<void> _zoomIn() async {
    try {
      if (_mapController.isCompleted) {
        final controller = await _mapController.future;
        double newZoom = _currentZoom + 1;
        if (newZoom <= 20) {
          await controller.animateCamera(CameraUpdate.zoomTo(newZoom));
          setState(() => _currentZoom = newZoom);
        }
      }
    } catch (e) {
      print('Zoom in error: $e');
    }
  }

  Future<void> _zoomOut() async {
    try {
      if (_mapController.isCompleted) {
        final controller = await _mapController.future;
        double newZoom = _currentZoom - 1;
        if (newZoom >= 3) {
          await controller.animateCamera(CameraUpdate.zoomTo(newZoom));
          setState(() => _currentZoom = newZoom);
        }
      }
    } catch (e) {
      print('Zoom out error: $e');
    }
  }

  // ========== FIXED: IMPROVED MOVE CAMERA FUNCTION ==========
  Future<void> _moveCameraToLocation(LatLng location,
      {double zoom = 15.0, double bearing = 0.0, double tilt = 0.0}) async {
    try {
      if (_mapController.isCompleted) {
        final controller = await _mapController.future;
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: location,
              zoom: zoom,
              bearing: bearing,
              tilt: tilt,
            ),
          ),
        );
        setState(() => _currentZoom = zoom);
      }
    } catch (e) {
      print('Move camera error: $e');
      // Fallback: Try to create new controller
      try {
        GoogleMapController controller = await _mapController.future;
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(location, zoom),
        );
      } catch (e2) {
        print('Camera fallback error: $e2');
      }
    }
  }

  // ========== FIXED: IMPROVED MARKERS UPDATE ==========
  void _updateMarkers() {
    final newMarkers = <Marker>{};
    final newPolylines = <Polyline>{};

    // Pickup marker
    if (_pickupLatLng != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickupLatLng!,
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: _pickupController.text.isNotEmpty
                ? _pickupController.text
                : 'Tap to set pickup',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    // Drop marker
    if (_dropLatLng != null) {
      newMarkers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: _dropLatLng!,
          infoWindow: InfoWindow(
            title: 'Drop Location',
            snippet: _dropController.text.isNotEmpty
                ? _dropController.text
                : 'Tap to set drop',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    // Toll markers
    for (int i = 0; i < _tollMarkers.length; i++) {
      final toll = _tollMarkers[i];
      if (toll['lat'] != null && toll['lng'] != null) {
        newMarkers.add(
          Marker(
            markerId: MarkerId('toll_$i'),
            position: LatLng(toll['lat'], toll['lng']),
            infoWindow: InfoWindow(
              title: toll['name'] ?? 'Toll Plaza ${i + 1}',
              snippet: '₹${toll['amount']?.toStringAsFixed(0) ?? '0'}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
          ),
        );
      }
    }

    // Temporary selection marker (for map selection)
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
            title: _isPickupSelection ? 'New Pickup Point' : 'New Drop Point',
            snippet: 'Tap confirm to set location',
          ),
        ),
      );
    }

    // Route polyline
    if (_routePoints.length > 1) {
      newPolylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: Colors.blue,
          width: 4,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
      _polylines = newPolylines;
    });
  }

  // ========== FIXED: IMPROVED PLACE SELECTION HANDLER ==========
  Future<void> _onPlaceSelected(Map<String, dynamic> place) async {
    try {
      setState(() => _isLoadingLocation = true);

      double lat;
      double lng;
      String address;

      // Get coordinates based on place type
      if (place['type'] == 'city' || place['type'] == 'geocoded') {
        // Direct coordinates from local database or geocoding
        lat = place['lat'] as double;
        lng = place['lng'] as double;
        address = place['name'] as String;
      } else if (place['type'] == 'google_place' && place['place_id'] != null) {
        // Get coordinates from Google Place Details API
        try {
          final detailsUrl =
              'https://maps.googleapis.com/maps/api/place/details/json?'
              'place_id=${place['place_id']}&'
              'key=$_googlePlacesApiKey&'
              'fields=name,formatted_address,geometry';

          final detailsResponse = await http
              .get(Uri.parse(detailsUrl))
              .timeout(Duration(seconds: 5));

          if (detailsResponse.statusCode == 200) {
            final detailsData = jsonDecode(detailsResponse.body);
            if (detailsData['status'] == 'OK') {
              final result = detailsData['result'];
              final geometry = result['geometry']['location'];
              lat = geometry['lat'].toDouble();
              lng = geometry['lng'].toDouble();
              address = result['formatted_address'] ?? place['name'];
            } else {
              throw Exception(
                  'Place details API error: ${detailsData['status']}');
            }
          } else {
            throw Exception('HTTP error: ${detailsResponse.statusCode}');
          }
        } catch (e) {
          print('Place details error: $e');
          // Fallback to geocoding
          try {
            List<Location> locations = await locationFromAddress(place['name'],
                    localeIdentifier: 'en_IN')
                .timeout(Duration(seconds: 3));

            if (locations.isNotEmpty) {
              lat = locations.first.latitude;
              lng = locations.first.longitude;
              address = place['name'];
            } else {
              throw Exception('No location found');
            }
          } catch (e2) {
            print('Geocoding fallback error: $e2');
            _showSnackBar('Could not get location coordinates', Colors.orange);
            return;
          }
        }
      } else {
        throw Exception('Unknown place type');
      }

      // Create LatLng object
      LatLng selectedLatLng = LatLng(lat, lng);

      // Update temporary selection
      setState(() {
        _temporarySelectedLatLng = selectedLatLng;
      });

      // Update search controller
      _searchController.text = address;

      // Update markers
      _updateMarkers();

      // Move camera to selected location
      await _moveCameraToLocation(selectedLatLng, zoom: 16.0);

      // Clear search results
      setState(() {
        _searchResults.clear();
      });

      // Unfocus keyboard
      FocusScope.of(context).unfocus();

      _showSnackBar('Location selected: $address', Color(0xFF00C853));
    } catch (e) {
      print('Place selection error: $e');
      _showSnackBar('Error selecting location: ${e.toString()}', Colors.orange);
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  // ========== FIXED: IMPROVED MAP TAP FUNCTION ==========
  Future<void> _onMapTap(LatLng latLng, bool isPickup) async {
    try {
      setState(() => _isLoadingLocation = true);

      // Update temporary selection
      _temporarySelectedLatLng = latLng;

      // Get formatted address
      String address = await _getFormattedAddress(latLng);
      _searchController.text = address;

      // Update markers
      _updateMarkers();

      // Move camera to tapped location
      await _moveCameraToLocation(latLng, zoom: 16.0);

      _showSnackBar('Location selected: $address', Color(0xFF00C853));
    } catch (e) {
      print('Map tap error: $e');
      _showSnackBar('Error selecting location', Colors.orange);
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

 Future<void> _saveSelectedLocation(bool isPickup) async {
  if (_temporarySelectedLatLng == null) {
    _showSnackBar('Please select a location first', Colors.orange);
    return;
  }

  try {
    String address = _searchController.text.isNotEmpty
        ? _searchController.text
        : await _getFormattedAddress(_temporarySelectedLatLng!);

    // 🔥 FIRST: Store the location before setting to null
    LatLng selectedLocation = _temporarySelectedLatLng!;

    setState(() {
      if (isPickup) {
        _pickupController.text = address;
        _pickupLatLng = selectedLocation; // Use stored location
      } else {
        _dropController.text = address;
        _dropLatLng = selectedLocation; // Use stored location
      }
      _temporarySelectedLatLng = null;
    });

    _updateMarkers();

    // 🔥 NOW: Move camera using stored location
    await _moveCameraToLocation(selectedLocation, zoom: 16.0);

    // Calculate distance and toll if both locations are set
    if (_pickupLatLng != null && _dropLatLng != null && _selectedTripType != 'PACKAGE TRIP') {
      _calculateDistanceAndToll();
    }

    Navigator.pop(context);
    _showSnackBar(
        '${isPickup ? 'Pickup' : 'Drop'} location saved', Color(0xFF00C853));
  } catch (e) {
    print('Save location error: $e');
    _showSnackBar('Error saving location', Colors.orange);
  }
}

  // ========== FIXED: IMPROVED MAP SELECTION SHEET ==========
  Widget _buildMapSelectionSheet(bool isPickup) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF00C853),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isPickup
                            ? 'Select Pickup Location'
                            : 'Select Drop Location',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Box
              Padding(
                padding: EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              'Search Street, Area, City, State, Pincode...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          prefixIcon:
                              Icon(Icons.search, color: Color(0xFF00C853)),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close, color: Colors.grey),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchResults.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            _searchLocation(value);
                          } else {
                            setState(() {
                              _searchResults.clear();
                            });
                          }
                        },
                      ),
                      if (_searchResults.isNotEmpty)
                        Container(
                          constraints: BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                                top: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final place = _searchResults[index];
                              return ListTile(
                                leading: Icon(Icons.location_on,
                                    color: Color(0xFF00C853)),
                                title: Text(
                                  place['name'] ?? 'Unknown',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  place['address'] ?? place['name'] ?? '',
                                  style: TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: _isLoadingLocation && index == 0
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF00C853)),
                                        ),
                                      )
                                    : null,
                                onTap: () => _onPlaceSelected(place),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Map
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _temporarySelectedLatLng ?? _center,
                        zoom: _currentZoom,
                      ),
                      onMapCreated: (controller) {
                        if (!_mapController.isCompleted) {
                          _mapController.complete(controller);
                        }
                        if (_temporarySelectedLatLng != null) {
                          _moveCameraToLocation(_temporarySelectedLatLng!);
                        }
                      },
                      markers: _markers,
                      polylines: _polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      onTap: (latLng) => _onMapTap(latLng, isPickup),
                      onCameraMove: (position) {
                        setState(() => _currentZoom = position.zoom);
                      },
                    ),

                    // Center marker
                    Center(
                      child: Icon(
                        Icons.location_pin,
                        color: isPickup ? Colors.green : Colors.red,
                        size: 48,
                      ),
                    ),

                    // Zoom controls
                    Positioned(
                      right: 16,
                      bottom: 100,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(Icons.add, color: Color(0xFF00C853)),
                              onPressed: _zoomIn,
                              iconSize: 20,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon:
                                  Icon(Icons.remove, color: Color(0xFF00C853)),
                              onPressed: _zoomOut,
                              iconSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Current location button
                    Positioned(
                      right: 16,
                      bottom: 160,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon:
                              Icon(Icons.my_location, color: Color(0xFF00C853)),
                          onPressed: _getCurrentLocation,
                          iconSize: 20,
                        ),
                      ),
                    ),

                    // Confirm button
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: ElevatedButton(
                        onPressed: _isLoadingLocation
                            ? null
                            : () => _saveSelectedLocation(isPickup),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isLoadingLocation
                              ? Colors.grey
                              : Color(0xFF00C853),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          minimumSize: Size(double.infinity, 50),
                        ),
                        child: _isLoadingLocation
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Processing...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle, size: 24),
                                  SizedBox(width: 8),
                                  Text(
                                    'Confirm ${isPickup ? 'Pickup' : 'Drop'} Location',
                                    style: TextStyle(
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

  // ========== FIXED: IMPROVED GET CURRENT LOCATION ==========
  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isLoadingLocation = true);

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar('Location permission denied', Colors.orange);
          _setDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackBar('Location permissions permanently denied', Colors.orange);
        _setDefaultLocation();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(Duration(seconds: 10));

      LatLng currentLocation = LatLng(position.latitude, position.longitude);
      String address = await _getFormattedAddress(currentLocation);

      setState(() {
        _center = currentLocation;
        _pickupLatLng = currentLocation;
        _pickupController.text = address;
      });

      _updateMarkers();
      await _moveCameraToLocation(currentLocation, zoom: 16.0);

      _showSnackBar('Current location set as pickup', Color(0xFF00C853));
    } catch (e) {
      print('Location error: $e');
      _showSnackBar('Unable to get location', Colors.orange);
      _setDefaultLocation();
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _setDefaultLocation() {
    setState(() {
      _center = LatLng(9.5850, 77.9570);
      _pickupLatLng = _center;
      _pickupController.text = 'Virudhunagar, Tamil Nadu';
    });
    _updateMarkers();
    _moveCameraToLocation(_center);
  }

  void _showMapSelection(bool isPickup) {
    setState(() {
      _isPickupSelection = isPickup;
      _temporarySelectedLatLng = (isPickup && _pickupLatLng != null)
          ? _pickupLatLng
          : (!isPickup && _dropLatLng != null)
              ? _dropLatLng
              : _center;
      _searchController.clear();
      _searchResults.clear();
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMapSelectionSheet(isPickup),
    );
  }

  // ========== OTHER FUNCTIONS (unchanged but included for completeness) ==========
  Future<Map<String, dynamic>> _calculateAccurateToll() async {
    if (_pickupLatLng == null ||
        _dropLatLng == null ||
        _selectedCarType == null) {
      return {
        'distance': 0.0,
        'tolls': [],
        'totalToll': 0.0,
        'routePoints': [],
        'status': 'error'
      };
    }

    try {
      Map<String, dynamic> orsResult = await _getRouteFromORS();
      double distance = orsResult['distance'] ?? 0.0;
      List<LatLng> routePoints =
          List<LatLng>.from(orsResult['routePoints'] ?? []);

      List<Map<String, dynamic>> tolls = [];
      double totalToll = 0.0;

      if (_indianTollRates.containsKey(_selectedCarType)) {
        var vehicleRates = _indianTollRates[_selectedCarType]!;
        double baseToll = (vehicleRates['base_toll'] as double?) ?? 50.0;
        double perKmRate = (vehicleRates['per_km_rate'] as double?) ?? 0.3;
        double minToll = (vehicleRates['min_toll'] as double?) ?? 20.0;
        double maxToll = (vehicleRates['max_toll'] as double?) ?? 300.0;

        double calculatedToll = baseToll + (distance * perKmRate);
        calculatedToll = calculatedToll.clamp(minToll, maxToll);

        int estimatedTollCount = _estimateTollPlazas(distance);

        if (estimatedTollCount > 0) {
          double tollPerPlaza = calculatedToll / estimatedTollCount;
          tollPerPlaza = tollPerPlaza.roundToDouble();

          for (int i = 0; i < estimatedTollCount; i++) {
            double ratio = (i + 1) / (estimatedTollCount + 1);
            int pointIndex = (routePoints.length * ratio).toInt();

            if (pointIndex < routePoints.length) {
              LatLng point = routePoints[pointIndex];

              tolls.add({
                'lat': point.latitude,
                'lng': point.longitude,
                'amount': tollPerPlaza,
                'name': 'Toll Plaza ${String.fromCharCode(65 + i)}',
                'description': 'Estimated toll on route',
                'distance_from_start': distance * ratio,
              });

              totalToll += tollPerPlaza;
            }
          }
        }

        if (_selectedTripType == 'ROUND TRIP') {
          distance *= 2;
          totalToll *= 2;
          tolls = tolls.map((toll) {
            return {
              ...toll,
              'amount': (toll['amount'] as double) * 2,
              'name': '${toll['name']} (Round Trip)',
            };
          }).toList();
        }
      }

      return {
        'distance': distance,
        'tolls': tolls,
        'totalToll': totalToll,
        'routePoints': routePoints,
        'status': 'calculated',
        'source': 'openrouteservice',
      };
    } catch (e) {
      print('Toll calculation error: $e');
      return _calculateFallbackToll();
    }
  }

  Future<Map<String, dynamic>> _getRouteFromORS() async {
    try {
      final url = '$_orsApiUrl/directions/driving-car';

      final headers = {
        'Authorization': _orsApiKey,
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({
        'coordinates': [
          [_pickupLatLng!.longitude, _pickupLatLng!.latitude],
          [_dropLatLng!.longitude, _dropLatLng!.latitude],
        ],
        'instructions': false,
        'geometry': true,
      });

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          double distance = (route['summary']?['distance'] ?? 0) / 1000.0;

          List<LatLng> routePoints = [];
          if (route['geometry'] != null) {
            routePoints = _decodeORSGeometry(route['geometry']);
          }

          return {
            'distance': distance,
            'routePoints': routePoints,
            'status': 'success',
          };
        }
      }
    } catch (e) {
      print('ORS API error: $e');
    }

    return await _getRouteFromGoogle();
  }

  List<LatLng> _decodeORSGeometry(String geometry) {
    List<LatLng> points = [];
    try {
      points = _decodePolyline(geometry);
    } catch (e) {
      print('Geometry decode error: $e');
    }
    return points;
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    try {
      int index = 0, len = encoded.length;
      int lat = 0, lng = 0;

      while (index < len) {
        int b, shift = 0, result = 0;
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
    } catch (e) {
      print('Polyline decode error: $e');
    }

    return points;
  }

  Future<Map<String, dynamic>> _getRouteFromGoogle() async {
    try {
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${_pickupLatLng!.latitude},${_pickupLatLng!.longitude}&'
          'destination=${_dropLatLng!.latitude},${_dropLatLng!.longitude}&'
          'key=$_googleMapsApiKey&'
          'mode=driving&'
          'alternatives=false';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final legs = route['legs'][0];

          double distance = (legs['distance']['value'] ?? 0) / 1000.0;
          List<LatLng> routePoints = [];

          if (route['overview_polyline'] != null) {
            routePoints = _decodePolyline(route['overview_polyline']['points']);
          }

          return {
            'distance': distance,
            'routePoints': routePoints,
            'status': 'success',
          };
        }
      }
    } catch (e) {
      print('Google Directions API error: $e');
    }

    double directDistance = Geolocator.distanceBetween(
          _pickupLatLng!.latitude,
          _pickupLatLng!.longitude,
          _dropLatLng!.latitude,
          _dropLatLng!.longitude,
        ) /
        1000.0;

    return {
      'distance': directDistance * 1.3,
      'routePoints': _generateRoutePoints(),
      'status': 'fallback',
    };
  }

  List<LatLng> _generateRoutePoints() {
    List<LatLng> points = [];

    if (_pickupLatLng == null || _dropLatLng == null) return points;

    points.add(_pickupLatLng!);

    int steps = 20;
    for (int i = 1; i < steps - 1; i++) {
      double t = i / steps;

      double lat = _pickupLatLng!.latitude +
          (_dropLatLng!.latitude - _pickupLatLng!.latitude) * t;
      double lng = _pickupLatLng!.longitude +
          (_dropLatLng!.longitude - _pickupLatLng!.longitude) * t;

      double curve = math.sin(t * math.pi) * 0.01;
      lat += (math.Random().nextDouble() - 0.5) * curve;
      lng += (math.Random().nextDouble() - 0.5) * curve;

      points.add(LatLng(lat, lng));
    }

    points.add(_dropLatLng!);

    return points;
  }

  Map<String, dynamic> _calculateFallbackToll() {
    if (_pickupLatLng == null || _dropLatLng == null) {
      return {
        'distance': 0.0,
        'tolls': [],
        'totalToll': 0.0,
        'routePoints': []
      };
    }

    double directDistance = Geolocator.distanceBetween(
          _pickupLatLng!.latitude,
          _pickupLatLng!.longitude,
          _dropLatLng!.latitude,
          _dropLatLng!.longitude,
        ) /
        1000.0;

    double distance = directDistance * 1.3;

    if (_selectedTripType == 'ROUND TRIP') {
      distance *= 2;
    }

    List<Map<String, dynamic>> tolls = [];
    double totalToll = 0.0;

    if (_selectedCarType != null &&
        _indianTollRates.containsKey(_selectedCarType)) {
      var rates = _indianTollRates[_selectedCarType]!;
      double baseToll = (rates['base_toll'] as double?) ?? 50.0;
      double perKmRate = (rates['per_km_rate'] as double?) ?? 0.3;

      double calculatedToll = baseToll + (distance * perKmRate);
      calculatedToll = calculatedToll.clamp(
        (rates['min_toll'] as double?) ?? 20.0,
        (rates['max_toll'] as double?) ?? 300.0,
      );

      int tollCount = distance > 50 ? (distance / 100).ceil() : 0;
      tollCount = math.min(tollCount, 3);

      if (tollCount > 0) {
        double tollPerPlaza = calculatedToll / tollCount;

        for (int i = 0; i < tollCount; i++) {
          double ratio = (i + 1) / (tollCount + 1);

          tolls.add({
            'lat': _pickupLatLng!.latitude +
                (_dropLatLng!.latitude - _pickupLatLng!.latitude) * ratio,
            'lng': _pickupLatLng!.longitude +
                (_dropLatLng!.longitude - _pickupLatLng!.longitude) * ratio,
            'amount': tollPerPlaza.roundToDouble(),
            'name': 'Toll ${i + 1}',
            'description': 'Estimated toll point',
            'distance_from_start': distance * ratio,
          });
        }

        totalToll = calculatedToll.roundToDouble();
      }
    }

    return {
      'distance': distance,
      'tolls': tolls,
      'totalToll': totalToll,
      'routePoints': _generateRoutePoints(),
    };
  }

  int _estimateTollPlazas(double distance) {
    if (distance < 50) return 0;
    if (distance <= 150) return 1;
    if (distance <= 300) return 2;
    if (distance <= 500) return 3;
    return math.min((distance / 150).ceil(), 5);
  }

  Future<void> _calculateDistanceAndToll() async {
    if (_pickupLatLng == null || _dropLatLng == null) {
      _showSnackBar('Please select both locations', Colors.orange);
      return;
    }

    if (_selectedCarType == null) {
      _showSnackBar('Please select vehicle type', Colors.orange);
      return;
    }

    setState(() => _calculatingToll = true);

    try {
      Map<String, dynamic> result = await _calculateAccurateToll();

      setState(() {
        _distance = result['distance'] ?? 0.0;
        _tollMarkers = List<Map<String, dynamic>>.from(result['tolls'] ?? []);
        _tollCharges = result['totalToll'] ?? 0.0;
        _routePoints = List<LatLng>.from(result['routePoints'] ?? []);
        _tollInfo = '${_tollMarkers.length} toll plaza(s)';
        _tollDetails = _tollMarkers;
      });

      _updateMarkers();
      _calculateFare();

      String tollSource = result['source'] == 'openrouteservice'
          ? 'OpenRouteService'
          : 'Local Calculation';
      _showSnackBar(
        'Distance: ${_distance.toStringAsFixed(1)} km | Toll: ₹${_tollCharges.toStringAsFixed(0)} ($tollSource)',
        Color(0xFF00C853),
      );
    } catch (e) {
      print('Calculation error: $e');
      _showSnackBar('Error calculating', Colors.orange);
    } finally {
      setState(() => _calculatingToll = false);
    }
  }

  void _calculateFare() {
    if (_selectedCarType == null) {
      setState(() => _totalFare = 0);
      return;
    }

    var carRates =
        _rateCard[_selectedCarType] ?? _fallbackRateCard[_selectedCarType];
    if (carRates == null) {
      setState(() => _totalFare = 0);
      return;
    }

    _kmCharges = 0.0;
    _waitingCharges = 0.0;
    _driverAllowance = 0.0;
    _driverFoodCharges = 0.0;
    _nightHaltCharges = 0.0;
    double totalFare = 0.0;

    if (_selectedTripType == 'PACKAGE TRIP') {
      var rateData = carRates['below200'];

      double hourlyRate = (rateData['hourlyRate'] as double?) ?? 0.0;
      _kmCharges = _packageHours * hourlyRate;

      if (_tripHours > _packageHours) {
        int extraHours = _tripHours - _packageHours;
        _waitingCharges = extraHours * hourlyRate;
      }

      if (rateData['driverFood'] != null &&
          (rateData['driverFood'] as double) > 0) {
        bool isFoodIncluded = (['Innova', 'Tavera'].contains(_selectedCarType));
        if (!isFoodIncluded) {
          _driverFoodCharges = rateData['driverFood'] as double;
        }
      }

      if (_isNightTravel && rateData['nightHalt'] != null) {
        _nightHaltCharges = rateData['nightHalt'] as double;
      }

      totalFare = _kmCharges +
          _waitingCharges +
          _driverFoodCharges +
          _nightHaltCharges +
          _tollCharges;
    } else {
      double effectiveDistance =
          _selectedTripType == 'ROUND TRIP' ? _distance * 2 : _distance;
      bool isBelow200 = effectiveDistance <= 200;
      var rateData = isBelow200 ? carRates['below200'] : carRates['above200'];

      _kmCharges = effectiveDistance * (rateData['perKm'] ?? 0.0);

      if (_tripHours > 0 && rateData['hourlyRate'] != null) {
        _waitingCharges = _tripHours * (rateData['hourlyRate'] as double);
      }

      if (!isBelow200 && rateData['driverAllowance'] != null) {
        int days = (effectiveDistance / 400).ceil();
        if (days < 1) days = 1;
        _driverAllowance = days * (rateData['driverAllowance'] as double);
      }

      if (rateData['driverFood'] != null &&
          (rateData['driverFood'] as double) > 0) {
        bool isFoodIncluded =
            (['Innova', 'Tavera'].contains(_selectedCarType) && isBelow200);
        if (!isFoodIncluded) {
          _driverFoodCharges = rateData['driverFood'] as double;
        }
      }

      if (_isNightTravel && rateData['nightHalt'] != null) {
        _nightHaltCharges = rateData['nightHalt'] as double;
      }

      totalFare = _kmCharges +
          _waitingCharges +
          _driverAllowance +
          _driverFoodCharges +
          _nightHaltCharges +
          _tollCharges;
    }

    setState(() => _totalFare = totalFare.roundToDouble());
  }

  void _checkNightTravel() {
    setState(
        () => _isNightTravel = _pickupTime.hour >= 22 || _pickupTime.hour < 6);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && picked != _pickupDate) {
      setState(() => _pickupDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _pickupTime,
    );
    if (picked != null && picked != _pickupTime) {
      setState(() {
        _pickupTime = picked;
        _checkNightTravel();
      });
    }
  }

  Future<void> _loadJsonData() async {
    try {
      setState(() => _loadingData = true);
      await _loadCityCoordinates();
    } catch (e) {
      print('JSON loading error: $e');
    } finally {
      setState(() => _loadingData = false);
    }
  }

  Future<void> _loadCityCoordinates() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/data/city_coordinates.json');
      final dynamic jsonData = jsonDecode(jsonString);

      Map<String, LocationPoint> coordinates = {};
      List<String> suggestions = [];

      if (jsonData is List) {
        for (var item in jsonData) {
          if (item is Map<String, dynamic>) {
            String name = (item['name'] as String?)?.trim() ?? '';
            double lat = (item['lat'] as num?)?.toDouble() ?? 0.0;
            double lng = (item['lng'] as num?)?.toDouble() ?? 0.0;

            if (name.isNotEmpty && lat != 0.0 && lng != 0.0) {
              coordinates[name] = LocationPoint(lat, lng);
              suggestions.add(name);
            }
          }
        }
      }

      setState(() {
        _cityCoordinates = coordinates;
        _citySuggestions = suggestions;
      });
    } catch (e) {
      print('City coordinates error: $e');
    }
  }

  Future<void> _loadVehiclesFromFirebase() async {
    try {
      setState(() => _loadingVehicles = true);

      final rateSnapshot = await _firestore
          .collection('rateCard')
          .where('isActive', isEqualTo: true)
          .get();

      if (rateSnapshot.docs.isEmpty) {
        _useLocalDatabase();
      } else {
        setState(() {
          _carTypes.clear();
          _vehicleModels.clear();
          _rateCard.clear();

          for (var doc in rateSnapshot.docs) {
            String vehicleType = doc.id;
            _carTypes.add(vehicleType);

            Map<String, dynamic> data = doc.data();
            _rateCard[vehicleType] = {
              'seats': data['seats'] ?? 4,
              'below200': {
                'hourlyRate': data['below200']?['hourlyRate'] ?? 0.0,
                'perKm': data['below200']?['perKm'] ?? 0.0,
                'driverFood': data['below200']?['driverFood'] ?? 0.0,
                'nightHalt': data['below200']?['nightHalt'] ?? 0.0,
                'minHours': data['below200']?['minHours'] ?? 8,
              },
              'above200': {
                'perKm': data['above200']?['perKm'] ?? 0.0,
                'driverAllowance': data['above200']?['driverAllowance'] ?? 0.0,
                'driverFood': data['above200']?['driverFood'] ?? 0.0,
                'nightHalt': data['above200']?['nightHalt'] ?? 0.0,
              },
            };

            _setVehicleModelsFromDatabase(vehicleType);
          }
        });
      }
    } catch (e) {
      print('Firebase error: $e');
      _useLocalDatabase();
    } finally {
      setState(() => _loadingVehicles = false);
    }
  }

  void _useLocalDatabase() {
    setState(() {
      _carTypes = _fallbackRateCard.keys.toList();
      _rateCard = Map.from(_fallbackRateCard);

      for (var vehicleType in _carTypes) {
        _setVehicleModelsFromDatabase(vehicleType);
      }
    });
  }

  void _setVehicleModelsFromDatabase(String vehicleType) {
    if (_vehicleModelDatabase.containsKey(vehicleType)) {
      setState(() =>
          _vehicleModels[vehicleType] = _vehicleModelDatabase[vehicleType]!);
    } else {
      setState(() => _vehicleModels[vehicleType] = ['Standard Model']);
    }
  }

  // ========== BUILD METHOD ==========
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;

        return SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8F5E8), Colors.white],
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
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTripTypeSection(isMobile),
                      Divider(height: 0, color: Colors.grey.shade200),
                      _buildLocationSection(isMobile),
                      Divider(height: 0, color: Colors.grey.shade200),
                      _buildDateTimeSection(isMobile),
                      Divider(height: 0, color: Colors.grey.shade200),
                      _buildVehicleSection(isMobile),
                      if (_selectedCarType != null)
                        _buildVehicleModelsSection(isMobile),
                      Divider(height: 0, color: Colors.grey.shade200),
                      _buildFareSection(isMobile),
                      Divider(height: 0, color: Colors.grey.shade200),
                      _buildPassengerSection(isMobile),
                      Divider(height: 0, color: Colors.grey.shade200),
                      _buildCustomerDetailsSection(isMobile),
                    ],
                  ),
                ),
                _buildConfirmButton(isMobile),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========== UI COMPONENTS ==========
  // [All UI components remain the same as in your original code]
  // Only map search functions were updated above

  Widget _buildTripTypeSection(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: Color(0xFF00C853), size: 20),
              SizedBox(width: 8),
              Text(
                'SELECT TRIP TYPE',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Row(
              children: ['DROP TRIP', 'ROUND TRIP', 'PACKAGE TRIP'].map((type) {
                bool isSelected = _selectedTripType == type;
                BorderRadius borderRadius;

                if (type == 'DROP TRIP') {
                  borderRadius = BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  );
                } else if (type == 'PACKAGE TRIP') {
                  borderRadius = BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  );
                } else {
                  borderRadius = BorderRadius.zero;
                }

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTripType = type;
                        _calculateFare();
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(0xFF00C853) : Colors.white,
                        borderRadius: borderRadius,
                        border: type != 'PACKAGE TRIP'
                            ? Border(
                                right: BorderSide(color: Colors.grey.shade300))
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            type == 'DROP TRIP'
                                ? Icons.arrow_right_alt
                                : type == 'ROUND TRIP'
                                    ? Icons.autorenew
                                    : Icons.timer,
                            color:
                                isSelected ? Colors.white : Color(0xFF00C853),
                            size: 20,
                          ),
                          SizedBox(height: 6),
                          Text(
                            type,
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 12),
          if (_selectedTripType == 'PACKAGE TRIP')
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Package Trip: Hourly rental without distance limit. Includes ${_packageHours} hours package.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
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

  Widget _buildLocationSection(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Color(0xFF00C853)),
              SizedBox(width: 8),
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
          SizedBox(height: 12),
          Column(
            children: [
              _buildLocationField(
                title: 'PICKUP LOCATION',
                controller: _pickupController,
                isPickup: true,
                isMobile: isMobile,
              ),
              SizedBox(height: 16),
              if (_selectedTripType != 'PACKAGE TRIP')
                Column(
                  children: [
                    _buildLocationField(
                      title: 'DROP LOCATION',
                      controller: _dropController,
                      isPickup: false,
                      isMobile: isMobile,
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              Container(
                margin: EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    foregroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.blue.shade200),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  icon: Icon(Icons.my_location, size: 20),
                  label: Text(
                    'USE MY CURRENT LOCATION FOR PICKUP',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              if (_selectedTripType != 'PACKAGE TRIP')
                ElevatedButton(
                  onPressed:
                      _calculatingToll ? null : _calculateDistanceAndToll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _calculatingToll
                        ? Colors.grey.shade400
                        : Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(double.infinity, 50),
                    elevation: 3,
                  ),
                  child: _calculatingToll
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('CALCULATING...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calculate, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'GET DISTANCE & TOLL',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              if (_distance > 0 && _selectedTripType != 'PACKAGE TRIP')
                _buildDistanceInfo(isMobile),
              if (_selectedTripType == 'PACKAGE TRIP')
                Container(
                  padding: EdgeInsets.all(16),
                  margin: EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Color(0xFF00C853).withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer, color: Color(0xFF00C853)),
                          SizedBox(width: 8),
                          Text(
                            'Package Trip Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Hourly rental package. No distance calculation required.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
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
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Tap to select location on map',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    prefixIcon:
                        Icon(Icons.location_on, color: Color(0xFF00C853)),
                  ),
                  onTap: () => _showMapSelection(isPickup),
                ),
              ),
              IconButton(
                icon: Icon(Icons.map, color: Color(0xFF00C853)),
                onPressed: () => _showMapSelection(isPickup),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceInfo(bool isMobile) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 16),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFF00C853).withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.route, color: Color(0xFF00C853)),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Distance:',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 4),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xFF00C853).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.gps_fixed,
                                      size: 10, color: Color(0xFF00C853)),
                                  SizedBox(width: 4),
                                  Text(
                                    'OpenRouteService API',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF00C853),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_distance.toStringAsFixed(1)} km',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00C853),
                          ),
                        ),
                        if (_selectedTripType == 'ROUND TRIP')
                          Text(
                            '${(_distance * 2).toStringAsFixed(1)} km total',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attach_money, color: Color(0xFF00C853)),
                        SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Toll Charges:',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 16,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.only(top: 4),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xFF00C853).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.api,
                                      size: 10, color: Color(0xFF00C853)),
                                  SizedBox(width: 4),
                                  Text(
                                    'OpenRouteService + Local DB',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF00C853),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${_tollCharges.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00C853),
                          ),
                        ),
                        Text(
                          _tollInfo,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (_tollMarkers.isNotEmpty)
                          Text(
                            '${_tollMarkers.length} toll plaza(s)',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (_tollDetails.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Toll Plaza Details:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          SizedBox(height: 8),
                          ..._tollDetails.asMap().entries.map((entry) {
                            int index = entry.key;
                            var toll = entry.value;
                            return Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.money,
                                      size: 12, color: Colors.orange),
                                  SizedBox(width: 6),
                                  Text(
                                    '${toll['name']}:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '₹${toll['amount']?.toStringAsFixed(0) ?? '0'}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
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
              Icon(Icons.calendar_today, color: Color(0xFF00C853)),
              SizedBox(width: 8),
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
          SizedBox(height: 12),
          Column(
            children: [
              if (isMobile)
                Column(
                  children: [
                    _buildDateTimeField(
                      title: 'PICKUP DATE',
                      value:
                          '${_pickupDate.day}/${_pickupDate.month}/${_pickupDate.year}',
                      icon: Icons.calendar_today,
                      onTap: _selectDate,
                      isMobile: isMobile,
                    ),
                    SizedBox(height: 16),
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
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimeField(
                        title: 'PICKUP DATE',
                        value:
                            '${_pickupDate.day}/${_pickupDate.month}/${_pickupDate.year}',
                        icon: Icons.calendar_today,
                        onTap: _selectDate,
                        isMobile: isMobile,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _buildDateTimeField(
                        title: 'PICKUP TIME',
                        value: _pickupTime.format(context),
                        icon: Icons.access_time,
                        onTap: () {
                          _selectTime();
                          _checkNightTravel();
                        },
                        isMobile: isMobile,
                      ),
                    ),
                  ],
                ),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer, color: Color(0xFF00C853), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'TRIP DURATION (Hours)',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.access_time, color: Color(0xFF00C853)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Total Trip Duration',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                if (_tripHours > 1) {
                                  setState(() {
                                    _tripHours--;
                                    _calculateFare();
                                  });
                                }
                              },
                              color: Color(0xFF00C853),
                            ),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text(
                                '$_tripHours',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00C853),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline),
                              onPressed: () {
                                setState(() {
                                  _tripHours++;
                                  _calculateFare();
                                });
                              },
                              color: Color(0xFF00C853),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  if (_selectedTripType == 'PACKAGE TRIP')
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(Icons.timer_outlined, color: Colors.blue),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Package Hours (Included)',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.blue.shade800),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline,
                                    color: Colors.blue),
                                onPressed: () {
                                  if (_packageHours > 4) {
                                    setState(() {
                                      _packageHours--;
                                      _calculateFare();
                                    });
                                  }
                                },
                              ),
                              Container(
                                width: 40,
                                alignment: Alignment.center,
                                child: Text(
                                  '$_packageHours',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add_circle_outline,
                                    color: Colors.blue),
                                onPressed: () {
                                  setState(() {
                                    _packageHours++;
                                    _calculateFare();
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedTripType == 'PACKAGE TRIP'
                                ? 'First $_packageHours hours included in package. Additional hours charged hourly.'
                                : 'All selected hours are chargeable based on hourly rate.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      _isNightTravel ? Color(0xFFE8F5E9) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isNightTravel
                        ? Color(0xFF00C853).withOpacity(0.3)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.nightlight_round,
                        color:
                            _isNightTravel ? Color(0xFF00C853) : Colors.grey),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isNightTravel
                            ? 'Night Travel (10 PM - 6 AM) - Night halt charges apply'
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
        SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(icon, color: Color(0xFF00C853), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSection(bool isMobile) {
    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: Color(0xFF00C853), size: 20),
              SizedBox(width: 8),
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
                  padding: EdgeInsets.only(left: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          Column(
            children: [
              if (_loadingVehicles)
                Container(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
                    ),
                  ),
                )
              else if (_carTypes.isEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No vehicles available. Check Firebase connection or contact admin.',
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
                    itemCount: _carTypes.length,
                    itemBuilder: (context, index) {
                      String carType = _carTypes[index];
                      bool isSelected = _selectedCarType == carType;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCarType = carType;
                            _selectedVehicleModel = null;
                            _calculateFare();
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 8),
                          padding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(0xFF00C853)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? Color(0xFF00C853)
                                  : Colors.grey.shade300,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            carType,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade800,
                              fontWeight: FontWeight.w600,
                              fontSize: isMobile ? 13 : 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              if (_selectedCarType != null && !_loadingVehicles)
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: _buildCapacityWarning(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleModelsSection(bool isMobile) {
    if (_selectedCarType == null) return SizedBox();
    List<String>? models = _vehicleModels[_selectedCarType];
    if (models == null || models.isEmpty) return SizedBox();

    return Padding(
      padding: EdgeInsets.only(
        left: isMobile ? 16 : 20,
        right: isMobile ? 16 : 20,
        bottom: 16,
      ),
      child: Container(
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
                    color: Color(0xFF00C853), size: 18),
                SizedBox(width: 8),
                Text(
                  'Available Models for $_selectedCarType:',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: models.asMap().entries.map((entry) {
                int index = entry.key + 1;
                String model = entry.value;
                bool isSelected = _selectedVehicleModel == model;

                return GestureDetector(
                  onTap: () => setState(() => _selectedVehicleModel = model),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 12,
                      vertical: isMobile ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0xFFE8F5E9) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? Color(0xFF00C853)
                            : Color(0xFF00C853).withOpacity(0.3),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(0xFF00C853)
                                : Color(0xFF00C853).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              '$index',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.white
                                    : Color(0xFF00C853),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          model,
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            color: isSelected
                                ? Color(0xFF00C853)
                                : Colors.grey.shade800,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (isSelected)
                          Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: Icon(Icons.check_circle,
                                size: 16, color: Color(0xFF00C853)),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, size: 14, color: Colors.green),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vendam-only database models (Hardcoded)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w500,
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

  Widget _buildCapacityWarning() {
    int seats = _rateCard[_selectedCarType!]?['seats'] ??
        _fallbackRateCard[_selectedCarType!]?['seats'] ??
        4;
    int totalPassengers = _adults + _children;

    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              totalPassengers <= seats ? Color(0xFFE8F5E9) : Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: totalPassengers <= seats
                ? Color(0xFF00C853).withOpacity(0.3)
                : Colors.red.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              totalPassengers <= seats ? Icons.check_circle : Icons.warning,
              color: totalPassengers <= seats ? Color(0xFF00C853) : Colors.red,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                totalPassengers <= seats
                    ? 'Vehicle capacity: $seats passengers | Selected: $totalPassengers'
                    : 'Capacity exceeded! Max: $seats | Selected: $totalPassengers',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
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
              Icon(Icons.attach_money, color: Color(0xFF00C853)),
              SizedBox(width: 8),
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
          SizedBox(height: 12),
          if (_selectedCarType != null &&
              (_distance > 0 || _selectedTripType == 'PACKAGE TRIP'))
            Column(
              children: [
                _buildDetailedFareBreakdown(isMobile),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00C853), Color(0xFF00E676)],
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
                          Icon(Icons.account_balance_wallet,
                              color: Colors.white),
                          SizedBox(width: 8),
                          Text(
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
                        style: TextStyle(
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
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(Icons.money_off, color: Colors.grey.shade400, size: 50),
                  SizedBox(height: 10),
                  Text(
                    _selectedTripType == 'PACKAGE TRIP'
                        ? 'Select vehicle to see package fare estimate'
                        : 'Select vehicle and calculate distance\nto see fare estimate',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailedFareBreakdown(bool isMobile) {
    final carRates =
        _rateCard[_selectedCarType] ?? _fallbackRateCard[_selectedCarType];
    if (carRates == null) return SizedBox();

    if (_selectedTripType == 'PACKAGE TRIP') {
      var rateData = carRates['below200'];

      return Column(
        children: [
          _buildFareDetailRow('Trip Type', 'PACKAGE TRIP', ''),
          _buildFareDetailRow('Vehicle Type', _selectedCarType!, ''),
          if (_selectedVehicleModel != null)
            _buildFareDetailRow('Vehicle Model', _selectedVehicleModel!, ''),
          _buildFareDetailRow('Package Hours', '$_packageHours hours', ''),
          _buildFareDetailRow('Package Rate', '₹${rateData['hourlyRate']}/hour',
              '₹${(_packageHours * (rateData['hourlyRate'] ?? 0)).toStringAsFixed(0)}'),
          if (_tripHours > _packageHours)
            _buildFareDetailRow(
              'Extra Hours (${_tripHours - _packageHours} hrs)',
              '${_tripHours - _packageHours} hrs × ₹${rateData['hourlyRate']}/hr',
              '₹${((_tripHours - _packageHours) * (rateData['hourlyRate'] ?? 0)).toStringAsFixed(0)}',
            ),
          if (_driverFoodCharges > 0)
            _buildFareDetailRow(
                'Driver Food', '', '₹${_driverFoodCharges.toStringAsFixed(0)}'),
          if (_nightHaltCharges > 0)
            _buildFareDetailRow(
                'Night Halt', '', '₹${_nightHaltCharges.toStringAsFixed(0)}'),
          if (_tollCharges > 0)
            _buildFareDetailRow(
                'Toll Charges', '', '₹${_tollCharges.toStringAsFixed(0)}'),
          Divider(thickness: 2, color: Colors.grey.shade300),
        ],
      );
    } else {
      final double effectiveDistance =
          _selectedTripType == 'ROUND TRIP' ? _distance * 2 : _distance;
      final bool isBelow200 = effectiveDistance <= 200;
      final Map<String, dynamic> rateData = (isBelow200
          ? carRates['below200']
          : carRates['above200']) as Map<String, dynamic>;

      return Column(
        children: [
          _buildFareDetailRow('Trip Type', _selectedTripType, ''),
          _buildFareDetailRow('Vehicle Type', _selectedCarType!, ''),
          if (_selectedVehicleModel != null)
            _buildFareDetailRow('Vehicle Model', _selectedVehicleModel!, ''),
          _buildFareDetailRow(
              'Distance', '${_distance.toStringAsFixed(1)} km', ''),
          if (_selectedTripType == 'ROUND TRIP')
            _buildFareDetailRow('Total Distance (Round Trip)',
                '${effectiveDistance.toStringAsFixed(1)} km', ''),
          _buildFareDetailRow('Rate per km', '₹${rateData['perKm']}/km',
              '₹${_kmCharges.toStringAsFixed(0)}'),
          if (_tripHours > 0)
            _buildFareDetailRow(
              'Trip Duration (${_tripHours} hrs)',
              '${_tripHours} hrs × ₹${rateData['hourlyRate']}/hr',
              '₹${_waitingCharges.toStringAsFixed(0)}',
            ),
          if (_driverAllowance > 0)
            _buildFareDetailRow('Driver Allowance', '',
                '₹${_driverAllowance.toStringAsFixed(0)}'),
          if (_driverFoodCharges > 0)
            _buildFareDetailRow(
                'Driver Food', '', '₹${_driverFoodCharges.toStringAsFixed(0)}'),
          if (_nightHaltCharges > 0)
            _buildFareDetailRow('Night Halt Charges', '',
                '₹${_nightHaltCharges.toStringAsFixed(0)}'),
          if (_tollCharges > 0)
            _buildFareDetailRow(
                'Toll Charges', '', '₹${_tollCharges.toStringAsFixed(0)}'),
          Divider(thickness: 2, color: Colors.grey.shade300),
        ],
      );
    }
  }

  Widget _buildFareDetailRow(String label, String value, String amount) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          if (amount.isNotEmpty)
            SizedBox(
              width: 60,
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00C853),
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
              Icon(Icons.people, color: Color(0xFF00C853)),
              SizedBox(width: 8),
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
          SizedBox(height: 12),
          if (isMobile)
            Column(
              children: [
                _buildCounter(
                  'Adults',
                  _adults,
                  (value) => setState(() => _adults = value),
                  isMobile: isMobile,
                ),
                SizedBox(height: 16),
                _buildCounter(
                  'Children',
                  _children,
                  (value) => setState(() => _children = value),
                  isMobile: isMobile,
                ),
                SizedBox(height: 16),
                _buildCounter(
                  'Luggage',
                  _luggage,
                  (value) => setState(() => _luggage = value),
                  isMobile: isMobile,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildCounter(
                    'Adults',
                    _adults,
                    (value) => setState(() => _adults = value),
                    isMobile: isMobile,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildCounter(
                    'Children',
                    _children,
                    (value) => setState(() => _children = value),
                    isMobile: isMobile,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildCounter(
                    'Luggage',
                    _luggage,
                    (value) => setState(() => _luggage = value),
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
        SizedBox(height: 8),
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
                    Icon(Icons.remove_circle_outline, color: Color(0xFF00C853)),
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
                splashRadius: 20,
                padding: EdgeInsets.only(left: 12, right: 4),
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: Color(0xFF00C853)),
                onPressed: () => onChanged(value + 1),
                splashRadius: 20,
                padding: EdgeInsets.only(left: 4, right: 12),
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
              Icon(Icons.person, color: Color(0xFF00C853), size: 20),
              SizedBox(width: 8),
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
          SizedBox(height: 12),
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
              SizedBox(height: 12),
              _buildCustomerTextField(
                label: 'Phone Number',
                controller: _customerPhoneController,
                icon: Icons.phone,
                isRequired: true,
                keyboardType: TextInputType.phone,
                hintText: 'Enter 10-digit mobile number',
              ),
              SizedBox(height: 12),
              _buildCustomerTextField(
                label: 'Email Address',
                controller: _customerEmailController,
                icon: Icons.email_outlined,
                isRequired: false,
                keyboardType: TextInputType.emailAddress,
                hintText: 'Enter email address (optional)',
              ),
              SizedBox(height: 12),
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
              Text(
                ' *',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        SizedBox(height: 6),
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
                  EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Icon(icon, color: Color(0xFF00C853)),
              filled: false,
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
              color: Color(0xFF00C853).withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 5),
            )
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _validateAndSaveBooking,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                _isSaving ? Colors.grey.shade400 : Color(0xFF00C853),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: EdgeInsets.symmetric(vertical: 16),
            minimumSize: Size(double.infinity, 55),
            elevation: 0,
          ),
          child: _isSaving
              ? Row(
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
              : Row(
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

  void _validateAndSaveBooking() {
    if (_customerNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter customer name', Colors.orange);
      return;
    }

    if (_customerPhoneController.text.trim().isEmpty) {
      _showSnackBar('Please enter customer phone number', Colors.orange);
      return;
    }

    String phone = _customerPhoneController.text.trim();
    if (phone.length < 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      _showSnackBar(
          'Please enter a valid 10-digit phone number', Colors.orange);
      return;
    }

    if (_selectedTripType != 'PACKAGE TRIP' && _distance == 0) {
      _showSnackBar('Please calculate distance first', Colors.orange);
      return;
    }

    if (_selectedCarType == null) {
      _showSnackBar('Please select a vehicle type', Colors.orange);
      return;
    }

    if (_selectedTripType != 'PACKAGE TRIP' && _dropController.text.isEmpty) {
      _showSnackBar('Please select drop location', Colors.orange);
      return;
    }

    int seats = _rateCard[_selectedCarType!]?['seats'] ??
        _fallbackRateCard[_selectedCarType!]?['seats'] ??
        4;
    int totalPassengers = _adults + _children;

    if (totalPassengers > seats) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Color(0xFF00C853)),
              SizedBox(width: 8),
              Text('Capacity Exceeded'),
            ],
          ),
          content: Text(
            '$_selectedCarType can only accommodate $seats passengers.\n\nYou have selected $totalPassengers passengers.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: TextStyle(color: Color(0xFF00C853)),
              ),
            ),
          ],
        ),
      );
      return;
    }

    _showBookingConfirmation();
  }

  void _showBookingConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Booking'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Customer: ${_customerNameController.text}'),
              SizedBox(height: 8),
              Text('Phone: ${_customerPhoneController.text}'),
              SizedBox(height: 8),
              Text('From: ${_pickupController.text}'),
              if (_selectedTripType != 'PACKAGE TRIP') ...[
                SizedBox(height: 8),
                Text('To: ${_dropController.text}'),
              ],
              SizedBox(height: 8),
              if (_selectedTripType != 'PACKAGE TRIP')
                Text('Distance: ${_distance.toStringAsFixed(1)} km'),
              if (_selectedTripType == 'PACKAGE TRIP')
                Text('Package: $_packageHours hours'),
              SizedBox(height: 8),
              Text('Trip Duration: $_tripHours hours'),
              SizedBox(height: 8),
              Text('Vehicle: $_selectedCarType'),
              if (_selectedVehicleModel != null)
                Text('Model: $_selectedVehicleModel'),
              SizedBox(height: 8),
              Text('Total Fare: ₹${_totalFare.toStringAsFixed(0)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveBookingToFirestore();
            },
            child: Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBookingToFirestore() async {
    try {
      setState(() => _isSaving = true);

      String bookingId =
          'BK${DateTime.now().millisecondsSinceEpoch}${_customerPhoneController.text.substring(_customerPhoneController.text.length - 4)}';

      DateTime pickupDateTime = DateTime(
        _pickupDate.year,
        _pickupDate.month,
        _pickupDate.day,
        _pickupTime.hour,
        _pickupTime.minute,
      );

      Map<String, dynamic> bookingData = {
        'bookingId': bookingId,
        'customerName': _customerNameController.text.trim(),
        'customerPhone': _customerPhoneController.text.trim(),
        'customerEmail': _customerEmailController.text.trim().isNotEmpty
            ? _customerEmailController.text.trim()
            : 'Not provided',
        'pickupLocation': _pickupController.text.trim(),
        'dropLocation': _selectedTripType != 'PACKAGE TRIP'
            ? _dropController.text.trim()
            : 'Package Trip',
        'pickupLat': _pickupLatLng?.latitude,
        'pickupLng': _pickupLatLng?.longitude,
        'dropLat':
            _selectedTripType != 'PACKAGE TRIP' ? _dropLatLng?.latitude : null,
        'dropLng':
            _selectedTripType != 'PACKAGE TRIP' ? _dropLatLng?.longitude : null,
        'distance': _distance.toStringAsFixed(1),
        'vehicleType': _selectedCarType ?? 'Not selected',
        'vehicleModel': _selectedVehicleModel ?? 'Not specified',
        'tripType': _selectedTripType,
        'pickupDate': DateFormat('yyyy-MM-dd').format(_pickupDate),
        'pickupTime': _pickupTime.format(context),
        'tripHours': _tripHours,
        'packageHours':
            _selectedTripType == 'PACKAGE TRIP' ? _packageHours : null,
        'adults': _adults.toString(),
        'children': _children.toString(),
        'totalPassengers': (_adults + _children).toString(),
        'luggage': _luggage.toString(),
        'totalFare': _totalFare.toStringAsFixed(0),
        'tollCharges': _tollCharges.toStringAsFixed(0),
        'tollPlazas': _tollMarkers.length,
        'isNightTravel': _isNightTravel,
        'specialInstructions': _specialInstructionsController.text.trim(),
        'bookingStatus': 'Confirmed',
        'bookedOn':
            DateFormat('dd MMM yyyy \'at\' hh:mm a').format(DateTime.now()),
        'createdAt': FieldValue.serverTimestamp(),
        'pickupDateTime': pickupDateTime,
        'fareBreakdown': {
          'kmCharges': _kmCharges,
          'waitingCharges': _waitingCharges,
          'driverAllowance': _driverAllowance,
          'driverFood': _driverFoodCharges,
          'nightHalt': _nightHaltCharges,
          'toll': _tollCharges,
        },
      };

      await _firestore.collection('bookings').doc(bookingId).set(bookingData);

      _showSnackBar('✅ Booking saved! ID: $bookingId', Color(0xFF00C853));
      _resetForm();
    } catch (e) {
      print('❌ Firestore save error: $e');
      _showSnackBar('Failed to save booking', Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedTripType = 'DROP TRIP';
      _pickupController.clear();
      _dropController.clear();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _customerEmailController.clear();
      _specialInstructionsController.clear();
      _pickupDate = DateTime.now();
      _pickupTime = TimeOfDay.now();
      _tripHours = 1;
      _packageHours = 8;
      _selectedCarType = null;
      _selectedVehicleModel = null;
      _adults = 1;
      _children = 0;
      _luggage = 0;
      _distance = 0.0;
      _tollCharges = 0.0;
      _totalFare = 0.0;
      _kmCharges = 0.0;
      _waitingCharges = 0.0;
      _driverAllowance = 0.0;
      _driverFoodCharges = 0.0;
      _nightHaltCharges = 0.0;
      _pickupLatLng = null;
      _dropLatLng = null;
      _markers.clear();
      _polylines.clear();
      _tollMarkers.clear();
      _routePoints.clear();
      _checkNightTravel();
    });

    _getCurrentLocation();
  }
}

class LocationPoint {
  final double lat;
  final double lng;

  LocationPoint(this.lat, this.lng);
}
