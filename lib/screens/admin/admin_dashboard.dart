// lib/screens/admin/admin_dashboard.dart - UPDATED with Clickable Toll Routes & Plazas

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../services/toll_service.dart';
import 'admin_vehicle_screen.dart';
import 'package:ssatravels_app/screens/admin/admin_price_screen.dart';
import 'package:ssatravels_app/screens/admin/admin_toll_plazas.dart';
import 'package:ssatravels_app/screens/admin/admin_toll_routes.dart';

class AdminDashboard extends StatefulWidget {
  final VoidCallback? onUpdatePrices;
  final VoidCallback? onManageTollPlazas;
  final VoidCallback? onManageTollRoutes;
  final VoidCallback? onManageVehicles;
  final VoidCallback? onAddVehicle;
  final VoidCallback? onViewBookings;

  const AdminDashboard({
    super.key,
    this.onUpdatePrices,
    this.onManageTollPlazas,
    this.onManageTollRoutes,
    this.onManageVehicles,
    this.onAddVehicle,
    this.onViewBookings,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final TollService _tollService = TollService();

  // Dashboard stats
  int _totalBookings = 0;
  int _activeVehicles = 0;
  int _totalTollPlazas = 0;
  int _totalTollRoutes = 0;
  double _todayRevenue = 0.0;
  double _monthlyRevenue = 0.0;
  int _pendingActions = 0;
  bool _isLoading = true;

  // Responsive variables
  late bool _isMobile;
  late bool _isTablet;
  late double _screenWidth;

  // Admin theme colors
  final Color _adminPrimaryColor = const Color(0xFF00C853);
  final Color _adminBackground = const Color(0xFFF5FDF8);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      DateTime now = DateTime.now();
      DateTime todayStart = DateTime(now.year, now.month, now.day);
      DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      DateTime monthStart = DateTime(now.year, now.month, 1);
      DateTime monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Get stats from TollService
      final stats = await _tollService.getDashboardStats();

      setState(() {
        _activeVehicles = stats['vehicles'] ?? 0;
        _totalTollPlazas = stats['plazas'] ?? 0;
        _totalTollRoutes = stats['routes'] ?? 0;
      });

      // Get total bookings count
      var bookingsSnapshot =
          await FirebaseFirestore.instance.collection('bookings').get();

      _totalBookings = bookingsSnapshot.docs.length;

      // Get today's revenue (only from completed bookings)
      var todayBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('createdAt', isGreaterThanOrEqualTo: todayStart)
          .where('createdAt', isLessThanOrEqualTo: todayEnd)
          .get();

      _todayRevenue = todayBookings.docs.fold(0.0, (total, doc) {
        final data = doc.data();
        String status = data['status']?.toString().toLowerCase() ?? '';
        if (status == 'completed') {
          return total + (data['totalAmount'] ?? 0.0);
        }
        return total;
      });

      // Get monthly revenue (only from completed bookings)
      var monthlyBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('createdAt', isGreaterThanOrEqualTo: monthStart)
          .where('createdAt', isLessThanOrEqualTo: monthEnd)
          .get();

      _monthlyRevenue = monthlyBookings.docs.fold(0.0, (total, doc) {
        final data = doc.data();
        String status = data['status']?.toString().toLowerCase() ?? '';
        if (status == 'completed') {
          return total + (data['totalAmount'] ?? 0.0);
        }
        return total;
      });

      // Get pending actions
      var pendingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('status', whereIn: ['pending', 'processing']).get();
      _pendingActions = pendingSnapshot.docs.length;

      setState(() {
        _isLoading = false;
      });

      print('✅ Dashboard loaded - Clean version');
    } catch (e) {
      print('Error loading dashboard: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    DateTime time = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(time);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('dd MMM yyyy').format(time);
    }
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _isMobile = _screenWidth < 600;
    _isTablet = _screenWidth >= 600 && _screenWidth < 1200;

    return Scaffold(
      backgroundColor: _adminBackground,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: _adminPrimaryColor,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(_isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              _buildWelcomeCard(),
              SizedBox(height: _isMobile ? 16 : 20),

              // Quick Stats Grid
              Text(
                'Quick Overview',
                style: TextStyle(
                  fontSize: _isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: _isMobile ? 10 : 12),
              _buildStatsGrid(),

              SizedBox(height: _isMobile ? 20 : 25),

              // Quick Actions - UPDATED with Toll Routes & Toll Plazas
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: _isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: _isMobile ? 10 : 12),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(_isMobile ? 16 : 20),
        child: Row(
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: _isMobile ? 32 : 40,
              color: _adminPrimaryColor,
            ),
            SizedBox(width: _isMobile ? 12 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Admin!',
                    style: TextStyle(
                      fontSize: _isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: _isMobile ? 3 : 5),
                  Text(
                    'Total Bookings: $_totalBookings',
                    style: TextStyle(
                      color: _adminPrimaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: _isMobile ? 12 : 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Manage your systems efficiently',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: _isMobile ? 11 : 13,
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              CircularProgressIndicator(
                color: _adminPrimaryColor,
                strokeWidth: 2,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_isLoading) return _buildLoadingStats();

    int crossAxisCount = _isMobile ? 2 : 4;
    double childAspectRatio = _isMobile ? 1.2 : 1.3;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: _isMobile ? 8 : 12,
      mainAxisSpacing: _isMobile ? 8 : 12,
      childAspectRatio: childAspectRatio,
      children: [
        _buildStatCard(
          title: 'Active Vehicles',
          value: '$_activeVehicles',
          icon: Icons.directions_car,
          color: _adminPrimaryColor,
          subTitle: 'Operational',
          onTap: () => _navigateToVehicleScreen(),
        ),
        _buildStatCard(
          title: 'Toll Plazas',
          value: '$_totalTollPlazas',
          icon: Icons.location_on,
          color: Colors.orange,
          subTitle: 'Click to manage',
          onTap: () => _navigateToTollPlazas(),
        ),
        _buildStatCard(
          title: 'Toll Routes',
          value: '$_totalTollRoutes',
          icon: Icons.route,
          color: Colors.purple,
          subTitle: 'Click to manage',
          onTap: () => _navigateToTollRoutes(),
        ),
        _buildStatCard(
          title: "Today's Revenue",
          value: _formatCurrency(_todayRevenue),
          icon: Icons.currency_rupee,
          color: Colors.green,
          subTitle: 'From completed bookings',
        ),
        _buildStatCard(
          title: 'Monthly Revenue',
          value: _formatCurrency(_monthlyRevenue),
          icon: Icons.bar_chart,
          color: Colors.teal,
          subTitle: DateFormat('MMMM yyyy').format(DateTime.now()),
        ),
        _buildStatCard(
          title: 'Pending Actions',
          value: '$_pendingActions',
          icon: Icons.pending_actions,
          color: Colors.amber,
          subTitle: 'Awaiting response',
        ),
        _buildStatCard(
          title: 'Total Bookings',
          value: '$_totalBookings',
          icon: Icons.book,
          color: Colors.blue,
          subTitle: 'Click to view',
          onTap: widget.onViewBookings,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subTitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(_isMobile ? 12 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(_isMobile ? 6 : 8),
                    decoration: BoxDecoration(
                      color: color.withAlpha((0.1 * 255).round()),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: _isMobile ? 16 : 20),
                  ),
                ],
              ),
              SizedBox(height: _isMobile ? 8 : 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: _isMobile ? 18 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: _isMobile ? 11 : 13,
                ),
              ),
              if (subTitle != null) ...[
                SizedBox(height: _isMobile ? 2 : 4),
                Text(
                  subTitle,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: _isMobile ? 9 : 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingStats() {
    int crossAxisCount = _isMobile ? 2 : 4;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: _isMobile ? 8 : 12,
      mainAxisSpacing: _isMobile ? 8 : 12,
      childAspectRatio: _isMobile ? 1.2 : 1.3,
      children: List.generate(7, (index) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(_isMobile ? 12 : 16),
            child: Center(
              child: CircularProgressIndicator(
                color: _adminPrimaryColor,
                strokeWidth: 2,
              ),
            ),
          ),
        );
      }),
    );
  }

  // UPDATED: Quick Actions with Toll Routes & Toll Plazas
  Widget _buildQuickActions() {
    int crossAxisCount = _isMobile ? 2 : 4;
    double childAspectRatio = _isMobile ? 1.4 : 1.5;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: _isMobile ? 8 : 12,
      mainAxisSpacing: _isMobile ? 8 : 12,
      childAspectRatio: childAspectRatio,
      children: [
        _buildActionCard(
          title: 'View Bookings',
          icon: Icons.book,
          onTap: widget.onViewBookings ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Navigate to Bookings')),
                );
              },
        ),
        _buildActionCard(
          title: 'Update Prices',
          icon: Icons.price_change,
          onTap: widget.onUpdatePrices ?? () {},
        ),
        _buildActionCard(
          title: 'Toll Plazas', // NEW: Clickable Toll Plazas
          icon: Icons.location_on,
          onTap: widget.onManageTollPlazas ?? _navigateToTollPlazas,
        ),
        _buildActionCard(
          title: 'Toll Routes', // NEW: Clickable Toll Routes
          icon: Icons.route,
          onTap: widget.onManageTollRoutes ?? _navigateToTollRoutes,
        ),
        _buildActionCard(
          title: 'Add Vehicle',
          icon: Icons.add_circle_outline,
          onTap: widget.onAddVehicle ?? _navigateToVehicleScreen,
        ),
      ],
    );
  }

  // Navigation methods
  void _navigateToTollPlazas() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminTollPlazas()),
    );
  }

  void _navigateToTollRoutes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminTollRoutesScreen()),
    );
  }

  void _navigateToVehicleScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminAddVehicleManagement()),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(_isMobile ? 12 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: _isMobile ? 24 : 30,
                color: _adminPrimaryColor,
              ),
              SizedBox(height: _isMobile ? 6 : 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  fontSize: _isMobile ? 12 : 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
