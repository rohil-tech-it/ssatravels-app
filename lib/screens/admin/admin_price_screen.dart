// lib/screens/admin/admin_price_screen.dart - CLEANED VERSION
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPriceScreen extends StatefulWidget {
  const AdminPriceScreen({super.key});

  @override
  State<AdminPriceScreen> createState() => AdminPriceScreenState(); // State class made public
}

class AdminPriceScreenState extends State<AdminPriceScreen> {
  // Removed unused fields _isLoading and _errorMessage

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vehicles')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00C853)),
            );
          }

          final vehicles = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isActive'] != false;
          }).toList();

          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.attach_money, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No vehicle rates found'),
                  const Text('Add vehicles in Vehicle Management first'),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(vehicles.length),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: vehicles.length,
                    itemBuilder: (context, index) {
                      final doc = vehicles[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final vehicleId = doc.id;
                      final displayName = data['displayName'] ?? vehicleId;
                      final seats = data['seatingCapacity'] ?? 4;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        child: ExpansionTile(
                          leading: const Icon(Icons.directions_car,
                              color: Color(0xFF00C853)),
                          title: Text(
                            displayName,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Vehicle: ${vehicleId.toUpperCase()} | Seats: $seats | Tap to edit prices',
                            style: const TextStyle(fontSize: 12),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: _buildRateEditor(vehicleId, data),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(int count) {
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
                const Text(
                  'Price Management',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Update prices for vehicles. Changes save automatically.'),
            if (count > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '$count vehicles available',
                  style: const TextStyle(
                      color: Color(0xFF00C853), fontWeight: FontWeight.w500),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateEditor(String vehicleId, Map<String, dynamic> vehicleData) {
    // Get rate data from vehicle
    Map<String, dynamic> below200 = vehicleData['below200'] ?? {};
    Map<String, dynamic> above200 = vehicleData['above200'] ?? {};
    int seats = vehicleData['seatingCapacity'] ?? 4;

    // Check if vehicle is a "day rent" type (Tourist Van, Tempo Traveller, Van 407)
    bool isDayRentVehicle = _isDayRentVehicle(vehicleId);

    // Create controllers with 5 fields only
    final below200Controllers = <String, TextEditingController>{};
    final above200Controllers = <String, TextEditingController>{};

    // If no rates exist, use defaults based on vehicle
    if (below200.isEmpty) {
      below200 =
          _getDefaultBelow200(vehicleId, vehicleData['displayName'] ?? '');
    }
    if (above200.isEmpty) {
      above200 =
          _getDefaultAbove200(vehicleId, vehicleData['displayName'] ?? '');
    }

    below200 =
        _filterToFiveFields(below200, isDayRentVehicle, isBelow200: true);
    above200 =
        _filterToFiveFields(above200, isDayRentVehicle, isBelow200: false);

    below200.forEach((key, value) {
      below200Controllers[key] = TextEditingController(text: value.toString());
    });

    above200.forEach((key, value) {
      above200Controllers[key] = TextEditingController(text: value.toString());
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vehicle Info with Type Indicator
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isDayRentVehicle ? Colors.amber.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                isDayRentVehicle ? Icons.calendar_today : Icons.access_time,
                color: isDayRentVehicle
                    ? Colors.amber.shade700
                    : Colors.blue.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isDayRentVehicle
                      ? 'This vehicle uses DAILY RENT pricing (No hourly rates)'
                      : 'This vehicle uses HOURLY RATE pricing',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDayRentVehicle
                        ? Colors.amber.shade700
                        : Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Seats
        Row(
          children: [
            const Icon(Icons.people, color: Colors.grey, size: 18),
            const SizedBox(width: 8),
            const Text('Seats Capacity:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 12),
            SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: seats.toString(),
                onChanged: (value) {
                  _updateVehicleField(vehicleId, 'seatingCapacity',
                      int.tryParse(value) ?? seats);
                },
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Below 200 KM Rates - 5 Fields
        _buildBelow200Section(
          title: 'BELOW 200 KM RATES',
          controllers: below200Controllers,
          isDayRent: isDayRentVehicle,
          vehicleId: vehicleId,
          onUpdate: () {
            _updateRates(vehicleId, 'below200', below200Controllers);
          },
        ),

        const SizedBox(height: 24),

        // Above 200 KM Rates - 5 Fields
        _buildAbove200Section(
          title: 'ABOVE 200 KM RATES',
          controllers: above200Controllers,
          isDayRent: isDayRentVehicle,
          vehicleId: vehicleId,
          onUpdate: () {
            _updateRates(vehicleId, 'above200', above200Controllers);
          },
        ),

        const SizedBox(height: 16),

        // Auto-save indicator
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.autorenew, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  'Changes save automatically',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method
  Map<String, dynamic> _filterToFiveFields(
      Map<String, dynamic> rates, bool isDayRent,
      {required bool isBelow200}) {
    if (isBelow200) {
      if (isDayRent) {
        // Day Rent vehicles
        return {
          'dailyRent': (rates['dailyRent'] ?? 3600.0).toDouble(),
          'perKm': (rates['perKm'] ?? 16.0).toDouble(),
          'driverFood': (rates['driverFood'] ?? 100.0).toDouble(),
          'nightHalt': (rates['nightHalt'] ?? 100.0).toDouble(),
          'driverAllowance': (rates['driverAllowance'] ?? 500.0).toDouble(),
        };
      } else {
        // Regular vehicles
        return {
          'hourlyRate': (rates['hourlyRate'] ?? 100.0).toDouble(),
          'perKm': (rates['perKm'] ?? 10.0).toDouble(),
          'driverFood': (rates['driverFood'] ?? 100.0).toDouble(),
          'nightHalt': (rates['nightHalt'] ?? 100.0).toDouble(),
          'driverAllowance': (rates['driverAllowance'] ?? 300.0).toDouble(),
        };
      }
    } else {
      // Above 200 - All vehicles same
      return {
        'perKm': (rates['perKm'] ?? 12.0).toDouble(),
        'driverAllowance': (rates['driverAllowance'] ?? 300.0).toDouble(),
        'driverFood': (rates['driverFood'] ?? 100.0).toDouble(),
        'nightHalt': (rates['nightHalt'] ?? 100.0).toDouble(),
        'hourlyRate': (rates['hourlyRate'] ?? 100.0).toDouble(),
      };
    }
  }

  Widget _buildBelow200Section({
    required String title,
    required Map<String, TextEditingController> controllers,
    required bool isDayRent,
    required String vehicleId,
    required VoidCallback onUpdate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDayRent ? Colors.amber.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isDayRent ? 'Daily Rent Mode' : 'Hourly Rate Mode',
                style: TextStyle(
                  fontSize: 11,
                  color:
                      isDayRent ? Colors.amber.shade700 : Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Rate fields in grid - EXACTLY 5 fields
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3,
          ),
          itemCount: 5,
          itemBuilder: (context, index) {
            String key = controllers.keys.elementAt(index);
            TextEditingController controller = controllers[key]!;

            return TextFormField(
              controller: controller,
              onChanged: (value) {
                onUpdate();
              },
              decoration: InputDecoration(
                labelText: _getBelow200FieldLabel(key, isDayRent),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixText: _isAmountField(key) ? '₹ ' : '',
                suffixText: _getBelow200FieldSuffix(key, isDayRent),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAbove200Section({
    required String title,
    required Map<String, TextEditingController> controllers,
    required bool isDayRent,
    required String vehicleId,
    required VoidCallback onUpdate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Rate fields in grid - EXACTLY 5 fields
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3,
          ),
          itemCount: 5,
          itemBuilder: (context, index) {
            String key = controllers.keys.elementAt(index);
            TextEditingController controller = controllers[key]!;

            return TextFormField(
              controller: controller,
              onChanged: (value) {
                onUpdate();
              },
              decoration: InputDecoration(
                labelText: _getAbove200FieldLabel(key, isDayRent),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixText: _isAmountField(key) ? '₹ ' : '',
                suffixText: _getAbove200FieldSuffix(key),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 14),
            );
          },
        ),
      ],
    );
  }

  bool _isDayRentVehicle(String vehicleId) {
    String id = vehicleId.toLowerCase();
    return id.contains('tourist') ||
        id.contains('tempo') ||
        id.contains('van 407') ||
        id.contains('van_407') ||
        id.contains('traveller');
  }

  String _getBelow200FieldLabel(String key, bool isDayRent) {
    if (isDayRent) {
      const Map<String, String> dayRentLabels = {
        'dailyRent': 'Daily Rent',
        'perKm': 'Per KM',
        'driverFood': 'Driver Food',
        'nightHalt': 'Night Halt',
        'driverAllowance': 'Driver Allowance',
      };
      return dayRentLabels[key] ?? key;
    } else {
      const Map<String, String> hourlyLabels = {
        'hourlyRate': 'Hourly Rate',
        'perKm': 'Per KM',
        'driverFood': 'Driver Food',
        'nightHalt': 'Night Halt',
        'driverAllowance': 'Driver Allowance',
      };
      return hourlyLabels[key] ?? key;
    }
  }

  String _getBelow200FieldSuffix(String key, bool isDayRent) {
    if (key == 'perKm') return '/km';
    if (key == 'hourlyRate') return '/hour';
    return '';
  }

  String _getAbove200FieldLabel(String key, bool isDayRent) {
    const Map<String, String> labels = {
      'perKm': 'Per KM',
      'driverAllowance': 'Driver Allowance',
      'driverFood': 'Driver Food',
      'nightHalt': 'Night Halt',
      'hourlyRate': 'Hourly Rate',
    };
    return labels[key] ?? key;
  }

  String _getAbove200FieldSuffix(String key) {
    if (key == 'perKm') return '/km';
    if (key == 'hourlyRate') return '/hour';
    return '';
  }

  bool _isAmountField(String key) {
    return const [
      'perKm',
      'driverFood',
      'nightHalt',
      'hourlyRate',
      'driverAllowance',
      'dailyRent'
    ].contains(key);
  }

  Map<String, dynamic> _getDefaultBelow200(
      String vehicleId, String displayName) {
    String key = vehicleId.toLowerCase();

    // Tourist Van, Tempo Traveller, Van 407 - DAY RENT based
    if (key.contains('tourist') ||
        key.contains('tempo') ||
        key.contains('van') ||
        key.contains('traveller')) {
      if (key.contains('tourist')) {
        return {
          'dailyRent': 3600.0,
          'perKm': 16.0,
          'driverFood': 100.0,
          'nightHalt': 100.0,
          'driverAllowance': 500.0,
        };
      } else if (key.contains('tempo')) {
        return {
          'dailyRent': 3600.0,
          'perKm': 16.0,
          'driverFood': 100.0,
          'nightHalt': 100.0,
          'driverAllowance': 500.0,
        };
      } else if (key.contains('van')) {
        return {
          'dailyRent': 3800.0,
          'perKm': 18.0,
          'driverFood': 100.0,
          'nightHalt': 100.0,
          'driverAllowance': 500.0,
        };
      }
    }

    // Regular vehicles
    if (key.contains('hatchback') || key.contains('access')) {
      return {
        'hourlyRate': 100.0,
        'perKm': 9.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
        'driverAllowance': 300.0,
      };
    }
    if (key.contains('zest')) {
      return {
        'hourlyRate': 100.0,
        'perKm': 9.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
        'driverAllowance': 300.0,
      };
    }
    if (key.contains('sedan')) {
      return {
        'hourlyRate': 150.0,
        'perKm': 9.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
        'driverAllowance': 300.0,
      };
    }
    if (key.contains('innova')) {
      return {
        'hourlyRate': 240.0,
        'perKm': 40.0,
        'driverFood': 0.0,
        'nightHalt': 100.0,
        'driverAllowance': 300.0,
      };
    }
    if (key.contains('ertiga')) {
      return {
        'hourlyRate': 270.0,
        'perKm': 45.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
        'driverAllowance': 350.0,
      };
    }

    // Default
    return {
      'hourlyRate': 100.0,
      'perKm': 10.0,
      'driverFood': 100.0,
      'nightHalt': 100.0,
      'driverAllowance': 300.0,
    };
  }

  Map<String, dynamic> _getDefaultAbove200(
      String vehicleId, String displayName) {
    String key = vehicleId.toLowerCase();

    // Tourist Van, Tempo Traveller, Van 407
    if (key.contains('tourist') ||
        key.contains('tempo') ||
        key.contains('van') ||
        key.contains('traveller')) {
      if (key.contains('tourist') || key.contains('tempo')) {
        return {
          'perKm': 25.0,
          'driverAllowance': 500.0,
          'driverFood': 100.0,
          'nightHalt': 100.0,
          'hourlyRate': 0.0,
        };
      }
      if (key.contains('van')) {
        return {
          'perKm': 27.0,
          'driverAllowance': 500.0,
          'driverFood': 100.0,
          'nightHalt': 100.0,
          'hourlyRate': 0.0,
        };
      }
    }

    // Regular vehicles
    if (key.contains('hatchback') ||
        key.contains('access') ||
        key.contains('zest')) {
      return {
        'perKm': 10.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
        'hourlyRate': 100.0,
      };
    }
    if (key.contains('sedan')) {
      return {
        'perKm': 11.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
        'hourlyRate': 150.0,
      };
    }
    if (key.contains('innova')) {
      return {
        'perKm': 15.0,
        'driverAllowance': 300.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
        'hourlyRate': 240.0,
      };
    }
    if (key.contains('ertiga')) {
      return {
        'perKm': 18.0,
        'driverAllowance': 350.0,
        'driverFood': 100.0,
        'nightHalt': 100.0,
        'hourlyRate': 270.0,
      };
    }

    return {
      'perKm': 12.0,
      'driverAllowance': 300.0,
      'driverFood': 100.0,
      'nightHalt': 100.0,
      'hourlyRate': 100.0,
    };
  }

  Future<void> _updateRates(
    String vehicleId,
    String rateType,
    Map<String, TextEditingController> controllers,
  ) async {
    try {
      Map<String, dynamic> updatedRates = {};
      controllers.forEach((key, controller) {
        updatedRates[key] = double.tryParse(controller.text) ?? 0.0;
      });

      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .update({
        rateType: updatedRates,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar('✅ Rates updated for $vehicleId', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _updateVehicleField(
      String vehicleId, String field, dynamic value) async {
    try {
      await FirebaseFirestore.instance
          .collection('vehicles')
          .doc(vehicleId)
          .update({
        field: value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _showSnackBar('Error updating $field: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}