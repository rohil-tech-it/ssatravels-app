import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/admin_config.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;
  bool _isAdmin = false;
  String? _phoneNumber;
  User? _firebaseUser;
  Map<String, dynamic>? _userData;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _isAdmin;
  String? get phoneNumber => _phoneNumber;
  Map<String, dynamic>? get userData => _userData;
  User? get firebaseUser => _firebaseUser;

  AuthProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _auth.authStateChanges().listen((User? user) async {
      _firebaseUser = user;
      _isLoggedIn = user != null;

      if (_isLoggedIn) {
        await _loadUserData(user!);
      } else {
        _isAdmin = false;
        _phoneNumber = null;
        _userData = null;
      }

      notifyListeners();
    });
  }

  Future<void> _loadUserData(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        _userData = userDoc.data() as Map<String, dynamic>;
        _phoneNumber = _userData!['phoneNumber'];
        _isAdmin = _userData!['isAdmin'] == true;
      } else {
        await _createUserDocument(user);
      }
    } catch (e) {
      debugPrint('Auth error: $e');
    }
  }

  Future<void> _createUserDocument(User user) async {
    try {
      // Extract phone from email (6379226432@ssatravels.com → 6379226432)
      String email = user.email ?? '';
      String phone = email.replaceAll('@ssatravels.com', '');

      _userData = {
        'uid': user.uid,
        'phoneNumber': phone,
        'email': '', // Empty initially
        'fullName': user.displayName ?? 'User',
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).set(_userData!);
    } catch (e) {
      debugPrint('Auth error: $e');
    }
  }

  // ============================================
  // LOGIN METHOD
  // ============================================
  Future<bool> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Clean phone number
      String cleanPhone = _cleanPhoneNumber(phoneNumber);

      // ================================
      // 1. ADMIN LOGIN
      // ================================
      if (cleanPhone == AdminConfig.adminPhone) {
        if (password.trim() != AdminConfig.adminPassword) {
          _error = 'Invalid admin password';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final adminQuery = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: AdminConfig.adminPhone)
            .where('isAdmin', isEqualTo: true)
            .limit(1)
            .get();

        if (adminQuery.docs.isEmpty) {
          _error = 'Admin account not configured';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final adminDoc = adminQuery.docs.first;
        _isAdmin = true;
        _isLoggedIn = true;
        _phoneNumber = cleanPhone;
        _userData = adminDoc.data();
        _userData!['uid'] = adminDoc.id;
        _firebaseUser = null;

        _isLoading = false;
        notifyListeners();
        return true;
      }

      // ================================
      // 2. USER LOGIN
      // ================================

      // Check if phone number is registered
      final phoneCheck = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: cleanPhone)
          .limit(1)
          .get();

      if (phoneCheck.docs.isEmpty) {
        _error = 'No account found with this phone number';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Convert phone to SSA email format for Firebase Auth
      String phoneEmail = '$cleanPhone@ssatravels.com';

      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: phoneEmail,
          password: password,
        );

        // Load user data
        await _loadUserData(userCredential.user!);

        // Set user state
        _isLoggedIn = true;
        _phoneNumber = cleanPhone;
        _firebaseUser = userCredential.user;

        _isLoading = false;
        notifyListeners();
        return true;
      } on FirebaseAuthException catch (e) {
        _error = _getAuthErrorMessage(e.code);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this phone number';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid phone number format';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Contact admin.';
      default:
        return 'Login failed. Please try again';
    }
  }

  // ============================================
  // REGISTRATION METHOD
  // ============================================
  Future<bool> register({
    required String phoneNumber,
    required String password,
    required String confirmPassword,
    required String fullName,
    required String email,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Clean phone number
      String cleanPhone = _cleanPhoneNumber(phoneNumber);

      // Validation
      if (password != confirmPassword) {
        _error = 'Passwords do not match';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (password.length < 6) {
        _error = 'Password must be at least 6 characters';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (email.isEmpty || !email.contains('@')) {
        _error = 'Please enter a valid email address';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Validate phone number
      if (cleanPhone.length != 10 ||
          !RegExp(r'^[6-9]\d{9}$').hasMatch(cleanPhone)) {
        _error = 'Please enter a valid 10-digit Indian phone number';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // BLOCK ADMIN PHONE
      if (cleanPhone == AdminConfig.adminPhone) {
        _error = 'This phone number is reserved for admin use';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if phone already exists
      final existingPhone = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: cleanPhone)
          .limit(1)
          .get();

      if (existingPhone.docs.isNotEmpty) {
        _error = 'Phone number already registered';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if email already exists in Firestore
      final existingEmail = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();

      if (existingEmail.docs.isNotEmpty) {
        _error = 'Email address already registered';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Use PHONE-EMAIL for Firebase Auth
      String phoneEmail = '$cleanPhone@ssatravels.com';

      // Create user in Firebase Auth with PHONE-EMAIL
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: phoneEmail,
        password: password,
      );

      // Update user profile
      await userCredential.user!.updateDisplayName(fullName);

      // Create user document in Firestore with REAL EMAIL
      _userData = {
        'uid': userCredential.user!.uid,
        'phoneNumber': cleanPhone,
        'email': email.trim(),
        'fullName': fullName.trim(),
        'isAdmin': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(_userData!);

      // Update state
      _isLoggedIn = true;
      _isAdmin = false;
      _phoneNumber = cleanPhone;
      _firebaseUser = userCredential.user;

      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getRegistrationErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Registration failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _getRegistrationErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this phone number';
      case 'invalid-email':
        return 'Invalid phone number format';
      case 'operation-not-allowed':
        return 'Registration is not enabled. Contact admin.';
      case 'weak-password':
        return 'Password is too weak';
      default:
        return 'Registration failed. Please try again';
    }
  }

  // ============================================
  // PASSWORD RESET METHOD - UPDATED WITH BETTER FEEDBACK
  // ============================================
  Future<bool> sendPasswordResetEmail({
    required String phoneNumber,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      String cleanPhone = _cleanPhoneNumber(phoneNumber);

      // Don't allow password reset for admin
      if (cleanPhone == AdminConfig.adminPhone) {
        _error =
            'Admin password cannot be reset through this method. Contact system administrator.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 1. Find user in Firestore by phone number
      final userQuery = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: cleanPhone)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        _error = 'No account found with this phone number';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // 2. Get user's REAL EMAIL from Firestore (for display)
      final userData = userQuery.docs.first.data();
      String? realEmail = userData['email'];

      // 3. Get phone-email for Firebase Auth
      String phoneEmail = '$cleanPhone@ssatravels.com';

      // 4. Send password reset to phone-email
      await _auth.sendPasswordResetEmail(email: phoneEmail);

      _isLoading = false;
      _error = null;
      notifyListeners();

      // Return true with real email for display in UI
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _getPasswordResetErrorMessage(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to send reset email. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _getPasswordResetErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this phone number';
      case 'invalid-email':
        return 'Invalid phone number format';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      default:
        return 'Failed to send password reset email';
    }
  }

  // ============================================
  // CHECK IF PHONE EXISTS
  // ============================================
  Future<bool> checkPhoneExists(String phoneNumber) async {
    try {
      String cleanPhone = _cleanPhoneNumber(phoneNumber);
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: cleanPhone)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking phone: $e');
      return false;
    }
  }

  // ============================================
  // GET REAL EMAIL BY PHONE
  // ============================================
  Future<String?> getRealEmailByPhone(String phoneNumber) async {
    try {
      String cleanPhone = _cleanPhoneNumber(phoneNumber);
      final querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: cleanPhone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data()['email'];
      }
      return null;
    } catch (e) {
      debugPrint('Error getting email: $e');
      return null;
    }
  }

  // ============================================
  // LOGOUT
  // ============================================
  Future<void> logout() async {
    try {
      if (_firebaseUser != null) {
        await _auth.signOut();
      }

      _isLoggedIn = false;
      _isAdmin = false;
      _phoneNumber = null;
      _userData = null;
      _firebaseUser = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Logout failed: ${e.toString()}';
      notifyListeners();
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================
  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll('+91', '').replaceAll(' ', '').trim();
  }

  bool isAdminPhone(String phoneNumber) {
    String cleanPhone = _cleanPhoneNumber(phoneNumber);
    return cleanPhone == AdminConfig.adminPhone;
  }

  // Update user's real email
  Future<bool> updateRealEmail({required String email}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_firebaseUser == null) {
        _error = 'User not logged in';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Check if email already exists
      final existingEmail = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .where('uid', isNotEqualTo: _firebaseUser!.uid)
          .limit(1)
          .get();

      if (existingEmail.docs.isNotEmpty) {
        _error = 'Email address already in use by another account';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Update real email in Firestore
      await _firestore.collection('users').doc(_firebaseUser!.uid).update(
          {'email': email.trim(), 'updatedAt': FieldValue.serverTimestamp()});

      _userData!['email'] = email.trim();
      _userData!['updatedAt'] = DateTime.now();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update email: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
