// lib/models/vehicle_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class VehicleModel {
  final String id;
  final String name; // Vehicle number/ID
  final String displayName; // Full display name with model
  final String vehicleName; // Base vehicle name
  final String vehicleModel; // Vehicle model/variant
  final String category; // This should match rateCard keys (innova, hatchback, etc.)
  final int seatingCapacity;
  final double baseTollMultiplier;
  final String? ownerName;
  final String? ownerPhone;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  VehicleModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.vehicleName,
    required this.vehicleModel,
    required this.category,
    required this.seatingCapacity,
    required this.baseTollMultiplier,
    this.ownerName,
    this.ownerPhone,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Firestore data to VehicleModel
  factory VehicleModel.fromFirestore(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return VehicleModel(
      id: documentId,
      name: data['name'] ?? '',
      displayName: data['displayName'] ?? '',
      vehicleName: data['vehicleName'] ?? data['displayName']?.split('(').first.trim() ?? '',
      vehicleModel: data['vehicleModel'] ?? '',
      category: data['category'] ?? 'Car', // Default to 'Car' if not set
      seatingCapacity: data['seatingCapacity'] ?? 4,
      baseTollMultiplier: (data['baseTollMultiplier'] ?? 1.0).toDouble(),
      ownerName: data['ownerName'],
      ownerPhone: data['ownerPhone'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert VehicleModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'displayName': displayName,
      'vehicleName': vehicleName,
      'vehicleModel': vehicleModel,
      'category': category,
      'seatingCapacity': seatingCapacity,
      'baseTollMultiplier': baseTollMultiplier,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper method to get display name without model for certain views
  String get baseName => vehicleName.isNotEmpty ? vehicleName : displayName;
  
  // Helper method to get model only
  String get model => vehicleModel.isNotEmpty ? vehicleModel : '';
  
  // Full display with model
  String get fullDisplayName => model.isNotEmpty ? '$baseName ($model)' : baseName;
}