// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onAuthError;

  const AuthWrapper({
    Key? key,
    required this.child,
    this.onAuthError,
  }) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _hasError = false;
  String? _errorMessage;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAuthListener();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _setupAuthListener() {
    _auth.authStateChanges().listen((User? user) {
      if (!mounted) return;
      
      if (user == null && !_isChecking) {
        // User logged out - redirect to login
        _redirectToLogin();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App resume aana session check pannu
    if (state == AppLifecycleState.resumed) {
      _verifySession();
    }
  }

  Future<void> _verifySession() async {
    if (_isChecking) return;
    
    setState(() {
      _isChecking = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _redirectToLogin();
        return;
      }

      // Token valid ah nu check pannu
      await user.getIdToken(true);
      
      setState(() {
        _hasError = false;
        _errorMessage = null;
      });
      
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Session expired. Please login again.';
      });
      
      // Automatic logout prevent panna - user ku option kudu
      if (mounted) {
        _showSessionErrorDialog();
      }
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _showSessionErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Error'),
        content: const Text('Your session has expired. Please login again.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _redirectToLogin();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Something went wrong',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _verifySession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                ),
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: _redirectToLogin,
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}