import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/toll_service.dart';
import '../../models/toll_plaza_model.dart';

class AdminTollPlazas extends StatefulWidget {
  @override
  _AdminTollPlazasState createState() => _AdminTollPlazasState();
}

class _AdminTollPlazasState extends State<AdminTollPlazas> {
  final TollService _tollService = TollService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _districtController = TextEditingController();
  final _highwayController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _amountController = TextEditingController(); // NEW: Simple amount
  final _searchController = TextEditingController();

  // REMOVED ALL vehicle type controllers

  List<String> _districts = [];
  String _selectedDistrict = 'All';
  String _searchQuery = '';
  bool _isLoading = false;

  // Admin theme colors
  final Color _primaryColor = const Color(0xFF00B14F);

  // Responsive variables
  late bool _isMobile;
  late bool _isTablet;
  late double _screenWidth;

  @override
  void initState() {
    super.initState();
    _loadDistricts();
  }

  Future<void> _loadDistricts() async {
    final districts = await _tollService.getDistricts();
    setState(() {
      _districts = districts;
    });
  }

  // Helper method to display info rows
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _isMobile = _screenWidth < 600;
    _isTablet = _screenWidth >= 600 && _screenWidth < 1200;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Top Bar
          Container(
            color: Colors.white,
            padding: EdgeInsets.all(_isMobile ? 12 : 16),
            child: Column(
              children: [
                // Title and action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Toll Plazas Management',
                      style: TextStyle(
                        fontSize: _isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    Row(
                      children: [
                        // Import Button
                        IconButton(
                          icon:
                              Icon(Icons.cloud_download, color: _primaryColor),
                          onPressed: _showImportDialog,
                          tooltip: 'Import from Local Data',
                        ),
                        // Add Button
                        IconButton(
                          icon: Icon(Icons.add, color: _primaryColor),
                          onPressed: _showAddTollPlazaDialog,
                          tooltip: 'Add New Toll Plaza',
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Search and Filter
                _isMobile
                    ? Column(
                        children: [
                          _buildSearchField(),
                          SizedBox(height: 8),
                          _buildDistrictFilter(),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 3, child: _buildSearchField()),
                          SizedBox(width: 12),
                          _buildDistrictFilter(),
                        ],
                      ),
              ],
            ),
          ),

          // Toll Plazas List
          Expanded(
            child: StreamBuilder<List<TollPlazaModel>>(
              stream: _tollService.getAllTollPlazas(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: _primaryColor));
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

                var plazas = snapshot.data ?? [];

                // Apply filters
                if (_searchQuery.isNotEmpty) {
                  plazas = plazas.where((plaza) {
                    return plaza.name.toLowerCase().contains(_searchQuery) ||
                        plaza.district.toLowerCase().contains(_searchQuery) ||
                        plaza.highway.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (_selectedDistrict != 'All') {
                  plazas = plazas
                      .where((plaza) => plaza.district == _selectedDistrict)
                      .toList();
                }

                if (plazas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No toll plazas found',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _showAddTollPlazaDialog,
                          icon: Icon(Icons.add),
                          label: Text('Add First Toll Plaza'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(_isMobile ? 12 : 16),
                  itemCount: plazas.length,
                  itemBuilder: (context, index) {
                    final plaza = plazas[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: _isMobile ? 8 : 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: _primaryColor.withOpacity(0.1),
                          child: Icon(Icons.location_on, color: _primaryColor),
                        ),
                        title: Text(
                          plaza.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: _isMobile ? 14 : 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${plaza.district} • ${plaza.highway}',
                          style: TextStyle(fontSize: _isMobile ? 12 : 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit,
                                  color: Colors.blue,
                                  size: _isMobile ? 18 : 20),
                              onPressed: () => _showEditTollPlazaDialog(plaza),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete,
                                  color: Colors.red, size: _isMobile ? 18 : 20),
                              onPressed: () => _showDeleteDialog(plaza),
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(_isMobile ? 12 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Basic Info
                                _buildInfoRow(
                                    Icons.place, 'Location', plaza.location),
                                _buildInfoRow(
                                    Icons.map, 'District', plaza.district),
                                _buildInfoRow(
                                    Icons.route, 'Highway', plaza.highway),
                                _buildInfoRow(
                                  Icons.explore,
                                  'Coordinates',
                                  '${plaza.latitude.toStringAsFixed(4)}, ${plaza.longitude.toStringAsFixed(4)}',
                                ),

                                SizedBox(height: 16),

                                // SIMPLE AMOUNT DISPLAY - Just one rate
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: _primaryColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: _primaryColor.withOpacity(0.3)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Toll Amount',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '₹${plaza.amount?.toStringAsFixed(0) ?? '0'}', // ✅ Fixed: single curly brace with $
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: _primaryColor,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Single rate for all vehicles',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                          fontStyle: FontStyle
                                              .italic, // ✅ Fixed: correct property and spelling
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  // Helper widgets for responsive layout
  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search toll plazas...',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              horizontal: 16, vertical: _isMobile ? 12 : 14),
          prefixIcon: Icon(Icons.search,
              color: _primaryColor, size: _isMobile ? 18 : 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: _isMobile ? 18 : 20),
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
    );
  }

  Widget _buildDistrictFilter() {
    return Container(
      width: _isMobile ? double.infinity : 200,
      padding: EdgeInsets.symmetric(horizontal: _isMobile ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: _selectedDistrict,
        onChanged: (String? newValue) {
          setState(() {
            _selectedDistrict = newValue!;
          });
        },
        underline: SizedBox(),
        icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
        style: TextStyle(
          color: Colors.grey[800],
          fontSize: _isMobile ? 14 : 16,
        ),
        isExpanded: true,
        items: [
          DropdownMenuItem(
            value: 'All',
            child: Text('All Districts'),
          ),
          ..._districts.map((district) {
            return DropdownMenuItem(
              value: district,
              child: Text(district),
            );
          }),
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
              Expanded(
                child: Text(
                  'Import Toll Plazas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                    fontSize: _isMobile ? 16 : 18,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            width: _isMobile ? double.maxFinite : 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will import all toll plazas from local data to Firestore.',
                  style: TextStyle(fontSize: _isMobile ? 13 : 14),
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
                          'This may create duplicate entries if toll plazas already exist.',
                          style: TextStyle(
                            fontSize: _isMobile ? 11 : 12,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

    // Show loading dialog
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
              Text('Importing toll plazas...'),
            ],
          ),
        );
      },
    );

    try {
      await _tollService.initializeTollPlazasToFirestore();

      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('✅ Toll plazas imported successfully!')),
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

  // ==================== ADD TOLL PLAZA DIALOG ====================
  void _showAddTollPlazaDialog() {
    _clearControllers();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add New Toll Plaza'),
        content: Container(
          width: _isMobile ? double.maxFinite : 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Basic Details
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Toll Plaza Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter name' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter location' : null,
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _districtController.text.isNotEmpty
                        ? _districtController.text
                        : null,
                    decoration: InputDecoration(
                      labelText: 'District',
                      border: OutlineInputBorder(),
                    ),
                    items: _districts.map((district) {
                      return DropdownMenuItem(
                        value: district,
                        child: Text(district),
                      );
                    }).toList(),
                    onChanged: (value) {
                      _districtController.text = value ?? '';
                    },
                    validator: (value) =>
                        value == null ? 'Please select district' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _highwayController,
                    decoration: InputDecoration(
                      labelText: 'Highway',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter highway' : null,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latitudeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _longitudeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // SIMPLE AMOUNT FIELD - Just one rate
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Toll Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Single rate for all vehicles',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Amount (₹)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.currency_rupee, size: 18),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter amount';
                            }
                            if (double.tryParse(value!) == null) {
                              return 'Please enter valid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _addTollPlaza,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
            ),
            child: Text('Add Toll Plaza'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTollPlaza() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await _tollService.addTollPlaza(
        name: _nameController.text,
        location: _locationController.text,
        district: _districtController.text,
        highway: _highwayController.text,
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        amount: double.parse(_amountController.text), // Simple amount
      );

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Toll plaza added successfully!'),
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

  // ==================== EDIT TOLL PLAZA DIALOG ====================
  void _showEditTollPlazaDialog(TollPlazaModel plaza) {
    _nameController.text = plaza.name;
    _locationController.text = plaza.location;
    _districtController.text = plaza.district;
    _highwayController.text = plaza.highway;
    _latitudeController.text = plaza.latitude.toString();
    _longitudeController.text = plaza.longitude.toString();
    _amountController.text = plaza.amount.toString(); // Simple amount

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Toll Plaza'),
        content: Container(
          width: _isMobile ? double.maxFinite : 400,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Basic Details
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Toll Plaza Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter name' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter location' : null,
                  ),
                  SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _districtController.text,
                    decoration: InputDecoration(
                      labelText: 'District',
                      border: OutlineInputBorder(),
                    ),
                    items: _districts.map((district) {
                      return DropdownMenuItem(
                        value: district,
                        child: Text(district),
                      );
                    }).toList(),
                    onChanged: (value) {
                      _districtController.text = value ?? '';
                    },
                    validator: (value) =>
                        value == null ? 'Please select district' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _highwayController,
                    decoration: InputDecoration(
                      labelText: 'Highway',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Please enter highway' : null,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latitudeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _longitudeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // SIMPLE AMOUNT FIELD
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Toll Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Single rate for all vehicles',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Amount (₹)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.currency_rupee, size: 18),
                          ),
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Please enter amount';
                            }
                            if (double.tryParse(value!) == null) {
                              return 'Please enter valid number';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _updateTollPlaza(plaza.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
            ),
            child: Text('Update Toll Plaza'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTollPlaza(String plazaId) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await _tollService.updateTollPlaza(
        plazaId: plazaId,
        name: _nameController.text,
        location: _locationController.text,
        district: _districtController.text,
        highway: _highwayController.text,
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        amount: double.parse(_amountController.text), // Simple amount
      );

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Toll plaza updated successfully!'),
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
  void _showDeleteDialog(TollPlazaModel plaza) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Toll Plaza'),
        content: Text('Are you sure you want to delete "${plaza.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _tollService.deleteTollPlaza(plaza.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ ${plaza.name} deleted successfully!'),
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

  void _clearControllers() {
    _nameController.clear();
    _locationController.clear();
    _districtController.clear();
    _highwayController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _amountController.clear(); // Clear amount
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _districtController.dispose();
    _highwayController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _amountController.dispose(); // Dispose amount
    _searchController.dispose();
    super.dispose();
  }
}
