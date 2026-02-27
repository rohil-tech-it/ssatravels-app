// lib/services/web_places_helper.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';

class WebPlacesHelper {
  static Future<List<Map<String, dynamic>>> searchPlaces(String query, String apiKey) async {
    if (!kIsWeb) return [];
    if (query.isEmpty || query.length < 2) return [];
    
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
          '?input=$query'
          '&components=country:in'
          '&key=$apiKey';
      
      print('📍 Web Places search: $query');
      
      // Don't add any headers
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
      print('❌ Web places helper error: $e');
    }
    
    return [];
  }
  
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId, String apiKey) async {
    if (!kIsWeb) return null;
    if (placeId.isEmpty) return null;
    
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=$placeId'
          '&fields=name,formatted_address,geometry'
          '&key=$apiKey';
      
      // Don't add any headers
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
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
        }
      }
    } catch (e) {
      print('❌ Web details error: $e');
    }
    
    return null;
  }
}