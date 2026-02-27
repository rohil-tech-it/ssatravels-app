import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String? id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String fromLocation;
  final String toLocation;
  final DateTime travelDate;
  final DateTime? returnDate;
  final String vehicleType;
  final String vehicleNumber;
  final int passengers;
  final double baseFare;
  final double? tollAmount;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String bookingStatus;
  final DateTime bookingDate;
  
  // New toll-related fields
  final List<Map<String, dynamic>>? tollPlazas;
  final String? routeKey;
  final int? totalTollPlazas;

  BookingModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.fromLocation,
    required this.toLocation,
    required this.travelDate,
    this.returnDate,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.passengers,
    required this.baseFare,
    this.tollAmount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.bookingDate,
    this.tollPlazas,
    this.routeKey,
    this.totalTollPlazas,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'travelDate': Timestamp.fromDate(travelDate),
      'returnDate': returnDate != null ? Timestamp.fromDate(returnDate!) : null,
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'passengers': passengers,
      'baseFare': baseFare,
      'tollAmount': tollAmount,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'bookingStatus': bookingStatus,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'tollPlazas': tollPlazas,
      'routeKey': routeKey,
      'totalTollPlazas': totalTollPlazas,
    };
  }

  factory BookingModel.fromMap(String id, Map<String, dynamic> map) {
    return BookingModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userPhone: map['userPhone'] ?? '',
      fromLocation: map['fromLocation'] ?? '',
      toLocation: map['toLocation'] ?? '',
      travelDate: (map['travelDate'] as Timestamp).toDate(),
      returnDate: map['returnDate'] != null 
          ? (map['returnDate'] as Timestamp).toDate() 
          : null,
      vehicleType: map['vehicleType'] ?? '',
      vehicleNumber: map['vehicleNumber'] ?? '',
      passengers: map['passengers'] ?? 1,
      baseFare: (map['baseFare'] ?? 0).toDouble(),
      tollAmount: map['tollAmount'] != null 
          ? (map['tollAmount']).toDouble() 
          : null,
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      paymentStatus: map['paymentStatus'] ?? 'pending',
      bookingStatus: map['bookingStatus'] ?? 'pending',
      bookingDate: (map['bookingDate'] as Timestamp).toDate(),
      tollPlazas: map['tollPlazas'] != null 
          ? List<Map<String, dynamic>>.from(map['tollPlazas']) 
          : null,
      routeKey: map['routeKey'],
      totalTollPlazas: map['totalTollPlazas'],
    );
  }
}