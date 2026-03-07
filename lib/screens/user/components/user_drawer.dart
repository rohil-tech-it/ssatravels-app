import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ssatravels_app/screens/auth/login_screen.dart';
import 'package:ssatravels_app/screens/user/components/about_page.dart';
import 'package:ssatravels_app/screens/user/components/help_support_page.dart';
import 'package:ssatravels_app/screens/user/components/privacy_policy_page.dart';
import 'package:ssatravels_app/screens/user/components/booking_history_page.dart';
import 'package:ssatravels_app/screens/user/components/settings_page.dart';
import 'package:ssatravels_app/screens/user/components/terms_conditions_page.dart';

class UserDrawer extends StatelessWidget {
  final int currentIndex;
  final String userName;
  final Function(int) onIndexChanged;

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  const UserDrawer({
    super.key,
    required this.currentIndex,
    required this.userName,
    required this.onIndexChanged,
  });

  // CALL FUNCTION – HERE
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

  // Get responsive font size based on screen width
  double _getResponsiveFontSize(BuildContext context,
      {double mobile = 14, double tablet = 16, double desktop = 18}) {
    double width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) return desktop;
    if (width >= tabletBreakpoint) return tablet;
    return mobile;
  }

  // Get responsive padding based on screen width
  EdgeInsets _getResponsivePadding(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    if (width >= desktopBreakpoint) {
      return EdgeInsets.symmetric(horizontal: width * 0.03, vertical: 16);
    } else if (width >= tabletBreakpoint) {
      return EdgeInsets.symmetric(horizontal: width * 0.04, vertical: 12);
    } else {
      return EdgeInsets.symmetric(horizontal: width * 0.05, vertical: 8);
    }
  }

  // Get responsive drawer width
  double _getDrawerWidth(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    if (width >= desktopBreakpoint) {
      return width * 0.25; // 25% of screen width for desktop
    } else if (width >= tabletBreakpoint) {
      return width * 0.4; // 40% of screen width for tablet
    } else if (width >= mobileBreakpoint) {
      return width * 0.7; // 70% of screen width for large phones
    } else {
      return width * 0.85; // 85% of screen width for small phones
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _getDrawerWidth(context),
      child: Drawer(
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
          'Booking History',
          null,
          onTap: () {
            _showLoginPrompt(context);
          },
        ),
        _drawerItem(
          context,
          Icons.call,
          'Contact Us',
          7,
          onTap: () {
            Navigator.pop(context);
            _callContactNumber();
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

        // Main navigation
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
          'Booking History',
          null,
          onTap: () => _navigateToPage(context, const BookingHistoryPage()),
        ),
        _drawerItem(
          context,
          Icons.call,
          'Contact Us',
          7,
          onTap: () {
            Navigator.pop(context);
            _callContactNumber();
          },
        ),

        if (FirebaseAuth.instance.currentUser != null) ...[
          const Divider(height: 1),
          _drawerItem(
            context,
            Icons.person_outline,
            'My Profile',
            3,
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

        _buildFooter(context),
      ],
    );
  }

  // ================= FOOTER SECTION =================
  Widget _buildFooter(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.only(
        top: screenHeight * 0.02,
        bottom: screenHeight * 0.02 + MediaQuery.of(context).padding.bottom,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Divider(color: Colors.grey[300], height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.code,
                color: Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Developed by Rohil Technologies',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context,
                        mobile: 11, tablet: 12, desktop: 13),
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= NAVIGATION HELPERS =================
  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _showLoginPrompt(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please login to view your booking history.'),
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      color: const Color(0xFF00B14F),
      padding: EdgeInsets.only(
        top: screenHeight * 0.04,
        bottom: screenHeight * 0.02,
        left: screenWidth * 0.04,
        right: screenWidth * 0.04,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: screenWidth * 0.1,
                height: screenWidth * 0.1,
                child: Center(
                  child: Image.asset(
                    'assets/ssa-logo.png',
                    height: screenWidth * 0.06,
                    fit: BoxFit.contain,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: Text(
                  'Travels Virudhunagar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context,
                        mobile: 16, tablet: 18, desktop: 20),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: screenWidth * 0.15,
                height: screenWidth * 0.15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00B14F),
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello Guest!',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context,
                            mobile: 12, tablet: 13, desktop: 14),
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      'Welcome to SSA Travels',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context,
                            mobile: 16, tablet: 17, desktop: 18),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      'Please login to book rides',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context,
                            mobile: 11, tablet: 12, desktop: 13),
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          Container(
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.01,
              horizontal: screenWidth * 0.03,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF008E3C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_taxi_outlined,
                  color: Colors.white70,
                  size: screenWidth * 0.035,
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    '24/7 Taxi Service Available',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: _getResponsiveFontSize(context,
                          mobile: 11, tablet: 12, desktop: 13),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: _getResponsiveFontSize(context,
                        mobile: 10, tablet: 11, desktop: 12),
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      color: const Color(0xFF00B14F),
      padding: EdgeInsets.only(
        top: screenHeight * 0.04,
        bottom: screenHeight * 0.02,
        left: screenWidth * 0.04,
        right: screenWidth * 0.04,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: screenWidth * 0.1,
                height: screenWidth * 0.1,
                child: Center(
                  child: Image.asset(
                    'assets/ssa-logo.png',
                    height: screenWidth * 0.06,
                    fit: BoxFit.contain,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: Text(
                  'Travels Virudhunagar',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _getResponsiveFontSize(context,
                        mobile: 16, tablet: 18, desktop: 20),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserAvatar(context, photoURL, screenWidth * 0.15, fullName),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context,
                            mobile: 12, tablet: 13, desktop: 14),
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context,
                            mobile: 16, tablet: 17, desktop: 18),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: _getResponsiveFontSize(context,
                            mobile: 11, tablet: 12, desktop: 13),
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (phoneNumber.isNotEmpty) ...[
                      SizedBox(height: screenHeight * 0.002),
                      Text(
                        phoneNumber,
                        style: TextStyle(
                          fontSize: _getResponsiveFontSize(context,
                              mobile: 10, tablet: 11, desktop: 12),
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          Container(
            padding: EdgeInsets.symmetric(
              vertical: screenHeight * 0.01,
              horizontal: screenWidth * 0.03,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF008E3C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_taxi_outlined,
                  color: Colors.white70,
                  size: screenWidth * 0.035,
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    '24/7 Taxi Service Available',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: _getResponsiveFontSize(context,
                          mobile: 11, tablet: 12, desktop: 13),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: _getResponsiveFontSize(context,
                        mobile: 10, tablet: 11, desktop: 12),
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
  Widget _buildUserAvatar(
      BuildContext context, String? photoURL, double size, String fullName) {
    if (photoURL != null && photoURL.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
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
        border: Border.all(color: Colors.white, width: 2),
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

  // ================= DRAWER ITEM =================
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
          size: _getResponsiveFontSize(context,
              mobile: 20, tablet: 22, desktop: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: _getResponsiveFontSize(context,
                mobile: 14, tablet: 15, desktop: 16),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: color ??
                (isSelected ? const Color(0xFF00B14F) : Colors.grey[800]),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: index != null
            ? Icon(
                Icons.chevron_right_rounded,
                size: _getResponsiveFontSize(context,
                    mobile: 18, tablet: 20, desktop: 22),
                color: Colors.grey[400],
              )
            : null,
        contentPadding: _getResponsivePadding(context),
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
            SnackBar(
              content: Text(
                'Logged out successfully',
                style: TextStyle(
                    fontSize: _getResponsiveFontSize(context,
                        mobile: 14, tablet: 15, desktop: 16)),
              ),
              backgroundColor: const Color(0xFF00B14F),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Logout failed: $e',
                style: TextStyle(
                    fontSize: _getResponsiveFontSize(context,
                        mobile: 14, tablet: 15, desktop: 16)),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
