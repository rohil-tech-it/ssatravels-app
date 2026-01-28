import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ssatravels_app/screens/auth/login_screen.dart';
import 'package:ssatravels_app/screens/user/components/about_page.dart';
import 'package:ssatravels_app/screens/user/components/help_support_page.dart';
import 'package:ssatravels_app/screens/user/components/privacy_policy_page.dart';
import 'package:ssatravels_app/screens/user/components/ride_history_page.dart';
import 'package:ssatravels_app/screens/user/components/settings_page.dart';
import 'package:ssatravels_app/screens/user/components/terms_conditions_page.dart';

class UserDrawer extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;

  // ✅ CALL FUNCTION – HERE
  Future<void> _callContactNumber() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: '9751867879',
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      debugPrint('Could not launch phone dialer');
    }
  }

  const UserDrawer({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnapshot) {
          final user = authSnapshot.data;
          final isLoggedIn = user != null;

          if (!isLoggedIn) {
            return _buildGuestView(context);
          }

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              final userData =
                  userSnapshot.data?.data() as Map<String, dynamic>?;
              final fullName =
                  userData?['fullName'] ?? user.displayName ?? 'User';
              final email = userData?['email'] ?? user.email ?? 'No email';
              final phoneNumber =
                  userData?['phoneNumber'] ?? user.phoneNumber ?? '';

              return _buildLoggedInView(
                context,
                fullName,
                email,
                phoneNumber,
                user.photoURL,
              );
            },
          );
        },
      ),
    );
  }

  // ================= GUEST VIEW =================
  Widget _buildGuestView(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildGuestHeader(context),

        // Menu items for guest
        _drawerItem(context, Icons.home, 'Home', 0, isDrawerItem: true),
        _drawerItem(context, Icons.directions_car, 'Book Trip', 1,
            isDrawerItem: true),

        const Divider(height: 1),

        // Navigation to pages
        _drawerItem(
          context,
          Icons.policy,
          'Privacy Policy',
          null,
          onTap: () => _navigateToPage(context, const PrivacyPolicyPage()),
        ),
        _drawerItem(
          context,
          Icons.description,
          'Terms & Conditions',
          null,
          onTap: () => _navigateToPage(context, const TermsConditionsPage()),
        ),
        _drawerItem(
          context,
          Icons.info_outline,
          'About Us',
          null,
          onTap: () => _navigateToPage(context, const AboutPage()),
        ),
        _drawerItem(
          context,
          Icons.help_outline,
          'Help & Support',
          null,
          onTap: () => _navigateToPage(context, const HelpSupportPage()),
        ),
        _drawerItem(
          context,
          Icons.history,
          'Ride History',
          null,
          onTap: () {
            // Show login prompt for guests
            _showLoginPrompt(context);
          },
        ),
        _drawerItem(
          context,
          Icons.call,
          'Contact Us',
          7,
          onTap: () {
            Navigator.pop(context); // close drawer
            _callContactNumber(); // make call
          },
        ),

        const Divider(height: 1),

        // LOGIN BUTTON
        _drawerItem(
          context,
          Icons.login_rounded,
          'Login / Sign Up',
          null,
          color: const Color(0xFF00B14F),
          onTap: () => _navigateToPage(context, const LoginScreen()),
        ),

        // Footer with "Developed by Rohil Technologies"
        _buildFooter(context),
      ],
    );
  }

  // ================= LOGGED IN VIEW =================
  Widget _buildLoggedInView(
    BuildContext context,
    String fullName,
    String email,
    String phoneNumber,
    String? photoURL,
  ) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildUserHeader(context, fullName, email, phoneNumber, photoURL),

        // Main navigation - Use isDrawerItem: true to change tabs
        _drawerItem(context, Icons.home, 'Home', 0, isDrawerItem: true),
        _drawerItem(context, Icons.directions_car, 'Book Trip', 1,
            isDrawerItem: true),

        const Divider(height: 1),

        // Pages navigation
        _drawerItem(
          context,
          Icons.policy,
          'Privacy Policy',
          null,
          onTap: () => _navigateToPage(context, const PrivacyPolicyPage()),
        ),
        _drawerItem(
          context,
          Icons.description,
          'Terms & Conditions',
          null,
          onTap: () => _navigateToPage(context, const TermsConditionsPage()),
        ),
        _drawerItem(
          context,
          Icons.info_outline,
          'About Us',
          null,
          onTap: () => _navigateToPage(context, const AboutPage()),
        ),
        _drawerItem(
          context,
          Icons.help_outline,
          'Help & Support',
          null,
          onTap: () => _navigateToPage(context, const HelpSupportPage()),
        ),
        _drawerItem(
          context,
          Icons.history,
          'Ride History',
          null,
          onTap: () => _navigateToPage(context, const RideHistoryPage()),
        ),
        _drawerItem(
          context,
          Icons.call,
          'Contact Us',
          7,
          onTap: () {
            Navigator.pop(context); // close drawer
            _callContactNumber(); // make call
          },
        ),

        if (FirebaseAuth.instance.currentUser != null) ...[
          const Divider(height: 1),
          // PROFILE - This will navigate to profile tab (index 3)
          _drawerItem(
            context,
            Icons.person_outline,
            'My Profile',
            3, // Changed from null to 3 to match bottom nav
            isDrawerItem: true,
          ),
          _drawerItem(
            context,
            Icons.settings_outlined,
            'Settings',
            null,
            onTap: () => _navigateToPage(context, const SettingsPage()),
          ),
        ],

        const Divider(height: 1),

        // LOGOUT BUTTON
        _drawerItem(
          context,
          Icons.logout_outlined,
          'Logout',
          null,
          color: Colors.red,
          onTap: () => _handleLogout(context),
        ),

        // Footer with "Developed by Rohil Technologies"
        _buildFooter(context),
      ],
    );
  }

  // ================= FOOTER SECTION =================
  Widget _buildFooter(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      margin: EdgeInsets.only(
        top: 20,
        bottom: 20 + MediaQuery.of(context).padding.bottom,
      ),
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Divider(color: Colors.grey[300], height: 1),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.code,
                color: Colors.grey[600],
                size: screenWidth * 0.04,
              ),
              SizedBox(width: 8),
              Column(
                children: [
                  Text(
                    'Developed by Rohil Technologies',
                    style: TextStyle(
                      fontSize: screenWidth * 0.03, // small font
                      color: Colors.grey[600], // light grey
                      fontWeight: FontWeight.w400, // normal
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= NAVIGATION HELPERS =================
  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    Navigator.pop(context); // Close drawer
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to view your ride history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B14F),
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  // ================= HEADER SECTIONS =================
  Widget _buildGuestHeader(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      color: const Color(0xFF00B14F),
      padding: EdgeInsets.only(
        top: screenHeight * 0.05,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: screenWidth * 0.12,
                height: screenWidth * 0.12,
                child: Center(
                  child: Image.asset(
                    'assets/ssa-logo.png',
                    height: screenWidth * 0.08,
                    fit: BoxFit.contain,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Travels Virudhunagar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.042,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: screenWidth * 0.18,
                height: screenWidth * 0.18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: screenWidth * 0.07,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00B14F),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello Guest!',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Welcome to SSA Travels',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please login to book rides',
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF008E3C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_taxi_outlined,
                  color: Colors.white70,
                  size: screenWidth * 0.04,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '24/7 Taxi Service Available',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: screenWidth * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: screenWidth * 0.03,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(
    BuildContext context,
    String fullName,
    String email,
    String phoneNumber,
    String? photoURL,
  ) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double avatarSize = screenWidth * 0.18;

    return Container(
      color: const Color(0xFF00B14F),
      padding: EdgeInsets.only(
        top: screenHeight * 0.05,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: screenWidth * 0.12,
                height: screenWidth * 0.12,
                child: Center(
                  child: Image.asset(
                    'assets/ssa-logo.png',
                    height: screenWidth * 0.08,
                    fit: BoxFit.contain,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Travels Virudhunagar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.042,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Stack(
                children: [
                  _buildUserAvatar(photoURL, avatarSize, fullName),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        color: Colors.white70,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (phoneNumber.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        phoneNumber,
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF008E3C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_taxi_outlined,
                  color: Colors.white70,
                  size: screenWidth * 0.04,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '24/7 Taxi Service Available',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: screenWidth * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: screenWidth * 0.03,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= AVATAR =================
  Widget _buildUserAvatar(String? photoURL, double size, String fullName) {
    if (photoURL != null && photoURL.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            photoURL,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar(size, fullName);
            },
          ),
        ),
      );
    }

    return _buildDefaultAvatar(size, fullName);
  }

  Widget _buildDefaultAvatar(double size, String fullName) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00B14F),
          ),
        ),
      ),
    );
  }

  // ================= DRAWER ITEM (UPDATED) =================
  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String title,
    int? index, {
    Color? color,
    VoidCallback? onTap,
    bool isDrawerItem = false,
  }) {
    final bool isSelected = index != null && currentIndex == index;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8F5E9) : Colors.transparent,
        border: isSelected
            ? const Border(
                left: BorderSide(
                  color: Color(0xFF00B14F),
                  width: 4,
                ),
              )
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: color ??
              (isSelected ? const Color(0xFF00B14F) : Colors.grey[700]),
          size: screenWidth * 0.06,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: screenWidth * 0.038,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: color ??
                (isSelected ? const Color(0xFF00B14F) : Colors.grey[800]),
          ),
        ),
        trailing: index != null
            ? Icon(
                Icons.chevron_right_rounded,
                size: screenWidth * 0.042,
                color: Colors.grey[400],
              )
            : null,
        contentPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05,
          vertical: screenWidth * 0.02,
        ),
        onTap: onTap ??
            () {
              if (index != null && isDrawerItem) {
                onIndexChanged(index);
              }
              Navigator.pop(context);
            },
      ),
    );
  }

  // ================= LOGOUT HANDLER =================
  Future<void> _handleLogout(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      Navigator.pop(context);

      try {
        await FirebaseAuth.instance.signOut();

        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logged out successfully'),
              backgroundColor: const Color(0xFF00B14F),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
