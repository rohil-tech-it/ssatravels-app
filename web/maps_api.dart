import 'dart:js' as js;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsWebHelper {
  static void loadDirections(
    LatLng origin,
    LatLng destination,
    Function(List<LatLng>) onRouteLoaded,
  ) {
    final directionsService = js.JsObject(js.context['google'].maps.DirectionsService);
    final directionsRenderer = js.JsObject(js.context['google'].maps.DirectionsRenderer);
    
    final request = js.JsObject.jsify({
      'origin': {'lat': origin.latitude, 'lng': origin.longitude},
      'destination': {'lat': destination.latitude, 'lng': destination.longitude},
      'travelMode': 'DRIVING',
    });

    directionsService.callMethod('route', [request, (result, status) {
      if (status == 'OK') {
        final route = result['routes'][0];
        final overviewPath = route['overview_path'];
        
        List<LatLng> routePoints = [];
        for (int i = 0; i < overviewPath.length; i++) {
          final point = overviewPath[i];
          routePoints.add(LatLng(
            point['lat'].toDouble(),
            point['lng'].toDouble(),
          ));
        }
        
        onRouteLoaded(routePoints);
      }
    }]);
  }
}