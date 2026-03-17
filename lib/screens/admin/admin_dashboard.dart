// lib/screens/admin/admin_dashboard.dart
// ignore_for_file: prefer_final_fields

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'admin_vehicle_screen.dart';
import 'admin_toll_plazas.dart';
import 'admin_toll_routes.dart';

import '../../data/tamilnadu_toll_plazas.dart';
import '../../data/tamilnadu_toll_routes.dart';

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

  // Dashboard stats
  int _totalBookings = 0;
  int _activeVehicles = 7;
  int _totalTollPlazas = 0;
  int _totalTollRoutes = 0;
  int _pendingActions = 0;
  bool _isLoading = true;

  // Responsive variables
  late bool _isMobile;
  late double _screenWidth;

  // Admin colors
  final Color _adminPrimaryColor = const Color(0xFF00C853);
  final Color _adminBackground = const Color(0xFFF5FDF8);

  // Firebase stream
  late Stream<QuerySnapshot> _bookingsStream;
  StreamSubscription<QuerySnapshot>? _bookingSubscription;

  @override
  void initState() {
    super.initState();

    _bookingsStream =
        FirebaseFirestore.instance.collection('bookings').snapshots();

    _loadDashboardData();
  }

  @override
  void dispose() {
    _bookingSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {

      final localPlazas = TamilNaduTollData.getAllTollPlazas();
      final localRoutes = TamilNaduTollRoutes.getAllTollRoutes();

      if (mounted) {
        setState(() {
          _totalTollPlazas = localPlazas.length;
          _totalTollRoutes = localRoutes.length;
        });
      }

      _bookingSubscription = _bookingsStream.listen((snapshot) {
        if (mounted) {
          _updateStatsFromSnapshot(snapshot);
        }
      });

      var pendingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('status', whereIn: ['pending', 'processing'])
          .get();

      if (mounted) {
        setState(() {
          _pendingActions = pendingSnapshot.docs.length;
          _isLoading = false;
        });
      }

    } catch (e) {

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  void _updateStatsFromSnapshot(QuerySnapshot snapshot) {

    int pendingCount = snapshot.docs.where((doc) {

      final data = doc.data() as Map<String, dynamic>;
      String status = data['status']?.toString().toLowerCase() ?? '';

      return status == 'pending' || status == 'processing';

    }).length;

    setState(() {
      _totalBookings = snapshot.docs.length;
      _pendingActions = pendingCount;
    });
  }

  @override
  Widget build(BuildContext context) {

    _screenWidth = MediaQuery.of(context).size.width;
    _isMobile = _screenWidth < 600;

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

              _buildWelcomeCard(),

              const SizedBox(height: 16),

              Text(
                'Quick Overview',
                style: TextStyle(
                  fontSize: _isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(height: 10),

              _buildStatsGrid(),

              const SizedBox(height: 20),

              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: _isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),

              const SizedBox(height: 10),

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

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    'Welcome, Admin!',
                    style: TextStyle(
                      fontSize: _isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    'Total Bookings: $_totalBookings',
                    style: TextStyle(
                      color: _adminPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                ],
              ),
            ),

            if (_isLoading)
              CircularProgressIndicator(
                color: _adminPrimaryColor,
                strokeWidth: 2,
              )

          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {

    int crossAxisCount = _isMobile ? 2 : 4;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.2,
      children: [

        _buildStatCard(
          'Active Vehicles',
          '$_activeVehicles',
          Icons.directions_car,
          _adminPrimaryColor,
          onTap: _navigateToVehicleScreen,
        ),

        _buildStatCard(
          'Toll Plazas',
          '$_totalTollPlazas',
          Icons.location_on,
          Colors.orange,
          onTap: _navigateToTollPlazas,
        ),

        _buildStatCard(
          'Toll Routes',
          '$_totalTollRoutes',
          Icons.route,
          Colors.purple,
          onTap: _navigateToTollRoutes,
        ),

        _buildStatCard(
          'Pending Actions',
          '$_pendingActions',
          Icons.pending_actions,
          Colors.amber,
        ),

        _buildStatCard(
          'Total Bookings',
          '$_totalBookings',
          Icons.book,
          Colors.blue,
          onTap: widget.onViewBookings,
        ),

      ],
    );
  }

  Widget _buildStatCard(
      String title,
      String value,
      IconData icon,
      Color color,
      {VoidCallback? onTap}) {

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

              Icon(icon, color: color),

              const SizedBox(height: 8),

              Text(
                value,
                style: TextStyle(
                  fontSize: _isMobile ? 18 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(title),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: _isMobile ? 2 : 4,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: [

        _buildActionCard('View Bookings', Icons.book, widget.onViewBookings),
        _buildActionCard('Update Prices', Icons.price_change, widget.onUpdatePrices),
        _buildActionCard('Toll Plazas', Icons.location_on, _navigateToTollPlazas),
        _buildActionCard('Toll Routes', Icons.route, _navigateToTollRoutes),
        _buildActionCard('Add Vehicle', Icons.add_circle_outline, _navigateToVehicleScreen),

      ],
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback? onTap) {

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Icon(icon, size: 28, color: _adminPrimaryColor),

            const SizedBox(height: 6),

            Text(title, textAlign: TextAlign.center),

          ],
        ),
      ),
    );
  }

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
}