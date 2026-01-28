// lib/models/booking_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingModel {
  final String? id;
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String pickupLocation;
  final String dropLocation;
  final String travelDate;
  final String travelTime;
  final String vehicleType;
  final int numberOfPersons;
  final double totalAmount;
  final double paidAmount;
  final String paymentStatus;
  final String status;
  final String? paymentMethod;
  final String? bookingId;
  final Timestamp createdAt;
  final Timestamp? updatedAt;
  final String? notes;
  final String? driverName;
  final String? vehicleNumber;

  BookingModel({
    this.id,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.pickupLocation,
    required this.dropLocation,
    required this.travelDate,
    required this.travelTime,
    required this.vehicleType,
    required this.numberOfPersons,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentStatus,
    required this.status,
    this.paymentMethod,
    this.bookingId,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    this.driverName,
    this.vehicleNumber,
  });

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return BookingModel(
      id: doc.id,
      customerName: data['customerName'] ?? '',
      customerPhone: data['customerPhone'] ?? '',
      customerEmail: data['customerEmail'],
      pickupLocation: data['pickupLocation'] ?? '',
      dropLocation: data['dropLocation'] ?? '',
      travelDate: data['travelDate'] ?? '',
      travelTime: data['travelTime'] ?? '',
      vehicleType: data['vehicleType'] ?? '',
      numberOfPersons: data['numberOfPersons'] ?? 1,
      totalAmount: (data['totalAmount'] ?? 0).toDouble(),
      paidAmount: (data['paidAmount'] ?? 0).toDouble(),
      paymentStatus: data['paymentStatus'] ?? 'pending',
      status: data['status'] ?? 'pending',
      paymentMethod: data['paymentMethod'],
      bookingId: data['bookingId'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'],
      notes: data['notes'],
      driverName: data['driverName'],
      vehicleNumber: data['vehicleNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'pickupLocation': pickupLocation,
      'dropLocation': dropLocation,
      'travelDate': travelDate,
      'travelTime': travelTime,
      'vehicleType': vehicleType,
      'numberOfPersons': numberOfPersons,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'paymentStatus': paymentStatus,
      'status': status,
      'paymentMethod': paymentMethod,
      'bookingId': bookingId ?? 'BK${DateTime.now().millisecondsSinceEpoch}',
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? FieldValue.serverTimestamp(),
      'notes': notes,
      'driverName': driverName,
      'vehicleNumber': vehicleNumber,
    };
  }
}