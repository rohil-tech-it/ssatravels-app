// lib/screens/admin/admin_price_screen.dart (Fully Updated)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ssatravels_app/services/firebase_services.dart';
import 'package:ssatravels_app/services/toll_service.dart';

class AdminPriceScreen extends StatefulWidget {
  const AdminPriceScreen({super.key});

  @override
  _AdminPriceScreenState createState() => _AdminPriceScreenState();
}

class _AdminPriceScreenState extends State<AdminPriceScreen> {
  late Map<String, dynamic> _rateCard = {};
  bool _isLoading = true;
  
  // Dynamic list of vehicles from Firebase
  List<Map<String, dynamic>> _vehicles = [];
  
  // Error state
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load all data in parallel
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Load both rate cards and vehicles in parallel
      await Future.wait([
        _loadRateCards(),
        _loadVehiclesFromFirebase(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load vehicles directly from Firebase
  Future<void> _loadVehiclesFromFirebase() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('vehicles').get();
      
      final List<Map<String, dynamic>> vehicles = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        
        // Only include active vehicles
        if (data['isActive'] == true) {
          vehicles.add({
            'id': doc.id,  // This will be 'access', 'hatchback', etc.
            'name': data['name'] ?? doc.id,
            'displayName': data['displayName'] ?? _formatDisplayName(doc.id),
            'seats': data['seatingCapacity'] ?? 4,
            'category': data['category'] ?? 'vehicle',
            'model': data['model'] ?? '',
            'isActive': data['isActive'] ?? true,
          });
        }
      }
      
      // Sort vehicles by displayName
      vehicles.sort((a, b) => a['displayName'].compareTo(b['displayName']));
      
      setState(() {
        _vehicles = vehicles;
      });
      
      print('✅ Loaded ${vehicles.length} vehicles from Firebase');
      print('Vehicle IDs: ${vehicles.map((v) => v['id']).toList()}');
    } catch (e) {
      print('Error loading vehicles: $e');
      // Fallback to empty list
      setState(() {
        _vehicles = [];
      });
      rethrow;
    }
  }

