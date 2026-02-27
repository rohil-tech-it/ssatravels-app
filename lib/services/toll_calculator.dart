import '../models/toll_route_model.dart';
import '../data/tamilnadu_toll_routes.dart';

enum TripType { oneWay, roundTrip }

class TollCalculationResult {
  final double totalAmount;
  final String message;
  final String fromCity;
  final String toCity;
  final double distance;
  final int tollCount;
  final TripType tripType;
  final bool returnWithin24Hours;

  TollCalculationResult({
    required this.totalAmount,
    required this.message,
    required this.fromCity,
    required this.toCity,
    required this.distance,
    required this.tollCount,
    required this.tripType,
    required this.returnWithin24Hours,
  });
}

class TollCalculator {
  // Calculate toll - RETURNS ONLY TOTAL AMOUNT (no individual rates)
  static TollCalculationResult calculateToll({
    required String fromCity,
    required String toCity,
    required TripType tripType,
    DateTime? returnTime,
  }) {
    // Get route
    final route = TamilNaduTollRoutes.getRoute(fromCity, toCity);
    
    if (route == null) {
      return TollCalculationResult(
        totalAmount: 0,
        message: 'Route not available between $fromCity and $toCity',
        fromCity: fromCity,
        toCity: toCity,
        distance: 0,
        tollCount: 0,
        tripType: tripType,
        returnWithin24Hours: false,
      );
    }

    // Get forward journey toll
    double forwardToll = route['baseToll'].toDouble();
    
    // For one-way trip
    if (tripType == TripType.oneWay) {
      return TollCalculationResult(
        totalAmount: forwardToll,
        message: 'One-way trip toll',
        fromCity: fromCity,
        toCity: toCity,
        distance: route['distance'].toDouble(),
        tollCount: route['tollPlazaIds'].length,
        tripType: tripType,
        returnWithin24Hours: false,
      );
    }
    
    // For round trip
    else {
      bool isWithin24Hours = _isWithin24Hours(returnTime);
      
      // Get return route
      final returnRoute = TamilNaduTollRoutes.getRoute(toCity, fromCity);
      double returnToll = returnRoute != null 
          ? returnRoute['baseToll'].toDouble() 
          : forwardToll;
      
      double totalToll;
      String message;
      
      if (isWithin24Hours) {
        totalToll = forwardToll + returnToll;
        message = 'Round trip within 24 hours - Total includes both journeys';
      } else {
        totalToll = forwardToll;
        message = 'Return after 24 hours - Pay only forward journey now';
      }
      
      return TollCalculationResult(
        totalAmount: totalToll,
        message: message,
        fromCity: fromCity,
        toCity: toCity,
        distance: route['distance'].toDouble(),
        tollCount: route['tollPlazaIds'].length,
        tripType: tripType,
        returnWithin24Hours: isWithin24Hours,
      );
    }
  }

  // Check if return is within 24 hours
  static bool _isWithin24Hours(DateTime? returnTime) {
    if (returnTime == null) return false;
    final now = DateTime.now();
    final difference = returnTime.difference(now).inHours;
    return difference <= 24 && difference > 0;
  }

  // Get route summary (without individual tolls)
  static String getRouteSummary(String from, String to) {
    final route = TamilNaduTollRoutes.getRoute(from, to);
    if (route == null) return 'Route not available';
    return '${route['distance']} km • ${route['tollPlazaIds'].length} toll plazas';
  }

  // Check if route exists
  static bool routeExists(String from, String to) {
    return TamilNaduTollRoutes.getRoute(from, to) != null;
  }
}