// lib/screens/admin/admin_vehicle_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAddVehicleManagement extends StatefulWidget {
  const AdminAddVehicleManagement({super.key});

  @override
  _AdminAddVehicleManagementState createState() =>
      _AdminAddVehicleManagementState();
}

class _AdminAddVehicleManagementState extends State<AdminAddVehicleManagement> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers
  final _nameController = TextEditingController();
  final _seatsController = TextEditingController();
  
  // NEW: For managing models
  List<String> _selectedModels = [];
  final TextEditingController _newModelController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
     appBar: AppBar(
  backgroundColor: const Color(0xFF00B14F),
  elevation: 2,

  // 👇 Back arrow white
  iconTheme: const IconThemeData(color: Colors.white),

  // 👇 Title text white
  title: const Text(
    'Vehicle Models Management',
    style: TextStyle(
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  ),

  actions: [
    IconButton(
      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
      onPressed: _showAddVehicleModelDialog,
      tooltip: 'Add New Vehicle Model',
    ),
  ],
),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('vehicleModels').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
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

          final vehicleModels = snapshot.data!.docs;

          if (vehicleModels.isEmpty) {
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
                      Icons.model_training,
                      size: 80,
                      color: const Color(0xFF00B14F),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No vehicle models found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first vehicle model to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _showAddVehicleModelDialog,
                    icon: Icon(Icons.add),
                    label: Text('Add First Model'),
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
            itemCount: vehicleModels.length,
            itemBuilder: (context, index) {
              final doc = vehicleModels[index];
              final data = doc.data() as Map<String, dynamic>;
              final isActive = data['isActive'] ?? true;
              final modelsList = List<String>.from(data['models'] ?? []);

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
                      color: isActive
                          ? const Color(0xFF00B14F).withOpacity(0.3)
                          : Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: isActive
                          ? const Color(0xFF00B14F).withOpacity(0.1)
                          : Colors.grey.shade200,
                      child: Icon(
                        Icons.model_training,
                        size: 24,
                        color: isActive ? const Color(0xFF00B14F) : Colors.grey,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['vehicleType'] ?? doc.id,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              decoration: isActive
                                  ? TextDecoration.none
                                  : TextDecoration.lineThrough,
                              color: isActive ? Colors.black87 : Colors.grey,
                            ),
                          ),
                        ),
                        if (isActive)
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
                              '${data['seatingCapacity'] ?? 4} seats',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${modelsList.length} models available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Models List
                            if (modelsList.isNotEmpty) ...[
                              Text(
                                'Available Models:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: modelsList.map((model) {
                                  return Chip(
                                    label: Text(model),
                                    deleteIcon: Icon(Icons.close, size: 16),
                                    onDeleted: () {
                                      _removeModelFromList(doc.id, modelsList, model);
                                    },
                                    backgroundColor: Colors.grey.shade100,
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 16),
                            ],
                            
                            // Add new model field
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _newModelController,
                                    decoration: InputDecoration(
                                      hintText: 'Add new model (e.g., Tata Tiago)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.add_circle,
                                      color: Color(0xFF00B14F)),
                                  onPressed: () {
                                    _addModelToList(doc.id, modelsList);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _toggleVehicleStatus(doc.id, isActive),
                            icon: Icon(
                              isActive ? Icons.visibility_off : Icons.visibility,
                              size: 18,
                              color: isActive ? Colors.orange : Colors.green,
                            ),
                            label: Text(
                              isActive ? 'Deactivate' : 'Activate',
                              style: TextStyle(
                                color: isActive ? Colors.orange : Colors.green,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => _showEditVehicleModelDialog(doc.id, data),
                            icon: Icon(Icons.edit, size: 18, color: Colors.blue),
                            label: Text('Edit', style: TextStyle(color: Colors.blue)),
                          ),
                          TextButton.icon(
                            onPressed: () => _showDeleteDialog(doc.id),
                            icon: Icon(Icons.delete, size: 18, color: Colors.red),
                            label: Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddVehicleModelDialog() {
    _nameController.clear();
    _seatsController.clear();
    _selectedModels.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.add_circle, color: const Color(0xFF00B14F)),
            SizedBox(width: 8),
            Text('Add New Vehicle Model'),
          ],
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Vehicle Type (Required)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Type *',
                      hintText: 'e.g., hatchback, sedan',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.drive_file_rename_outline,
                          color: const Color(0xFF00B14F)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vehicle type is required';
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
                      hintText: 'e.g., 5',
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

                // Info about models
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You can add models after creating the vehicle type',
                          style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                    ],
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
            onPressed: _addVehicleModel,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B14F),
            ),
            child: Text('Create Model'),
          ),
        ],
      ),
    );
  }

  Future<void> _addVehicleModel() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        String vehicleId = _nameController.text.toLowerCase().replaceAll(' ', '_');

        // Save in vehicleModels collection
        await _firestore.collection('vehicleModels').doc(vehicleId).set({
          'vehicleType': _nameController.text,
          'seatingCapacity': int.parse(_seatsController.text),
          'models': [],  // Initialize empty models array
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        Navigator.pop(context);
        _nameController.clear();
        _seatsController.clear();
        _showSnackBar('✅ Vehicle model created successfully!', Colors.green);
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
      }
    }
  }

  void _showEditVehicleModelDialog(String docId, Map<String, dynamic> data) {
    _nameController.text = data['vehicleType'] ?? '';
    _seatsController.text = (data['seatingCapacity'] ?? 4).toString();
    _selectedModels = List<String>.from(data['models'] ?? []);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: const Color(0xFF00B14F)),
            SizedBox(width: 8),
            Text('Edit Vehicle Model'),
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
                      labelText: 'Vehicle Type *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.drive_file_rename_outline,
                          color: const Color(0xFF00B14F)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vehicle type is required';
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
            onPressed: () => _updateVehicleModel(docId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B14F),
            ),
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateVehicleModel(String docId) async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await _firestore.collection('vehicleModels').doc(docId).update({
          'vehicleType': _nameController.text,
          'seatingCapacity': int.parse(_seatsController.text),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        Navigator.pop(context);
        _nameController.clear();
        _seatsController.clear();
        _showSnackBar('✅ Vehicle model updated successfully!', Colors.green);
      } catch (e) {
        _showSnackBar('Error: $e', Colors.red);
      }
    }
  }

  Future<void> _addModelToList(String docId, List<String> currentModels) async {
    if (_newModelController.text.trim().isEmpty) {
      _showSnackBar('Please enter a model name', Colors.orange);
      return;
    }

    String newModel = _newModelController.text.trim();
    
    if (currentModels.contains(newModel)) {
      _showSnackBar('Model already exists', Colors.orange);
      return;
    }

    try {
      List<String> updatedModels = List.from(currentModels)..add(newModel);
      
      await _firestore.collection('vehicleModels').doc(docId).update({
        'models': updatedModels,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _newModelController.clear();
      _showSnackBar('✅ Model added successfully', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _removeModelFromList(String docId, List<String> currentModels, String modelToRemove) async {
    try {
      List<String> updatedModels = List.from(currentModels)
        ..remove(modelToRemove);
      
      await _firestore.collection('vehicleModels').doc(docId).update({
        'models': updatedModels,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar('✅ Model removed', Colors.green);
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _toggleVehicleStatus(String docId, bool currentStatus) async {
    try {
      await _firestore.collection('vehicleModels').doc(docId).update({
        'isActive': !currentStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showSnackBar(
        currentStatus ? '⭕ Model deactivated' : '✅ Model activated',
        currentStatus ? Colors.orange : Colors.green,
      );
    } catch (e) {
      _showSnackBar('Toggle failed: $e', Colors.red);
    }
  }

  void _showDeleteDialog(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Vehicle Model'),
        content: Text(
            'Are you sure you want to delete this vehicle model? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore.collection('vehicleModels').doc(docId).delete();
                Navigator.pop(context);
                _showSnackBar('✅ Vehicle model deleted', Colors.green);
              } catch (e) {
                _showSnackBar('Delete failed: $e', Colors.red);
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

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _seatsController.dispose();
    _newModelController.dispose();
    super.dispose();
  }
}