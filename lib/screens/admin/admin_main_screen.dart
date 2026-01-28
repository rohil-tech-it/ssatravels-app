// lib/screens/admin/admin_main_screen.dart - UPDATED VERSION
import 'package:flutter/material.dart';
import 'admin_price_screen.dart';
import 'admin_booking_screen.dart';
import 'admin_dashboard.dart';
import 'admin_profile.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({Key? key}) : super(key: key);

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // Define screens WITH CALLBACKS
  late final List<Widget> _screens;

  final List<String> _appBarTitles = [
    'Admin Dashboard',
    'Price Management',
    'Bookings Management',
    'Admin Profile'
  ];

  @override
  void initState() {
    super.initState();

    // Initialize screens with callbacks
    _screens = [
      // Dashboard with callbacks
      AdminDashboard(
        onViewBookings: () => _switchToTab(2),
        onUpdatePrices: () => _switchToTab(1),
      ),
      // Price Management
      AdminPriceScreen(),
      // Bookings Management
      AdminBookingScreen(),
      // Profile Screen - ADDED
      AdminProfileTab(),
    ];

    print('✅ AdminMainScreen initialized');
    print('✅ Screens count: ${_screens.length}');
    print('✅ Current index: $_currentIndex');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Helper method to switch tabs
  void _switchToTab(int index) {
    print('🔄 Switching to tab: $index');
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _appBarTitles[_currentIndex],
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF00B14F),
        elevation: 2,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          // REMOVED Profile icon from AppBar (now it's in bottom navigation)
        ],
      ),
      drawer: _buildDrawer(context),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          print('📱 Page changed to: $index');
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          print('👆 Bottom nav tapped: $index');
          _switchToTab(index);
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF00B14F),
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: TextStyle(fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        type: BottomNavigationBarType.fixed,
        items: [
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
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
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
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: const Color(0xFF00B14F),
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'SSA Travels',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Drawer Items
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
            icon: Icons.person,
            title: 'Profile',
            index: 3,
          ),
          Divider(height: 20, thickness: 1),
          _buildDrawerItem(
            icon: Icons.directions_car,
            title: 'Vehicles',
            onTap: () {
              // Navigate to vehicles management
              print('🚗 Vehicles clicked');
            },
          ),
          _buildDrawerItem(
            icon: Icons.people,
            title: 'Drivers',
            onTap: () {
              // Navigate to drivers management
              print('👥 Drivers clicked');
            },
          ),
          _buildDrawerItem(
            icon: Icons.route,
            title: 'Routes',
            onTap: () {
              // Navigate to routes management
              print('🗺️ Routes clicked');
            },
          ),
          _buildDrawerItem(
            icon: Icons.bar_chart,
            title: 'Reports',
            onTap: () {
              // Navigate to reports
              print('📊 Reports clicked');
            },
          ),
          Divider(height: 20, thickness: 1),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              // Navigate to settings
              print('⚙️ Settings clicked');
            },
          ),
          _buildDrawerItem(
            icon: Icons.exit_to_app,
            title: 'Logout',
            onTap: () {
              _confirmLogout(context);
            },
            color: Colors.red,
          ),
          _buildFooter(context),
        ],
      ),
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user,
                  color: Color(0xFF00B14F),
                  size: screenWidth * 0.035,
                ),
                SizedBox(width: 6),
                Text(
                  'Secure & Reliable',
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    int? index,
    Color? color,
    VoidCallback? onTap,
  }) {
    bool isSelected = index != null && index == _currentIndex;

    return InkWell(
      onTap: onTap ??
          () {
            Navigator.pop(context);
            if (index != null) {
              _switchToTab(index);
            }
          },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00B14F).withOpacity(0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF00B14F) : Colors.transparent,
              width: 4, // 👉 active side border width
            ),
          ),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: color ??
                (isSelected ? const Color(0xFF00B14F) : Colors.grey[700]),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: color ??
                  (isSelected ? const Color(0xFF00B14F) : Colors.grey[800]),
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
        title: Text('Confirm Logout'),
        content: Text('Are you sure you want to logout from admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}