  // Format Firebase key to display name if no displayName field
  String _formatDisplayName(String key) {
    return key.replaceAll('_', ' ').split(' ').map((word) => 
      word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }

  // Load rate cards from Firebase
  Future<void> _loadRateCards() async {
    try {
      final rates = await FirebaseService.getAllRateCards();
      setState(() {
        _rateCard = rates;
      });
      print('✅ Loaded ${rates.length} rate cards');
    } catch (e) {
      print('Error loading rate cards: $e');
      rethrow;
    }
  }

  // Update vehicle rates in Firebase
  Future<void> _updateVehicleRate(
      String vehicleId, Map<String, dynamic> newRates) async {
    try {
      await FirebaseService.updateRateCard(vehicleId, newRates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rates updated successfully!'),
            backgroundColor: const Color(0xFF00B14F),
            duration: Duration(seconds: 2),
          ),
        );
      }

      await _loadRateCards(); // Refresh rate card data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)))
          : _errorMessage != null
              ? _buildErrorWidget()
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Info
                        _buildHeaderCard(),
                        const SizedBox(height: 20),
                        // List of Vehicles from Firebase
                        Expanded(
                          child: _vehicles.isEmpty
                              ? _buildEmptyState()
                              : ListView.builder(
                                  itemCount: _vehicles.length,
                                  itemBuilder: (context, index) {
                                    final vehicle = _vehicles[index];
                                    final vehicleId = vehicle['id']; // Firebase document ID
                                    final displayName = vehicle['displayName'];
                                    final seats = vehicle['seats'];
                                    
                                    // Get rate card data for this vehicle
                                    Map<String, dynamic>? vehicleData = _rateCard[vehicleId];
                                    
                                    // If no rate card exists, create default structure
                                    if (vehicleData == null) {
                                      vehicleData = {
                                        'seats': seats,
                                        'below200': _getDefaultBelow200(vehicleId, displayName),
                                        'above200': _getDefaultAbove200(vehicleId, displayName),
                                      };
                                    }
                                    
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 3,
                                      child: ExpansionTile(
                                        leading: const Icon(Icons.directions_car,
                                            color: Color(0xFF00C853)),
                                        title: Text(
                                          displayName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                        subtitle: Text(
                                          'Seats: ${vehicleData['seats'] ?? seats} | Tap to edit prices',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: _buildRateEditor(vehicle, vehicleData),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      color: const Color(0xFFE8F5E9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Color(0xFF00C853)),
                const SizedBox(width: 8),
                Text(
                  'Price Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Update prices for vehicles. New vehicles added in Vehicle Management will appear here automatically.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            if (_vehicles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '${_vehicles.length} vehicles available',
                  style: const TextStyle(
                    color: Color(0xFF00C853),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No Vehicles Available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add vehicles in Vehicle Management first',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Rate Editor Widget
  Widget _buildRateEditor(Map<String, dynamic> vehicle, Map<String, dynamic> vehicleData) {
    final vehicleId = vehicle['id'];
    final displayName = vehicle['displayName'];
    
    Map<String, dynamic> below200 = vehicleData['below200'] ?? {};
    Map<String, dynamic> above200 = vehicleData['above200'] ?? {};
    int seats = vehicleData['seats'] ?? vehicle['seats'] ?? 4;

    // Create controllers with current values
    final below200Controllers = <String, TextEditingController>{};
    final above200Controllers = <String, TextEditingController>{};

    below200.forEach((key, value) {
      below200Controllers[key] = TextEditingController(text: value.toString());
    });

    above200.forEach((key, value) {
      above200Controllers[key] = TextEditingController(text: value.toString());
    });

    // If no controllers created, add default fields based on vehicle type
    if (below200Controllers.isEmpty) {
      final defaultBelow200 = _getDefaultBelow200(vehicleId, displayName);
      defaultBelow200.forEach((key, value) {
        below200Controllers[key] = TextEditingController(text: value.toString());
      });
    }
    
    if (above200Controllers.isEmpty) {
      final defaultAbove200 = _getDefaultAbove200(vehicleId, displayName);
      defaultAbove200.forEach((key, value) {
        above200Controllers[key] = TextEditingController(text: value.toString());
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seats (editable)
        Row(
          children: [
            const Icon(Icons.people, color: Colors.grey, size: 18),
            const SizedBox(width: 8),
            const Text('Seats Capacity:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            Container(
              width: 80,
              child: TextFormField(
                initialValue: seats.toString(),
                onChanged: (value) {
                  // Update seats in vehicleData
                  vehicleData['seats'] = int.tryParse(value) ?? seats;
                },
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Below 200 KM Rates
        _buildRateSection(
          title: 'BELOW 200 KM RATES',
          controllers: below200Controllers,
          onSave: () async {
            // Create updated below200 map
            final updatedBelow200 = <String, dynamic>{};
            below200Controllers.forEach((key, controller) {
              updatedBelow200[key] = double.tryParse(controller.text) ?? 0.0;
            });

            // Get current vehicle data
            final currentData = _rateCard[vehicleId] ?? {};

            // Prepare updated data
            final updatedData = Map<String, dynamic>.from(currentData);
            updatedData['below200'] = updatedBelow200;
            updatedData['above200'] = currentData['above200'] ?? above200;
            updatedData['seats'] = int.tryParse(vehicleData['seats'].toString()) ?? seats;
            updatedData['updatedAt'] = FieldValue.serverTimestamp();

            // Update in Firebase
            await _updateVehicleRate(vehicleId, updatedData);
          },
        ),

        const SizedBox(height: 24),

        // Above 200 KM Rates
        _buildRateSection(
          title: 'ABOVE 200 KM RATES',
          controllers: above200Controllers,
          onSave: () async {
            // Create updated above200 map
            final updatedAbove200 = <String, dynamic>{};
            above200Controllers.forEach((key, controller) {
              updatedAbove200[key] = double.tryParse(controller.text) ?? 0.0;
            });

            // Get current vehicle data
            final currentData = _rateCard[vehicleId] ?? {};

            // Prepare updated data
            final updatedData = Map<String, dynamic>.from(currentData);
            updatedData['below200'] = currentData['below200'] ?? below200;
            updatedData['above200'] = updatedAbove200;
            updatedData['seats'] = int.tryParse(vehicleData['seats'].toString()) ?? seats;
            updatedData['updatedAt'] = FieldValue.serverTimestamp();

            // Update in Firebase
            await _updateVehicleRate(vehicleId, updatedData);
          },
        ),

        const SizedBox(height: 20),

        // Save All Button
        Center(
          child: ElevatedButton.icon(
            onPressed: () async {
              // Create updated below200 map
              final updatedBelow200 = <String, dynamic>{};
              below200Controllers.forEach((key, controller) {
                updatedBelow200[key] = double.tryParse(controller.text) ?? 0.0;
              });

              // Create updated above200 map
              final updatedAbove200 = <String, dynamic>{};
              above200Controllers.forEach((key, controller) {
                updatedAbove200[key] = double.tryParse(controller.text) ?? 0.0;
              });

              // Prepare complete updated data
              final updatedData = <String, dynamic>{};
              updatedData['below200'] = updatedBelow200;
              updatedData['above200'] = updatedAbove200;
              updatedData['seats'] = int.tryParse(vehicleData['seats'].toString()) ?? seats;
              updatedData['updatedAt'] = FieldValue.serverTimestamp();

              // Update in Firebase
              await _updateVehicleRate(vehicleId, updatedData);
            },
            icon: const Icon(Icons.save, size: 20),
            label: Text('SAVE ALL CHANGES FOR $displayName'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C853),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRateSection({
    required String title,
    required Map<String, TextEditingController> controllers,
    required VoidCallback onSave,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Save Section'),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Rate fields in a grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3,
          ),
          itemCount: controllers.length,
          itemBuilder: (context, index) {
            String key = controllers.keys.elementAt(index);
            TextEditingController controller = controllers[key]!;

            return TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: _getFieldLabel(key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixText: _isAmountField(key) ? '₹ ' : '',
                suffixText: _getFieldSuffix(key),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14),
            );
          },
        ),
      ],
    );
  }

  // Helper methods for field labels
  String _getFieldLabel(String key) {
    Map<String, String> labels = {
      'hourlyRate': 'Hourly Rate',
      'perKm': 'Rate per KM',
      'driverFood': 'Driver Food',
      'nightHalt': 'Night Halt',
      'minHours': 'Minimum Hours',
      'dailyRent': 'Daily Rent',
      'includedKm': 'Included KM',
      'extraPerKm': 'Extra per KM',
      'driverAllowance': 'Driver Allowance',
    };
    return labels[key] ?? key;
  }

  String _getFieldSuffix(String key) {
    if (key == 'perKm' || key == 'extraPerKm') return '/km';
    if (key == 'hourlyRate') return '/hour';
    if (key == 'minHours') return ' hours';
    if (key == 'includedKm') return ' km';
    return '';
  }

  bool _isAmountField(String key) {
    List<String> amountFields = [
      'hourlyRate',
      'perKm',
      'driverFood',
      'nightHalt',
      'dailyRent',
      'extraPerKm',
      'driverAllowance'
    ];
    return amountFields.contains(key);
  }

  // Default values based on vehicle ID or display name
  Map<String, dynamic> _getDefaultBelow200(String vehicleId, String displayName) {
    final String key = vehicleId.toLowerCase();
    
    // Hatchback/Access
    if (key.contains('access') || key.contains('hatchback') || displayName.contains('Access')) {
      return {
        'hourlyRate': 100.0,
        'perKm': 9.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
        'minHours': 8,
      };
    }
    // Zest
    else if (key.contains('zest') || displayName.contains('Zest')) {
      return {
        'hourlyRate': 100.0,
        'perKm': 9.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
        'minHours': 8,
      };
    }
    // Sedan
    else if (key.contains('sedan')) {
      return {
        'hourlyRate': 150.0,
        'perKm': 9.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
        'minHours': 8,
      };
    }
    // Innova
    else if (key.contains('innova')) {
      return {
        'hourlyRate': 240.0,
        'perKm': 40.0,
        'driverFood': 0.0,
        'nightHalt': 100.0,
        'minHours': 8,
      };
    }
    // Tavera
    else if (key.contains('tavera')) {
      return {
        'hourlyRate': 240.0,
        'perKm': 90.0,
        'driverFood': 0.0,
        'nightHalt': 100.0,
        'minHours': 8,
      };
    }
    // Ertiga
    else if (key.contains('ertiga')) {
      return {
        'hourlyRate': 270.0,
        'perKm': 9.0,
        'driverFood': 0.0,
        'nightHalt': 100.0,
        'minHours': 8,
      };
    }
    // Tempo Traveller
    else if (key.contains('tempo')) {
      return {
        'dailyRent': 3600.0,
        'includedKm': 40.0,
        'extraPerKm': 16.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      };
    }
    // Tourist Van
    else if (key.contains('tourist')) {
      return {
        'dailyRent': 3600.0,
        'includedKm': 340.0,
        'extraPerKm': 16.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      };
    }
    // Van 407
    else if (key.contains('van') || key.contains('407')) {
      return {
        'dailyRent': 3800.0,
        'extraPerKm': 18.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      };
    }
    
    // Default
    return {
      'hourlyRate': 100.0,
      'perKm': 10.0,
      'driverFood': 100.0,
      'nightHalt': 100.0,
      'minHours': 8,
    };
  }

  Map<String, dynamic> _getDefaultAbove200(String vehicleId, String displayName) {
    final String key = vehicleId.toLowerCase();
    
    // Hatchback/Access
    if (key.contains('access') || key.contains('hatchback') || displayName.contains('Access')) {
      return {
        'perKm': 10.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      };
    }
    // Zest
    else if (key.contains('zest') || displayName.contains('Zest')) {
      return {
        'perKm': 10.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      };
    }
    // Sedan
    else if (key.contains('sedan')) {
      return {
        'perKm': 11.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      };
    }
    // Innova
    else if (key.contains('innova')) {
      return {
        'perKm': 15.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      };
    }
    // Tavera
    else if (key.contains('tavera')) {
      return {
        'perKm': 15.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      };
    }
    // Ertiga
    else if (key.contains('ertiga')) {
      return {
        'perKm': 16.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      };
    }
    // Tempo Traveller
    else if (key.contains('tempo')) {
      return {
        'perKm': 25.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      };
    }
    // Tourist Van
    else if (key.contains('tourist')) {
      return {
        'perKm': 25.0,
        'driverAllowance': 500.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      };
    }
    // Van 407
    else if (key.contains('van') || key.contains('407')) {
      return {
        'perKm': 27.0,
        'driverAllowance': 500.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      };
    }
    
    // Default
    return {
      'perKm': 12.0,
      'driverAllowance': 300.0,
      'driverFood': 100.0,
      'nightHalt': 100.0,
    };
  }
}