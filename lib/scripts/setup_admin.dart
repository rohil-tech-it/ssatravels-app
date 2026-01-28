import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

Future<void> setupAdminAccount() async {
  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    return;
  }

  final firestore = FirebaseFirestore.instance;

  try {
    // Hash password
    final password = 'Admin@ssatravel!1';
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    final hashedPassword = digest.toString();

    // Admin data
    final adminData = {
      'uid': 'admin_001',
      'phoneNumber': '+919751867879',
      'password': hashedPassword,
      'fullName': 'SSA Admin',
      'email': 'admin@ssatravels.com',
      'role': 'super_admin',
      'permissions': ['manage_all'],
      'createdAt': FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
      'isActive': true,
    };

    // Create admin document
    await firestore.collection('admins').doc('admin_001').set(adminData);
  } catch (e) {
    print('❌ Error creating admin account: $e');
  }
}

void main() async {
  await setupAdminAccount();
}
