import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Use microtask to ensure first frame renders quickly
    Future.microtask(() => _navigateToHome());
  }

  Future<void> _navigateToHome() async {
    // Read context safely
    final authProvider = context.read<AuthProvider>();
    
    // Reduced delay - 2.5 seconds is too long for splash screen
    // 1.5 seconds is more reasonable
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;

    if (authProvider.isLoggedIn) {
      Navigator.pushReplacementNamed(
        context,
        authProvider.isAdmin ? '/admin-home' : '/user-home',
      );
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00B14F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with ClipOval for better performance
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval( // Added ClipOval for better rendering
                child: Image.asset(
                  'assets/ssa-logo.png',
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // App Name - make it const if possible
            const Text(
              'SSA Travels Virudhunagar',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            // Subtitle - withOpacity is expensive, use withValues
            Text(
              'We make it for you',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 60),
            // Loading Indicator - specify size to avoid layout recalculation
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}