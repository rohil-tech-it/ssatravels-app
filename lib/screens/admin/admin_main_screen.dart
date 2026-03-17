// lib/screens/admin/admin_main_screen.dart
// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'admin_price_screen.dart';
import 'admin_booking_screen.dart';
import 'admin_dashboard.dart';
import 'admin_profile.dart';
import 'admin_toll_plazas.dart';
import 'admin_toll_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // For back button handling
  DateTime? _lastPressedTime;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // For toll sub-navigation
  late TabController _tollTabController;
  int _tollSubIndex = 0;

  // Define screens WITH CALLBACKS
  late final List<Widget> _screens;

  final List<String> _appBarTitles = [
    'Admin Dashboard',
    'Price Management',
    'Bookings Management',
    'Toll Management',
    'Admin Profile'
  ];

  @override
  void initState() {
    super.initState();

    // Initialize toll tab controller
    _tollTabController = TabController(length: 2, vsync: this);
    _tollTabController.addListener(() {
      if (_tollTabController.indexIsChanging) {
        setState(() {
          _tollSubIndex = _tollTabController.index;
        });
      }
    });

    // Initialize screens with callbacks
    _screens = [
      // Dashboard with callbacks
      AdminDashboard(
        onViewBookings: () => _switchToTab(2),
        onUpdatePrices: () => _switchToTab(1),
        onManageTollPlazas: () => _switchToTabWithSubIndex(3, 0),
        onManageTollRoutes: () => _switchToTabWithSubIndex(3, 1),
      ),
      // Price Management
      AdminPriceScreen(),
      // Bookings Management
      AdminBookingScreen(),
      // Toll Management with TabBarView
      _buildTollManagementScreen(),
      // Profile Screen
      AdminProfileTab(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tollTabController.dispose();
    super.dispose();
  }

  // Build Toll Management screen with tabs
  Widget _buildTollManagementScreen() {
    return Column(
      children: [
        // Custom Tab Bar for Toll sub-sections
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tollTabController,
            labelColor: const Color(0xFF00B14F),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF00B14F),
            indicatorWeight: 3,
            tabs: const [
              Tab(
                icon: Icon(Icons.location_on),
                text: 'Toll Plazas',
              ),
              Tab(
                icon: Icon(Icons.route),
                text: 'Toll Routes',
              ),
            ],
          ),
        ),
        // Tab Bar View
        Expanded(
          child: TabBarView(
            controller: _tollTabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              // Toll Plazas Tab
              AdminTollPlazas(),
              // Toll Routes Tab
              AdminTollRoutesScreen(),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to switch tabs with sub-index
  void _switchToTabWithSubIndex(int mainIndex, int subIndex) {
    setState(() {
      _currentIndex = mainIndex;
      _tollSubIndex = subIndex;
    });
    _pageController.jumpToPage(mainIndex);
    _tollTabController.animateTo(subIndex);
  }

  // Helper method to switch tabs
  void _switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  // Navigation methods for toll management
  void _navigateToTollPlazas() {
    _switchToTabWithSubIndex(3, 0);
  }

  void _navigateToTollRoutes() {
    _switchToTabWithSubIndex(3, 1);
  }

  // FIXED: Back button handling with PopScope
  void _onPopInvoked(bool didPop) {
    if (didPop) return; // Pop already happened, nothing to do

    // If drawer is open, close it first
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context); // Close the drawer
      return;
    }

    // If not on Dashboard, go to Dashboard first
    if (_currentIndex != 0) {
      _switchToTab(0);
      _showExitSnackBar('Press back again to exit app');
      return;
    }

    // On Dashboard: double back to exit
    if (_lastPressedTime == null ||
        DateTime.now().difference(_lastPressedTime!) >
            const Duration(seconds: 2)) {
      _lastPressedTime = DateTime.now();
      _showExitSnackBar('Press back again to exit app');
      return;
    }

    // Second press within 2 seconds → exit app
    SystemNavigator.pop();
  }

  void _showExitSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF00B14F),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // We handle all pops manually
      onPopInvoked: _onPopInvoked,
      child: Scaffold(
        key: _scaffoldKey, // Added key to access drawer state
        appBar: AppBar(
          title: Column(
            children: [
              Text(
                _appBarTitles[_currentIndex],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (_currentIndex == 3 && _getTollSubTitle().isNotEmpty)
                Text(
                  _getTollSubTitle(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
          backgroundColor: const Color(0xFF00B14F),
          elevation: 2,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (_currentIndex == 3)
              PopupMenuButton<int>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 0:
                      _navigateToTollPlazas();
                      break;
                    case 1:
                      _navigateToTollRoutes();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 0,
                    child: Row(
                      children: [
                        Icon(Icons.location_on,
                            color: _tollSubIndex == 0
                                ? const Color(0xFF00B14F)
                                : Colors.grey),
                        const SizedBox(width: 8),
                        const Text('Toll Plazas'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 1,
                    child: Row(
                      children: [
                        Icon(Icons.route,
                            color: _tollSubIndex == 1
                                ? const Color(0xFF00B14F)
                                : Colors.grey),
                        const SizedBox(width: 8),
                        const Text('Toll Routes'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            _switchToTab(index);
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF00B14F),
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.price_change_outlined),
              activeIcon: Icon(Icons.price_change),
              label: 'Prices',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.toll_outlined),
              activeIcon: Icon(Icons.toll),
              label: 'Toll',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  String _getTollSubTitle() {
    switch (_tollSubIndex) {
      case 0:
        return 'Toll Plazas';
      case 1:
        return 'Toll Routes';
      default:
        return '';
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF00B14F),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF00B14F), const Color(0xFF00B14F)],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF00B14F),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'SSA Travels',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Navigation Items
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            index: 0,
          ),
          _buildDrawerItem(
            icon: Icons.price_change,
            title: 'Price Management',
            index: 1,
          ),
          _buildDrawerItem(
            icon: Icons.book,
            title: 'Bookings',
            index: 2,
          ),
          _buildDrawerItem(
            icon: Icons.toll,
            title: 'Toll Management',
            index: 3,
          ),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Profile',
            index: 4,
          ),

          const Divider(height: 20, thickness: 1),

          // TOLL MANAGEMENT SUB-SECTIONS
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'TOLL SUB-SECTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
          ),

          _buildDrawerItem(
            icon: Icons.location_on,
            title: 'Toll Plazas',
            onTap: _navigateToTollPlazas,
          ),
          _buildDrawerItem(
            icon: Icons.route,
            title: 'Toll Routes',
            onTap: _navigateToTollRoutes,
          ),
          _buildDrawerItem(
            icon: Icons.exit_to_app,
            title: 'Logout',
            color: Colors.red, // This will make both icon and text red
            onTap: () {
              _confirmLogout(context);
            },
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final bool isDesktop = width > 900;
    final bool isTablet = width > 600 && width <= 900;

    double titleSize = isDesktop
        ? 14
        : isTablet
            ? 13
            : 12;

    double iconSize = isDesktop
        ? 18
        : isTablet
            ? 16
            : 14;

    return Container(
      margin: EdgeInsets.only(
        top: 30,
        bottom: 20 + MediaQuery.of(context).padding.bottom,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Divider(color: Colors.grey[300]),
          const SizedBox(height: 20),

          /// Developer Section
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.code, size: iconSize, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Developed by Rohil Technologies',
                style: TextStyle(
                  fontSize: titleSize,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          /// Secure Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user,
                    size: iconSize, color: const Color(0xFF00B14F)),
                const SizedBox(width: 6),
                Text(
                  'Secure & Reliable',
                  style: TextStyle(
                    fontSize: titleSize,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    Color? iconColor,
    Color? textColor,
    required IconData icon,
    required String title,
    int? index,
    Color? color, // This overrides both colors if provided
    VoidCallback? onTap,
  }) {
    bool isSelected = index != null && index == _currentIndex;

    // Determine the colors to use
    Color getIconColor() {
      if (color != null) return color;
      if (iconColor != null) return iconColor;
      return isSelected ? const Color(0xFF00B14F) : Colors.grey[700]!;
    }

    Color getTextColor() {
      if (color != null) return color;
      if (textColor != null) return textColor;
      return isSelected ? const Color(0xFF00B14F) : Colors.grey[800]!;
    }

    return InkWell(
      onTap: () {
        Navigator.pop(context); // Always close drawer first

        if (onTap != null) {
          onTap();
        } else if (index != null) {
          _switchToTab(index);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00B14F).withValues(alpha: 0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF00B14F) : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: getIconColor(),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: getTextColor(),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content:
            const Text('Are you sure you want to logout from admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00B14F),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              await FirebaseAuth.instance.signOut();

              if (!mounted) return;

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00B14F),
                foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
