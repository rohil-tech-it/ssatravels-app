// lib/screens/admin/admin_vehicle_management.dart
import 'package:flutter/material.dart';
import '../../services/toll_service.dart';
import '../../models/vehicle_model.dart';

class AdminAddVehicleManagement extends StatefulWidget {
  @override
  _AdminAddVehicleManagementState createState() =>
      _AdminAddVehicleManagementState();
}

class _AdminAddVehicleManagementState extends State<AdminAddVehicleManagement> {
  final TollService _tollService = TollService();
  final _formKey = GlobalKey<FormState>();

  // Controllers - Only three fields
  final _nameController = TextEditingController(); // Vehicle name
  final _seatsController = TextEditingController(); // Seats
  final _modelController = TextEditingController(); // Model (optional)

  // Simple icon for all vehicles
  IconData _getVehicleIcon() {
    return Icons.directions_car;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Vehicle Management',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF00B14F),
        elevation: 2,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: _showAddVehicleDialog,
            tooltip: 'Add New Vehicle',
          ),
        ],
      ),
      body: StreamBuilder<List<VehicleModel>>(
        stream: _tollService.getAllVehicles(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B14F),
                    ),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor:
                    AlwaysStoppedAnimation<Color>(const Color(0xFF00B14F)),
              ),
            );
          }

          final vehicles = snapshot.data!;

          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B14F).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_car,
                      size: 80,
                      color: const Color(0xFF00B14F),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No vehicles found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first vehicle to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _showAddVehicleDialog,
                    icon: Icon(Icons.add),
                    label: Text('Add First Vehicle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00B14F),
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: vehicle.isActive
                          ? const Color(0xFF00B14F).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: vehicle.isActive
                          ? const Color(0xFF00B14F).withOpacity(0.1)
                          : Colors.grey.shade200,
                      child: Icon(
                        _getVehicleIcon(),
                        size: 28,
                        color: vehicle.isActive
                            ? const Color(0xFF00B14F)
                            : Colors.grey,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            vehicle.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              decoration: vehicle.isActive
                                  ? TextDecoration.none
                                  : TextDecoration.lineThrough,
                              color: vehicle.isActive
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        if (vehicle.isActive)
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00B14F).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Active',
                              style: TextStyle(
                                color: const Color(0xFF00B14F),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Inactive',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.event_seat,
                                size: 14, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text(
                              '${vehicle.seatingCapacity} seats',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                            if (vehicle.model != null &&
                                vehicle.model!.isNotEmpty) ...[
                              SizedBox(width: 12),
                              Icon(Icons.model_training,
                                  size: 14, color: Colors.grey[600]),
                              SizedBox(width: 4),
                              Text(
                                vehicle.model!,
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditVehicleDialog(vehicle);
                        } else if (value == 'toggle') {
                          _toggleVehicleStatus(vehicle);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit,
                                  color: const Color(0xFF00B14F), size: 20),
                              SizedBox(width: 8),
                              Text('Edit Vehicle'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Row(
                            children: [
                              Icon(
                                vehicle.isActive
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: vehicle.isActive
                                    ? Colors.orange
                                    : const Color(0xFF00B14F),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                  vehicle.isActive ? 'Deactivate' : 'Activate'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddVehicleDialog() {
    _clearControllers();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_circle, color: const Color(0xFF00B14F)),
            SizedBox(width: 8),
            Text('Add New Vehicle'),
          ],
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Vehicle Name (Required)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Name *',
                      hintText: 'e.g., Toyota Innova',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.drive_file_rename_outline,
                          color: const Color(0xFF00B14F)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vehicle name is required';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 12),

                // Seats (Required)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    controller: _seatsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Number of Seats *',
                      hintText: 'e.g., 7',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.event_seat,
                          color: const Color(0xFF00B14F)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Seats count is required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Enter a valid number';
                      }
                      if (int.parse(value) <= 0) {
                        return 'Seats must be greater than 0';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 12),

                // Model (Optional)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    controller: _modelController,
                    decoration: InputDecoration(
                      labelText: 'Model (Optional)',
                      hintText: 'e.g., 2024, LX, VX',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.model_training,
                          color: const Color(0xFF00B14F)),
                    ),
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
            onPressed: _addVehicle,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B14F),
            ),
            child: Text('Add Vehicle'),
          ),
        ],
      ),
    );
  }

  // In admin_vehicle_management.dart, update _addVehicle method:

  Future<void> _addVehicle() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Auto-detect category from vehicle name
        String vehicleNameLower = _nameController.text.toLowerCase();
        String category = 'Car'; // Default

        // Map to rateCard keys
        if (vehicleNameLower.contains('innova')) {
          category = 'innova';
        } else if (vehicleNameLower.contains('ertiga')) {
          category = 'eritga'; // Note: your Firebase has 'eritga' (typo)
        } else if (vehicleNameLower.contains('hatchback') ||
            vehicleNameLower.contains('swift') ||
            vehicleNameLower.contains('i10')) {
          category = 'hatchback';
        } else if (vehicleNameLower.contains('sedan') ||
            vehicleNameLower.contains('dzire') ||
            vehicleNameLower.contains('verna')) {
          category = 'sedan';
        } else if (vehicleNameLower.contains('tavera')) {
          category = 'tavera';
        } else if (vehicleNameLower.contains('tempo')) {
          category = 'tempo';
        } else if (vehicleNameLower.contains('tourist')) {
          category = 'tourist van';
        } else if (vehicleNameLower.contains('van') ||
            vehicleNameLower.contains('407')) {
          category = 'van 407';
        }

        await _tollService.addVehicle(
          name: _nameController.text.toLowerCase().replaceAll(' ', '_'),
          displayName: _nameController.text,
          category: category, // Use detected category
          seatingCapacity: int.parse(_seatsController.text),
          baseTollMultiplier: 1.0,
          model: _modelController.text.isEmpty ? null : _modelController.text,
        );

        Navigator.pop(context);
        _clearControllers();
        _showSnackBar('✅ Vehicle added successfully!', Colors.green);
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
      }
    }
  }

  void _showEditVehicleDialog(VehicleModel vehicle) {
    _nameController.text = vehicle.displayName;
    _seatsController.text = vehicle.seatingCapacity.toString();
    _modelController.text = vehicle.model ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: const Color(0xFF00B14F)),
            SizedBox(width: 8),
            Text('Edit Vehicle'),
          ],
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Name *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.drive_file_rename_outline,
                          color: const Color(0xFF00B14F)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vehicle name is required';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    controller: _seatsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Number of Seats *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.event_seat,
                          color: const Color(0xFF00B14F)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Seats count is required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Enter a valid number';
                      }
                      if (int.parse(value) <= 0) {
                        return 'Seats must be greater than 0';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    controller: _modelController,
                    decoration: InputDecoration(
                      labelText: 'Model (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.model_training,
                          color: const Color(0xFF00B14F)),
                    ),
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
            onPressed: () => _updateVehicle(vehicle.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B14F),
            ),
            child: Text('Update Vehicle'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateVehicle(String vehicleId) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await _tollService.updateVehicle(
          vehicleId: vehicleId,
          displayName: _nameController.text,
          seatingCapacity: int.parse(_seatsController.text),
          model: _modelController.text.isEmpty ? null : _modelController.text,
          // Keep existing category and multiplier
        );

        Navigator.pop(context);
        _clearControllers();
        _showSnackBar('✅ Vehicle updated successfully!', Colors.green);
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
      }
    }
  } // <-- This should be the ONLY closing brace here

  Future<void> _toggleVehicleStatus(VehicleModel vehicle) async {
    try {
      await _tollService.updateVehicle(
        vehicleId: vehicle.id,
        isActive: !vehicle.isActive,
      );

      _showSnackBar(
        vehicle.isActive ? '⭕ Vehicle deactivated' : '✅ Vehicle activated',
        vehicle.isActive ? Colors.orange : Colors.green,
      );
    } catch (e) {
      _showSnackBar('Toggle failed: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _clearControllers() {
    _nameController.clear();
    _seatsController.clear();
    _modelController.clear();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _seatsController.dispose();
    _modelController.dispose();
    super.dispose();
  }
}
