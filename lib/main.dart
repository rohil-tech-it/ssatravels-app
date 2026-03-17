// ignore_for_file: avoid_print, duplicate_ignore

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ssatravels_app/screens/admin/admin_dashboard.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/user/user_home_screen.dart';
import 'screens/admin/admin_main_screen.dart';
import 'screens/user/components/booking_tab.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load ENV file
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // ignore: avoid_print
    print("⚠️ .env not found");
  }

  // Initialize Firebase safely
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {}
  } catch (e) {
    print("❌ Firebase init error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SSA Tours & Travels',
        theme: ThemeData(
          primaryColor: const Color(0xFF00B14F),
        ),
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/user-home': (context) => const UserHomeScreen(),       
          '/admin-dashboard': (context) => AdminDashboard(),
          '/admin-home': (context) => const AdminMainScreen(),
          '/booking_tab': (context) => const BookingTab(),
        },
      ),
    );
  }
}
