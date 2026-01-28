import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ssatravels_app/services/firebase_services.dart';

class AdminPriceScreen extends StatefulWidget {
  const AdminPriceScreen({Key? key}) : super(key: key);

  @override
  _AdminPriceScreenState createState() => _AdminPriceScreenState();
}

class _AdminPriceScreenState extends State<AdminPriceScreen> {
  late Map<String, dynamic> _rateCard = {};
  bool _isLoading = true;

  // Define FIXED vehicle types that cannot be changed
  final List<String> _fixedVehicleTypes = [
    'Hatchback',
    'Sedan',
    'Innova',
    'Tavera',
    'Ertiga',
    'Tempo Traveller',
    'Tourist Van',
    'Van 407',
  ];

  @override
  void initState() {
    super.initState();
    _loadRateCards();
  }

  Future<void> _loadRateCards() async {
    try {
      final rates = await FirebaseService.getAllRateCards();
      setState(() {
        _rateCard = rates;
        _isLoading = false;
      });
      print('✅ Loaded ${rates.length} vehicles');
    } catch (e) {
      print('Error loading rate cards: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateVehicleRate(
      String vehicleType, Map<String, dynamic> newRates) async {
    try {
      // Convert display name to Firebase key
      String firebaseKey = _convertToFirebaseKey(vehicleType);

      await FirebaseService.updateRateCard(firebaseKey, newRates);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$vehicleType rates updated successfully!'),
          backgroundColor: const Color(0xFF00B14F),
          duration: Duration(seconds: 2),
        ),
      );

      await _loadRateCards(); // Refresh data
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Helper: Convert display name to Firebase key
  String _convertToFirebaseKey(String displayName) {
    Map<String, String> mapping = {
      'Hatchback': 'hatchback',
      'Sedan': 'sedan',
      'Innova': 'innova',
      'Tavera': 'tavera',
      'Ertiga': 'ertiga',
      'Tempo Traveller': 'tempo traveller',
      'Tourist Van': 'tourist van',
      'Van 407': 'van 407',
    };
    return mapping[displayName] ?? displayName.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF00C853)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info
                  Card(
                    color: Color(0xFFE8F5E9),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Color(0xFF00C853)),
                              SizedBox(width: 8),
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
                          SizedBox(height: 8),
                          Text(
                            'Update prices for existing vehicles only. Vehicle types cannot be added or removed.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // List of Fixed Vehicles
                  Expanded(
                    child: ListView.builder(
                      itemCount: _fixedVehicleTypes.length,
                      itemBuilder: (context, index) {
                        String vehicleType = _fixedVehicleTypes[index];
                        String firebaseKey = _convertToFirebaseKey(vehicleType);
                        Map<String, dynamic>? vehicleData = _rateCard[firebaseKey];

                        // If vehicle not in Firebase, show empty/default
                        if (vehicleData == null) {
                          vehicleData = {
                            'seats': _getDefaultSeats(vehicleType),
                            'below200': _getDefaultBelow200(vehicleType),
                            'above200': _getDefaultAbove200(vehicleType),
                          };
                        }

                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          elevation: 3,
                          child: ExpansionTile(
                            leading: Icon(Icons.directions_car,
                                color: Color(0xFF00C853)),
                            title: Text(
                              vehicleType,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            subtitle: Text(
                              'Seats: ${vehicleData['seats'] ?? "N/A"} | Tap to edit prices',
                              style: TextStyle(fontSize: 12),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildRateEditor(vehicleType, vehicleData),
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
    );
  }

  Widget _buildRateEditor(String vehicleType, Map<String, dynamic> vehicleData) {
    // Get current values
    Map<String, dynamic> below200 = vehicleData['below200'] ?? {};
    Map<String, dynamic> above200 = vehicleData['above200'] ?? {};
    int seats = vehicleData['seats'] ?? 4;

    // Create controllers with current values
    final below200Controllers = <String, TextEditingController>{};
    final above200Controllers = <String, TextEditingController>{};

    below200.forEach((key, value) {
      below200Controllers[key] = TextEditingController(text: value.toString());
    });

    above200.forEach((key, value) {
      above200Controllers[key] = TextEditingController(text: value.toString());
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seats (read-only or limited edit)
        Row(
          children: [
            Icon(Icons.people, color: Colors.grey, size: 18),
            SizedBox(width: 8),
            Text('Seats Capacity:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(width: 12),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xFF00C853).withOpacity(0.3)),
              ),
              child: Text(
                seats.toString(),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00C853)),
              ),
            ),
          ],
        ),

        SizedBox(height: 20),

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
            String firebaseKey = _convertToFirebaseKey(vehicleType);
            final currentData = _rateCard[firebaseKey] ?? {};

            // Prepare updated data - preserve existing above200 and seats
            final updatedData = Map<String, dynamic>.from(currentData);
            updatedData['below200'] = updatedBelow200;
            updatedData['above200'] = currentData['above200'] ?? above200;
            updatedData['seats'] = seats;
            updatedData['updatedAt'] = FieldValue.serverTimestamp();

            // Update in Firebase
            await _updateVehicleRate(vehicleType, updatedData);
          },
        ),

        SizedBox(height: 24),

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
            String firebaseKey = _convertToFirebaseKey(vehicleType);
            final currentData = _rateCard[firebaseKey] ?? {};

            // Prepare updated data - preserve existing below200 and seats
            final updatedData = Map<String, dynamic>.from(currentData);
            updatedData['below200'] = currentData['below200'] ?? below200;
            updatedData['above200'] = updatedAbove200;
            updatedData['seats'] = seats;
            updatedData['updatedAt'] = FieldValue.serverTimestamp();

            // Update in Firebase
            await _updateVehicleRate(vehicleType, updatedData);
          },
        ),

        SizedBox(height: 20),

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
              updatedData['seats'] = seats;
              updatedData['updatedAt'] = FieldValue.serverTimestamp();

              // Update in Firebase
              await _updateVehicleRate(vehicleType, updatedData);
            },
            icon: Icon(Icons.save, size: 20),
            label: Text('SAVE ALL CHANGES FOR $vehicleType'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00C853),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
                backgroundColor: Color(0xFF00C853),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text('Save Section'),
            ),
          ],
        ),

        SizedBox(height: 16),

        // Rate fields in a grid
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontSize: 14),
            );
          },
        ),
      ],
    );
  }

  // Helper methods
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

  // Default values for vehicles not in Firebase
  int _getDefaultSeats(String vehicleType) {
    Map<String, int> defaultSeats = {
      'Hatchback': 5,
      'Sedan': 5,
      'Innova': 7,
      'Tavera': 9,
      'Ertiga': 7,
      'Tempo Traveller': 14,
      'Tourist Van': 18,
      'Van 407': 25,
    };
    return defaultSeats[vehicleType] ?? 4;
  }

  Map<String, dynamic> _getDefaultBelow200(String vehicleType) {
    // Return default below200 rates based on vehicle type
    Map<String, Map<String, dynamic>> defaults = {
      'Hatchback': {
        'hourlyRate': 100.0,
        'perKm': 9.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
        'minHours': 8,
      },
      'Sedan': {
        'hourlyRate': 150.0,
        'perKm': 9.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
        'minHours': 8,
      },
      'Innova': {
        'hourlyRate': 240.0,
        'perKm': 40.0,
        'driverFood': 0.0,
        'nightHalt': 100.0,
        'minHours': 8,
      },
      'Tavera': {
        'hourlyRate': 240.0,
        'perKm': 90.0,
        'driverFood': 0.0,
        'nightHalt': 100.0,
        'minHours': 8,
      },
      'Ertiga': {
        'hourlyRate': 270.0,
        'perKm': 9.0,
        'driverFood': 0.0,
        'nightHalt': 100.0,
        'minHours': 8,
      },
      'Tempo Traveller': {
        'dailyRent': 3600.0,
        'includedKm': 40.0,
        'extraPerKm': 16.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      },
      'Tourist Van': {
        'dailyRent': 3600.0,
        'includedKm': 340.0,
        'extraPerKm': 16.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      },
      'Van 407': {
        'dailyRent': 3800.0,
        'extraPerKm': 18.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      },
    };
    return defaults[vehicleType] ??
        {
          'hourlyRate': 100.0,
          'perKm': 10.0,
          'driverFood': 100.0,
          'nightHalt': 100.0,
          'minHours': 8,
        };
  }

  Map<String, dynamic> _getDefaultAbove200(String vehicleType) {
    // Return default above200 rates based on vehicle type
    Map<String, Map<String, dynamic>> defaults = {
      'Hatchback': {
        'perKm': 10.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      },
      'Sedan': {
        'perKm': 11.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      },
      'Innova': {
        'perKm': 15.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      },
      'Tavera': {
        'perKm': 15.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      },
      'Ertiga': {
        'perKm': 16.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      },
      'Tempo Traveller': {
        'perKm': 25.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      },
      'Tourist Van': {
        'perKm': 25.0,
        'driverAllowance': 500.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      },
      'Van 407': {
        'perKm': 27.0,
        'driverAllowance': 500.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
      },
    };
    return defaults[vehicleType] ??
        {
          'perKm': 12.0,
          'driverAllowance': 300.0,
          'driverFood': 100.0,
          'nightHalt': 100.0,
        };
  }
}