// lib/services/route_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'web_places_helper.dart';

class RouteService {
  String? _apiKey;
  final bool isWeb;

  RouteService() : isWeb = kIsWeb {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
      
      if (_apiKey == null || _apiKey!.isEmpty) {
        print('❌ GOOGLE_MAPS_API_KEY not found in .env file');
      } else {
        print('🔑 RouteService initialized with API key: ✅ Loaded');
        print('   Key starts with: ${_apiKey!.substring(0, 10)}...');
      }
    } catch (e) {
      print('❌ Error loading .env file: $e');
      _apiKey = '';
    }
  }

  String _buildUrl(String path, Map<String, String> params) {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('API key is missing');
    }
    
    params['key'] = _apiKey!;
    final queryString = params.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    final url = 'https://maps.googleapis.com/maps/api/$path/json?$queryString';
    
    return url;
  }

  // Search places using Google Places API
  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.isEmpty || query.length < 2) return [];
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('❌ API key is missing');
      return [];
    }

    // For web, use simple fetch without custom headers
    if (kIsWeb) {
      try {
        print('📍 Using web fetch for: "$query"');
        final url = _buildUrl('place/autocomplete', {
          'input': query,
          'components': 'country:in',
        });

        // IMPORTANT: Don't add any headers for Google APIs on web
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['status'] == 'OK') {
            final predictions = data['predictions'] as List? ?? [];
            print('✅ Found ${predictions.length} results for "$query"');
            
            return predictions.map((p) {
              return {
                'place_id': p['place_id'] ?? '',
                'description': p['description'] ?? '',
                'main_text': p['structured_formatting']?['main_text'] ?? p['description'] ?? '',
                'secondary_text': p['structured_formatting']?['secondary_text'] ?? '',
              };
            }).toList();
          }
        }
      } catch (e) {
        print('❌ Web fetch error: $e');
      }
    }

    // HTTP method for non-web
    try {
      final url = _buildUrl('place/autocomplete', {
        'input': query,
        'components': 'country:in',
      });

      print('📍 Places search URL: ${url.replaceAll(_apiKey!, 'HIDDEN')}');

      // Don't use headers for Google APIs
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('   Places search status: ${data['status']}');

        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List? ?? [];
          print('✅ Found ${predictions.length} results for "$query"');
          
          return predictions.map<Map<String, dynamic>>((p) {
            return {
              'place_id': p['place_id'] ?? '',
              'description': p['description'] ?? '',
              'main_text': p['structured_formatting']?['main_text'] ??
                  p['description'] ?? '',
              'secondary_text':
                  p['structured_formatting']?['secondary_text'] ?? '',
            };
          }).toList();
        } else if (data['status'] == 'ZERO_RESULTS') {
          print('⚠️ No results found for "$query"');
          return [];
        } else if (data['status'] == 'REQUEST_DENIED') {
          print('❌ Places API not enabled.');
        } else {
          print('❌ Places API error: ${data['status']}');
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Place search error: $e');
    }

    return [];
  }

  // Get place details by place_id
  Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (_apiKey == null || _apiKey!.isEmpty || placeId.isEmpty) return null;

    try {
      final url = _buildUrl('place/details', {
        'place_id': placeId,
        'fields': 'name,formatted_address,geometry',
      });

      print('📍 Place details URL: ${url.replaceAll(_apiKey!, 'HIDDEN')}');

      // Don't use headers for Google APIs
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('   Place details status: ${data['status']}');

        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']?['location'];

          if (location != null) {
            return {
              'name': result['name'] ?? '',
              'address': result['formatted_address'] ?? '',
              'lat': location['lat'] ?? 0.0,
              'lng': location['lng'] ?? 0.0,
              'place_id': placeId,
            };
          }
        } else if (data['status'] == 'REQUEST_DENIED') {
          print('❌ Places API not enabled.');
        }
      }
    } catch (e) {
      print('❌ Place details error: $e');
    }

    return null;
  }

  // Get route between two points
  Future<Map<String, dynamic>> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    print('📍 Getting route from ${origin.latitude},${origin.longitude} to ${destination.latitude},${destination.longitude}');

    if (_apiKey == null || _apiKey!.isEmpty) {
      print('⚠️ API key empty, using fallback');
      return _generateFallbackRoute(origin, destination);
    }

    try {
      final url = _buildUrl('directions', {
        'origin': '${origin.latitude},${origin.longitude}',
        'destination': '${destination.latitude},${destination.longitude}',
        'mode': 'driving',
        'alternatives': 'true',
      });

      print('📍 Directions URL: ${url.replaceAll(_apiKey!, 'HIDDEN')}');

      // Don't use headers for Google APIs
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('   Directions status: ${data['status']}');

        if (data['status'] == 'OK') {
          print('✅ Real road route found!');
          return _parseDirectionsResponse(data);
        } else if (data['status'] == 'REQUEST_DENIED') {
          print('❌ Directions API not enabled.');
        } else if (data['status'] == 'ZERO_RESULTS') {
          print('⚠️ No route found between these points');
        } else {
          print('❌ Directions API error: ${data['status']}');
        }
      }
    } catch (e) {
      print('❌ Directions error: $e');
    }

    print('⚠️ Using fallback route');
    return _generateFallbackRoute(origin, destination);
  }

  // Parse Google Directions API response
  Map<String, dynamic> _parseDirectionsResponse(Map<String, dynamic> data) {
    final routes = data['routes'] as List? ?? [];
    if (routes.isEmpty) {
      return _generateFallbackRoute(LatLng(0, 0), LatLng(0, 0));
    }

    final route = routes[0];
    final leg = route['legs'][0];

    final distance = (leg['distance']['value'] as num?)?.toDouble() ?? 0.0;
    final distanceInKm = distance / 1000.0;
    final duration = leg['duration']['text'] as String? ?? '';
    final distanceText = leg['distance']['text'] as String? ??
        '${distanceInKm.toStringAsFixed(1)} km';

    // Decode the polyline
    final encodedPolyline = route['overview_polyline']['points'] as String? ?? '';
    List<LatLng> routePoints = [];

    if (encodedPolyline.isNotEmpty) {
      try {
        final polylinePoints = PolylinePoints();
        final List<PointLatLng> decodedPoints =
            polylinePoints.decodePolyline(encodedPolyline);
        routePoints = decodedPoints
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
        print('📍 Successfully decoded ${routePoints.length} route points');
      } catch (e) {
        print('❌ Polyline decode error: $e');
        routePoints = _decodePolylineManual(encodedPolyline);
      }
    }

    return {
      'distance': distanceInKm,
      'distanceText': distanceText,
      'duration': duration,
      'durationSeconds': leg['duration']['value'] ?? 0,
      'routePoints': routePoints,
      'steps': [],
      'status': 'OK',
      'source': 'google_maps',
    };
  }

  List<LatLng> _decodePolylineManual(String encoded) {
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
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  // Get address from coordinates
  Future<String> getAddressFromLatLng(LatLng latLng) async {
    print('📍 Getting address for: (${latLng.latitude}, ${latLng.longitude})');

    if (_apiKey == null || _apiKey!.isEmpty) {
      return _formatCoordinates(latLng);
    }

    // Try Google Geocoding API
    try {
      final url = 'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${latLng.latitude},${latLng.longitude}'
          '&key=$_apiKey';

      print('   Reverse geocoding URL: ${url.replaceAll(_apiKey!, 'HIDDEN')}');

      // Don't use headers for Google APIs
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('   Geocoding status: ${data['status']}');

        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          final result = data['results'][0];
          String address = result['formatted_address'] ?? '';

          if (address.isNotEmpty) {
            print('✅ Found address: $address');
            return address;
          }
        } else if (data['status'] == 'REQUEST_DENIED') {
          print('❌ Geocoding API not enabled.');
        }
      }
    } catch (e) {
      print('❌ Reverse geocoding error: $e');
    }

    // Try local geocoding
    try {
      final placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[];

        if (p.name?.isNotEmpty ?? false) parts.add(p.name!);
        if (p.subLocality?.isNotEmpty ?? false) parts.add(p.subLocality!);
        if (p.locality?.isNotEmpty ?? false) parts.add(p.locality!);
        if (p.administrativeArea?.isNotEmpty ?? false)
          parts.add(p.administrativeArea!);
        if (p.country?.isNotEmpty ?? false) parts.add(p.country!);

        if (parts.isNotEmpty) {
          print('✅ Local address: ${parts.join(', ')}');
          return parts.join(', ');
        }
      }
    } catch (e) {
      print('❌ Local geocoding error: $e');
    }

    return _formatCoordinates(latLng);
  }

  String _formatCoordinates(LatLng latLng) {
    return '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
  }

  // Generate fallback route
  Map<String, dynamic> _generateFallbackRoute(
      LatLng origin, LatLng destination) {
    List<LatLng> routePoints = [];
    routePoints.add(origin);

    double distance = 30.0;
    try {
      distance = Geolocator.distanceBetween(
            origin.latitude,
            origin.longitude,
            destination.latitude,
            destination.longitude,
          ) /
          1000.0;
    } catch (e) {
      print('❌ Distance calculation error: $e');
    }

    int steps = (distance * 2).round().clamp(20, 100);
    
    for (int i = 1; i < steps; i++) {
      double t = i / steps;
      double lat = origin.latitude + (destination.latitude - origin.latitude) * t;
      double lng = origin.longitude + (destination.longitude - origin.longitude) * t;
      
      double curve = math.sin(t * math.pi) * 0.02;
      
      double dx = destination.longitude - origin.longitude;
      double dy = destination.latitude - origin.latitude;
      double length = math.sqrt(dx * dx + dy * dy);
      
      if (length > 0) {
        double perpX = -dy / length;
        double perpY = dx / length;
        lat += perpY * curve * distance * 0.1;
        lng += perpX * curve * distance * 0.1;
      }
      
      routePoints.add(LatLng(lat, lng));
    }

    routePoints.add(destination);

    int minutes = (distance / 50 * 60).round();
    if (minutes < 5) minutes = 5;
    
    String duration = minutes >= 60
        ? '${minutes ~/ 60} hr ${minutes % 60} min'
        : '${minutes} min';

    return {
      'distance': distance,
      'distanceText': '${distance.toStringAsFixed(1)} km',
      'duration': duration,
      'durationSeconds': minutes * 60,
      'routePoints': routePoints,
      'steps': [],
      'status': 'FALLBACK',
      'source': 'fallback',
    };
  }
}