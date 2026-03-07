import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ssatravels_app/screens/admin/admin_about_page.dart';
import 'package:ssatravels_app/screens/admin/admin_help_support_page.dart';

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Design colors - Green theme for all
  final Color _primaryColor = const Color(0xFF00C853); // Green color for all items
  final Color _backgroundColor = const Color(0xFFF5F5F5);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF333333);
  final Color _secondaryTextColor = const Color(0xFF666666);
  final Color _dividerColor = const Color(0xFFEEEEEE);

  // Form controllers for Edit Profile
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Form controllers for Change Password
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Map<String, dynamic> _adminData = {};
  bool _isLoading = true;
  bool _showPassword = false;

  // Responsive variables
  late double _screenWidth;
  late double _screenHeight;
  late double _paddingHorizontal;
  late double _avatarRadius;
  late double _fontSizeTitle;
  late double _fontSizeSubtitle;
  late double _fontSizeSmall;
  late double _iconSize;
  late double _containerHeight;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateResponsiveValues();
  }

  void _updateResponsiveValues() {
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate responsive values
    _paddingHorizontal = _screenWidth * 0.04; // 4% of screen width
    _avatarRadius = _screenWidth * 0.12; // 12% of screen width (min 45, max 60)
    if (_avatarRadius < 45) _avatarRadius = 45;
    if (_avatarRadius > 60) _avatarRadius = 60;
    
    _fontSizeTitle = _screenWidth * 0.06; // 6% of screen width
    if (_fontSizeTitle < 20) _fontSizeTitle = 20;
    if (_fontSizeTitle > 26) _fontSizeTitle = 26;
    
    _fontSizeSubtitle = _screenWidth * 0.04; // 4% of screen width
    if (_fontSizeSubtitle < 14) _fontSizeSubtitle = 14;
    if (_fontSizeSubtitle > 18) _fontSizeSubtitle = 18;
    
    _fontSizeSmall = _screenWidth * 0.035; // 3.5% of screen width
    if (_fontSizeSmall < 12) _fontSizeSmall = 12;
    if (_fontSizeSmall > 14) _fontSizeSmall = 14;
    
    _iconSize = _screenWidth * 0.06; // 6% of screen width
    if (_iconSize < 20) _iconSize = 20;
    if (_iconSize > 30) _iconSize = 30;
    
    _containerHeight = _screenHeight * 0.07; // 7% of screen height
    if (_containerHeight < 50) _containerHeight = 50;
    if (_containerHeight > 70) _containerHeight = 70;
  }

  Future<void> _loadAdminData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get admin data from Firestore
        var adminDoc = await _firestore.collection('admins').doc(user.uid).get();
        if (adminDoc.exists) {
          setState(() {
            _adminData = adminDoc.data()!;
          });
        } else {
          // Create default admin data if not exists
          setState(() {
            _adminData = {
              'name': 'SSA Admin',
              'email': user.email ?? 'admin@ssatravels.com',
              'phone': '6379226432',
              'role': 'Administrator',
              'createdAt': Timestamp.now(),
            };
          });

          // Save to Firestore
          await _firestore.collection('admins').doc(user.uid).set(_adminData);
        }
      }

      // Update form controllers
      _nameController.text = _adminData['name'] ?? 'SSA Admin';
      _emailController.text = _adminData['email'] ?? 'admin@ssatravels.com';
      _phoneController.text = _adminData['phone'] ?? '6379226432';

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Update profile in Firestore
        await _firestore.collection('admins').doc(user.uid).set({
          'name': _nameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'updatedAt': Timestamp.now(),
        }, SetOptions(merge: true));

        if (mounted) {
          _showSnackbar('Profile updated successfully!', isError: false);
        }
        await _loadAdminData(); // Reload updated data
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Error updating profile: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _changePassword() async {
    // Validation
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      if (mounted) {
        _showSnackbar('Please fill all password fields', isError: true);
      }
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      if (mounted) {
        _showSnackbar('New passwords do not match!', isError: true);
      }
      return;
    }

    if (_newPasswordController.text.length < 6) {
      if (mounted) {
        _showSnackbar('Password must be at least 6 characters!', isError: true);
      }
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Re-authenticate user before changing password
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);

        // Update password
        await user.updatePassword(_newPasswordController.text);

        // Clear password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        if (mounted) {
          _showSnackbar('Password changed successfully!', isError: false);
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error changing password';
      if (e.code == 'wrong-password') {
        errorMessage = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        errorMessage = 'New password is too weak';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = 'Please login again to change password';
      }
      if (mounted) {
        _showSnackbar(errorMessage, isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Error: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _logout() async {
    final scaffoldContext = context; // capture context before showing dialog

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout from admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _auth.signOut();
      if (scaffoldContext.mounted) {
        Navigator.pushReplacementNamed(scaffoldContext, '/admin-login');
      }
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontSize: _fontSizeSmall),
        ),
        backgroundColor: isError ? Colors.red : _primaryColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(_paddingHorizontal),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: _screenHeight * 0.03, 
        horizontal: _paddingHorizontal
      ),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: _avatarRadius,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.admin_panel_settings,
              size: _avatarRadius * 0.8,
              color: _primaryColor,
            ),
          ),
          SizedBox(height: _screenHeight * 0.02),
          Text(
            _adminData['name'] ?? 'SSA Admin',
            style: TextStyle(
              fontSize: _fontSizeTitle,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _screenHeight * 0.01),
          Text(
            _adminData['email'] ?? 'admin@ssatravels.com',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: _fontSizeSubtitle,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: _screenHeight * 0.015),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _paddingHorizontal,
              vertical: _screenHeight * 0.01,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield, 
                  color: Colors.white, 
                  size: _fontSizeSubtitle,
                ),
                SizedBox(width: _screenWidth * 0.02),
                Text(
                  _adminData['role'] ?? 'Administrator',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: _fontSizeSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptionsList() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _paddingHorizontal, 
        vertical: _screenHeight * 0.01
      ),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Edit Profile (Now includes Change Password)
          _buildProfileOptionItem(
            title: 'Edit Profile & Password',
            subtitle: 'Update your profile and change password',
            icon: Icons.edit_outlined,
            onTap: _showEditProfileDialog,
          ),
          Divider(color: _dividerColor, height: 1, indent: 72),
         
          // Help & Support
          _buildProfileOptionItem(
            title: 'Help & Support',
            subtitle: 'Get help and support',
            icon: Icons.help_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminHelpSupportPage()),
              );
            },
          ),
          Divider(color: _dividerColor, height: 1, indent: 72),

          // About App
          _buildProfileOptionItem(
            title: 'About App',
            subtitle: 'App version 1.0.0',
            icon: Icons.info_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminAboutPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(_paddingHorizontal),
          child: Row(
            children: [
              Container(
                width: _containerHeight * 0.8,
                height: _containerHeight * 0.8,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: _primaryColor,
                  size: _iconSize,
                ),
              ),
              SizedBox(width: _screenWidth * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: _fontSizeSubtitle,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                    SizedBox(height: _screenHeight * 0.005),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: _fontSizeSmall,
                        color: _secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _secondaryTextColor,
                size: _iconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: EdgeInsets.all(_paddingHorizontal),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: _screenWidth * 0.95,
              constraints: BoxConstraints(
                maxHeight: _screenHeight * 0.9,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(_paddingHorizontal),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.edit,
                            color: _primaryColor,
                            size: _iconSize * 1.2,
                          ),
                          SizedBox(width: _screenWidth * 0.03),
                          Expanded(
                            child: Text(
                              'Edit Profile & Password',
                              style: TextStyle(
                                fontSize: _fontSizeTitle * 0.9,
                                fontWeight: FontWeight.bold,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _screenHeight * 0.02),

                      // Personal Information Section
                      Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: _fontSizeSubtitle,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      SizedBox(height: _screenHeight * 0.015),

                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          labelStyle: TextStyle(fontSize: _fontSizeSmall),
                          prefixIcon: Icon(Icons.person, color: _primaryColor, size: _iconSize * 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: _paddingHorizontal,
                            vertical: _screenHeight * 0.015,
                          ),
                        ),
                      ),
                      SizedBox(height: _screenHeight * 0.015),

                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(fontSize: _fontSizeSmall),
                          prefixIcon: Icon(Icons.email, color: _primaryColor, size: _iconSize * 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: _paddingHorizontal,
                            vertical: _screenHeight * 0.015,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      SizedBox(height: _screenHeight * 0.015),

                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          labelStyle: TextStyle(fontSize: _fontSizeSmall),
                          prefixIcon: Icon(Icons.phone, color: _primaryColor, size: _iconSize * 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: _paddingHorizontal,
                            vertical: _screenHeight * 0.015,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),

                      SizedBox(height: _screenHeight * 0.03),

                      // Change Password Section
                      Text(
                        'Change Password',
                        style: TextStyle(
                          fontSize: _fontSizeSubtitle,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                        ),
                      ),
                      SizedBox(height: _screenHeight * 0.015),

                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          labelStyle: TextStyle(fontSize: _fontSizeSmall),
                          prefixIcon: Icon(Icons.lock, color: _primaryColor, size: _iconSize * 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: _paddingHorizontal,
                            vertical: _screenHeight * 0.015,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Icons.visibility : Icons.visibility_off,
                              color: _primaryColor,
                              size: _iconSize * 0.8,
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: _screenHeight * 0.015),

                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle: TextStyle(fontSize: _fontSizeSmall),
                          prefixIcon: Icon(Icons.lock_outline, color: _primaryColor, size: _iconSize * 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: _paddingHorizontal,
                            vertical: _screenHeight * 0.015,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Icons.visibility : Icons.visibility_off,
                              color: _primaryColor,
                              size: _iconSize * 0.8,
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: _screenHeight * 0.015),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_showPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          labelStyle: TextStyle(fontSize: _fontSizeSmall),
                          prefixIcon: Icon(Icons.lock_reset, color: _primaryColor, size: _iconSize * 0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: _paddingHorizontal,
                            vertical: _screenHeight * 0.015,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Icons.visibility : Icons.visibility_off,
                              color: _primaryColor,
                              size: _iconSize * 0.8,
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: _screenHeight * 0.02),
                      Container(
                        padding: EdgeInsets.all(_paddingHorizontal * 0.8),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 156, 230, 162),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color.fromARGB(255, 51, 180, 51)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: const Color.fromARGB(255, 43, 179, 47),
                              size: _fontSizeSubtitle,
                            ),
                            SizedBox(width: _screenWidth * 0.02),
                            Expanded(
                              child: Text(
                                'Password must be at least 6 characters long',
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 7, 156, 12),
                                  fontSize: _fontSizeSmall,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: _screenHeight * 0.03),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // Clear password fields when canceling
                                _currentPasswordController.clear();
                                _newPasswordController.clear();
                                _confirmPasswordController.clear();
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _primaryColor,
                                side: const BorderSide(color: Colors.grey),
                                padding: EdgeInsets.symmetric(
                                  vertical: _screenHeight * 0.015,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: _fontSizeSubtitle,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: _screenWidth * 0.03),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                // Update profile first
                                await _updateProfile();

                                // Change password if fields are filled
                                if (_currentPasswordController.text.isNotEmpty ||
                                    _newPasswordController.text.isNotEmpty ||
                                    _confirmPasswordController.text.isNotEmpty) {
                                  await _changePassword();
                                }

                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: _screenHeight * 0.015,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Save Changes',
                                style: TextStyle(fontSize: _fontSizeSubtitle),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: _paddingHorizontal, 
        vertical: _screenHeight * 0.01
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _logout,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: EdgeInsets.all(_paddingHorizontal),
            child: Row(
              children: [
                Container(
                  width: _containerHeight * 0.8,
                  height: _containerHeight * 0.8,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.logout,
                    color: Colors.red,
                    size: _iconSize,
                  ),
                ),
                SizedBox(width: _screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: _fontSizeSubtitle,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: _screenHeight * 0.005),
                      Text(
                        'Logout from admin panel',
                        style: TextStyle(
                          fontSize: _fontSizeSmall,
                          color: _secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _secondaryTextColor,
                  size: _iconSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _updateResponsiveValues();
    
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: _primaryColor,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: _screenHeight * 0.02),
                  Text(
                    'Loading Admin Profile...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: _fontSizeSubtitle,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(),

                  // Profile Options List
                  _buildProfileOptionsList(),

                  // Logout Button
                  _buildLogoutButton(),

                  // App Version
                  Padding(
                    padding: EdgeInsets.only(
                      top: _screenHeight * 0.02, 
                      bottom: _screenHeight * 0.03
                    ),
                    child: Text(
                      'Developed by Rohil Technologies',
                      style: TextStyle(
                        color: _secondaryTextColor,
                        fontSize: _fontSizeSmall * 0.9,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}