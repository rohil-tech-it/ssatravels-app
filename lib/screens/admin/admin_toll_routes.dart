//lib/screens/admin/admin_toll_routes.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/toll_service.dart';
import '../../models/toll_route_model.dart';
import '../../data/tamilnadu_toll_routes.dart';

class AdminTollRoutesScreen extends StatefulWidget {
  @override
  _AdminTollRoutesScreenState createState() => _AdminTollRoutesScreenState();
}

class _AdminTollRoutesScreenState extends State<AdminTollRoutesScreen> {
  final TollService _tollService = TollService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _sourceController = TextEditingController();
  final _destinationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _baseTollController = TextEditingController();
  final _searchController = TextEditingController();

  List<String> _sources = [];
  List<String> _destinations = [];
  String _selectedSource = 'All';
  String _selectedDestination = 'All';
  String _searchQuery = '';
  bool _isLoading = false;

  // Updated color - using a vibrant green as requested
  final Color _primaryColor = const Color(0xFF00C853); // Vibrant green color

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    // Get unique sources and destinations from existing routes
    final routes = await _tollService.getAllTollRoutes().first;
    final sources = routes.map((r) => r.source).toSet().toList();
    final destinations = routes.map((r) => r.destination).toSet().toList();
    
    setState(() {
      _sources = ['All', ...sources];
      _destinations = ['All', ...destinations];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Toll Routes Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white, // White text color
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 2,
        iconTheme: IconThemeData(color: Colors.white), // White back button
        actions: [
          // Import Button
          IconButton(
            icon: Icon(Icons.cloud_download, color: Colors.white), // White icon
            onPressed: _showImportDialog,
            tooltip: 'Import from Local Data',
          ),
          // Add Button
          IconButton(
            icon: Icon(Icons.add, color: Colors.white), // White icon
            onPressed: _showAddRouteDialog,
            tooltip: 'Add New Route',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar - Updated to show only one "All" filter
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Search Field
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search routes...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                        prefixIcon: Icon(Icons.search, color: _primaryColor),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Single Filter Dropdown - Shows "All" only once
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: 'All', // Always show "All"
                    onChanged: null, // Disabled since we only show "All"
                    underline: SizedBox(),
                    icon: Icon(Icons.filter_list, color: _primaryColor), // Filter icon
                    items: [
                      DropdownMenuItem(
                        value: 'All',
                        child: Row(
                          children: [
                            Icon(Icons.filter_alt, size: 16, color: _primaryColor),
                            SizedBox(width: 4),
                            Text('All Routes'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Routes List
          Expanded(
            child: StreamBuilder<List<TollRouteModel>>(
              stream: _tollService.getAllTollRoutes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: _primaryColor));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                var routes = snapshot.data ?? [];

                // Apply filters
                if (_searchQuery.isNotEmpty) {
                  routes = routes.where((route) {
                    return route.source.toLowerCase().contains(_searchQuery) ||
                        route.destination.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (routes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.route, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No toll routes found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _showAddRouteDialog,
                          icon: Icon(Icons.add),
                          label: Text('Add First Route'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: routes.length,
                  itemBuilder: (context, index) {
                    final route = routes[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _primaryColor.withOpacity(0.1),
                          child: Icon(Icons.route, color: _primaryColor),
                        ),
                        title: Text(
                          '${route.source} → ${route.destination}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Distance: ${route.distance} km'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '₹${route.baseToll}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showEditRouteDialog(route),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteDialog(route),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== IMPORT DIALOG ====================
  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.cloud_download, color: _primaryColor),
              SizedBox(width: 8),
              Text(
                'Import Toll Routes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This will import all toll routes from local data to Firestore.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This may create duplicate entries if routes already exist.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performImport();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Import'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performImport() async {
    setState(() => _isLoading = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _primaryColor),
              SizedBox(height: 16),
              Text('Importing toll routes...'),
            ],
          ),
        );
      },
    );

    try {
      // Get routes from local data
      final routes = TamilNaduTollRoutes.getAllTollRoutes();
      int successCount = 0;
      
      for (var routeData in routes) {
        final route = TollRouteModel(
          id: routeData['id'],
          source: routeData['source'],
          destination: routeData['destination'],
          distance: routeData['distance'].toDouble(),
          baseToll: routeData['baseToll'].toDouble(),
          tollPlazaIds: List<String>.from(routeData['tollPlazaIds'] ?? []),
          vehicleRates: Map<String, double>.from(routeData['vehicleRates'] ?? {}),
          isActive: routeData['isActive'] ?? true,
        );
        
        await _tollService.addTollRoute(route);
        successCount++;
      }

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('✅ $successCount toll routes imported successfully!')),
            ],
          ),
          backgroundColor: _primaryColor,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('❌ Error: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ==================== ADD ROUTE DIALOG ====================
  void _showAddRouteDialog() {
    _sourceController.clear();
    _destinationController.clear();
    _distanceController.clear();
    _baseTollController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Toll Route'),
        content: Container(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _sourceController,
                  decoration: InputDecoration(
                    labelText: 'Source',
                    hintText: 'e.g., Chennai',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: 'Destination',
                    hintText: 'e.g., Madurai',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _distanceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Distance (km)',
                    hintText: 'e.g., 460',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.straighten),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _baseTollController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Base Toll (₹)',
                    hintText: 'e.g., 580',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addRoute,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
            ),
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addRoute() async {
    try {
      final route = TollRouteModel(
        id: '${_sourceController.text.toLowerCase()}_${_destinationController.text.toLowerCase()}',
        source: _sourceController.text,
        destination: _destinationController.text,
        distance: double.parse(_distanceController.text),
        baseToll: double.parse(_baseTollController.text),
        tollPlazaIds: [],
        vehicleRates: {},
        isActive: true,
      );

      await _tollService.addTollRoute(route);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Route added successfully!'),
          backgroundColor: _primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==================== EDIT ROUTE DIALOG ====================
  void _showEditRouteDialog(TollRouteModel route) {
    _sourceController.text = route.source;
    _destinationController.text = route.destination;
    _distanceController.text = route.distance.toString();
    _baseTollController.text = route.baseToll.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Toll Route'),
        content: Container(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _sourceController,
                  decoration: InputDecoration(
                    labelText: 'Source',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: 'Destination',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _distanceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Distance (km)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.straighten),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _baseTollController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Base Toll (₹)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateRoute(route.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
            ),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateRoute(String routeId) async {
    try {
      final updatedRoute = TollRouteModel(
        id: routeId,
        source: _sourceController.text,
        destination: _destinationController.text,
        distance: double.parse(_distanceController.text),
        baseToll: double.parse(_baseTollController.text),
        tollPlazaIds: [],
        vehicleRates: {},
        isActive: true,
      );

      await _tollService.addTollRoute(updatedRoute);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Route updated successfully!'),
          backgroundColor: _primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==================== DELETE DIALOG ====================
  void _showDeleteDialog(TollRouteModel route) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Toll Route'),
        content: Text('Are you sure you want to delete "${route.source} → ${route.destination}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _tollService.deleteTollRoute(route.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Route deleted successfully!'),
                    backgroundColor: _primaryColor,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sourceController.dispose();
    _destinationController.dispose();
    _distanceController.dispose();
    _baseTollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}