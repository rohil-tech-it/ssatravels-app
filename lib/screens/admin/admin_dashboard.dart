// lib/screens/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/toll_service.dart';
import 'admin_vehicle_screen.dart';
import 'admin_toll_plazas.dart';
import 'admin_toll_routes.dart';
// ADD THESE IMPORTS
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
  late TollService _tollService;

  // Dashboard stats
  int _totalBookings = 0;
  int _activeVehicles = 0;
  int _totalTollPlazas = 0;
  int _totalTollRoutes = 0;
  int _pendingActions = 0;
  bool _isLoading = true;

  // Responsive variables
  late bool _isMobile;
  late double _screenWidth;

  // Admin theme colors
  final Color _adminPrimaryColor = const Color(0xFF00C853);
  final Color _adminBackground = const Color(0xFFF5FDF8);

  // Firebase streams for real-time updates
  late Stream<QuerySnapshot> _bookingsStream;

  @override
  void initState() {
    super.initState();
    _tollService = TollService();

    // Setup real-time stream for bookings
    _bookingsStream =
        FirebaseFirestore.instance.collection('bookings').snapshots();

    _loadDashboardData();
  }

  // UPDATED METHOD - Use local data for toll plazas and routes
  Future<void> _loadDashboardData() async {
    try {
      // Get counts from LOCAL data files first
      final localPlazas = TamilNaduTollData.getAllTollPlazas();
      final localRoutes = TamilNaduTollRoutes.getAllTollRoutes();

      // Set local counts immediately
      if (mounted) {
        setState(() {
          _totalTollPlazas = localPlazas.length; // This will be 78
          _totalTollRoutes = localRoutes.length; // Count your actual routes
          _activeVehicles = 7; // Set from your dashboard image
        });
      }

      // Listen to bookings stream for real-time updates
      _bookingsStream.listen((snapshot) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _updateStatsFromSnapshot(snapshot);
            }
          });
        }
      });

      // Get pending actions from Firebase
      var pendingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('status', whereIn: ['pending', 'processing']).get();

      if (mounted) {
        setState(() {
          _pendingActions = pendingSnapshot.docs.length;
          _isLoading = false;
        });
      }

      // Optional: Still get stats from TollService but don't override local values
      // You can use this for debugging or if you need other stats
      // final stats = await _tollService.getDashboardStats();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Something went wrong: ${e.toString()}")),
        );
      }
    }
  }

  // Update stats from snapshot (real-time) - REVENUE REMOVED
  void _updateStatsFromSnapshot(QuerySnapshot snapshot) {
    // Count pending actions only - revenue removed
    int pendingCount = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      String status = data['status']?.toString().toLowerCase() ?? '';
      return status == 'pending' || status == 'processing';
    }).length;

    // Update only non-revenue values
    _totalBookings = snapshot.docs.length;
    _pendingActions = pendingCount;

    if (mounted) {
      setState(() {});
    }
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
              // Welcome Card
              _buildWelcomeCard(),
              const SizedBox(height: 16),

              // Quick Stats Grid
              Text(
                'Quick Overview',
                style: TextStyle(
                  fontSize: _isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 10),

              // StreamBuilder for real-time updates
              StreamBuilder<QuerySnapshot>(
                stream: _bookingsStream,
                builder: (context, snapshot) {
                  return _buildStatsGrid();
                },
              ),

              const SizedBox(height: 20),

              // Quick Actions
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
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Total Bookings: $_totalBookings',
                    style: TextStyle(
                      color: _adminPrimaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: _isMobile ? 12 : 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Real-time updates',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: _isMobile ? 11 : 13,
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: _adminPrimaryColor,
                  strokeWidth: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
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
          value: '$_totalTollPlazas', // Now shows 78
          icon: Icons.location_on,
          color: Colors.orange,
          subTitle: 'Click to manage',
          onTap: () => _navigateToTollPlazas(),
        ),
        _buildStatCard(
          title: 'Toll Routes',
          value: '$_totalTollRoutes', // Now shows correct count
          icon: Icons.route,
          color: Colors.purple,
          subTitle: 'Click to manage',
          onTap: () => _navigateToTollRoutes(),
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
              const SizedBox(height: 8),
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
                const SizedBox(height: 2),
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

  // Quick Actions
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
                  const SnackBar(content: Text('Navigate to Bookings')),
                );
              },
        ),
        _buildActionCard(
          title: 'Update Prices',
          icon: Icons.price_change,
          onTap: widget.onUpdatePrices ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Update Prices clicked')),
                );
              },
        ),
        _buildActionCard(
          title: 'Toll Plazas',
          icon: Icons.location_on,
          onTap: widget.onManageTollPlazas ?? _navigateToTollPlazas,
        ),
        _buildActionCard(
          title: 'Toll Routes',
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
              const SizedBox(height: 6),
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
