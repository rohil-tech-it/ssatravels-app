// lib/services/phone_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login with phone number (by finding email from Firestore)
  Future<User?> loginWithPhoneNumber(String phoneNumber, String password) async {
    try {
      print('🔍 Searching for phone number: $phoneNumber');
      
      // Step 1: Clean the phone number (remove +91 if present)
      String cleanPhone = phoneNumber.replaceAll('+91', '').replaceAll(' ', '').trim();
      
      // Step 2: Search in Firestore for this phone number
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: cleanPhone)
          .limit(1)
          .get();

      // Check if user exists
      if (querySnapshot.docs.isEmpty) {
        print('❌ No user found with phone: $cleanPhone');
        return null;
      }

      // Step 3: Get the email from user document
      final userData = querySnapshot.docs.first.data();
      final email = userData['email'];

      if (email == null || email.isEmpty) {
        print('❌ Email not found for this user');
        return null;
      }

      print('✅ Found email: $email for phone: $cleanPhone');

      // Step 4: Sign in with email and password
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Login successful for user: ${result.user?.uid}');
      return result.user;
      
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth error: ${e.code} - ${e.message}');
      if (e.code == 'wrong-password') {
        throw Exception('Wrong password');
      } else if (e.code == 'user-not-found') {
        throw Exception('User not found');
      } else {
        throw Exception('Authentication failed: ${e.message}');
      }
    } catch (e) {
      print('❌ Phone login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  // Check if phone number exists
  Future<bool> checkPhoneExists(String phoneNumber) async {
    try {
      String cleanPhone = phoneNumber.replaceAll('+91', '').replaceAll(' ', '').trim();
      
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: cleanPhone)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking phone: $e');
      return false;
    }
  }
}