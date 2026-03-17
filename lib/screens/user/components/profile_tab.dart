// ignore_for_file: unused_field, unused_element, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ssatravels_app/screens/user/components/about_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
// Import the new pages
import 'help_support_page.dart';
import 'settings_page.dart';

class ProfileTab extends StatefulWidget {
  final String? userName;
  final Function(int)? onIndexChanged; // add this

  const ProfileTab({
    super.key,
    this.userName,
    this.onIndexChanged, // add this
  });

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // Theme colors - Green theme
  final Color _primaryColor = const Color(0xFF00B14F);
  final Color _backgroundColor = const Color(0xFFF5F5F5);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF333333);
  final Color _secondaryTextColor = const Color(0xFF666666);
  final Color _dividerColor = const Color(0xFFEEEEEE);

  // Firebase instances
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  // ================= NAVIGATION HELPERS =================
  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  Future<void> _loadProfileImage() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData != null && userData['profileImageUrl'] != null) {
        setState(() {
          _profileImageUrl = userData['profileImageUrl'];
        });
      }
    }
  }

  Future<void> _saveUserProfile(
      String name, String phone, String email, String designation) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'fullName': name,
          'phoneNumber': phone,
          'email': email,
          'designation': designation,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving profile: $e');
      rethrow;
    }
  }

// In ProfileTab.dart, update the _uploadProfileImage method:
Future<void> _uploadProfileImage(File image) async {
  final user = _auth.currentUser;
  if (user == null) return;

  // store context locally
  final currentContext = context;

  try {
    showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF00B14F),
        ),
      ),
    );

    final ref = FirebaseStorage.instance
        .ref()
        .child("profile_images")
        .child("${user.uid}.jpg");

    SettableMetadata metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'uploadedAt': DateTime.now().toString()},
    );

    UploadTask uploadTask = ref.putFile(image, metadata);

    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .update({
      "profileImageUrl": downloadUrl,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    Navigator.pop(currentContext);

    setState(() {
      _profileImageUrl = downloadUrl;
      _selectedImage = null;
    });

    _showMessage(currentContext, 'Profile image updated successfully!');
  } catch (e) {
    if (!mounted) return;

    Navigator.pop(currentContext);
    _showMessage(currentContext, 'Error uploading image: $e', isError: true);
  }
}

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        await _uploadProfileImage(_selectedImage!);
      }
    } catch (e) {
      _showMessage(context, 'Error picking image: $e', isError: true);
    }
  }

  void _showMessage(BuildContext context, String message,
      {bool isError = false}) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : _primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _makePhoneCall() async {
    const phoneNumber = '6374049582';
    final url = Uri.parse('tel:$phoneNumber');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        _showMessage(context, 'Could not launch phone app', isError: true);
      }
    }
  }

  Widget _buildUserStatusHeader(User? user, Map<String, dynamic>? userData) {
    final bool isLoggedIn = user != null;

    // Use the parameter for guest view
    final String fullName = userData?['fullName'] ??
        user?.displayName ??
        (isLoggedIn ? 'User' : widget.userName) ??
        'Guest User';

    final String designation = userData?['designation'] ?? 'SSA Traveler';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: _primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // User Status Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                // User Avatar and Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // User Avatar with edit option - INCREASED SIZE
                    Stack(
                      children: [
                        Container(
                          width: 100, // Increased from 70 to 100
                          height: 100, // Increased from 70 to 100
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: BorderRadius.circular(
                                50), // Updated for 100 size
                            border: Border.all(
                              color: Colors.white,
                              width: 4, // Increased border width
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                            image: _profileImageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_profileImageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: _profileImageUrl == null
                              ? Center(
                                  child: Text(
                                    _getInitials(fullName),
                                    style: const TextStyle(
                                      fontSize: 42, // Increased from 28 to 42
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        if (isLoggedIn)
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                width: 36, // Increased from 28 to 36
                                height: 36, // Increased from 28 to 36
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3, // Increased border width
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 20, // Increased from 14 to 20
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 20), // Increased spacing

                    // User Info - Adjusted for larger avatar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoggedIn ? 'Hello!' : 'Welcome, Guest!',
                            style: TextStyle(
                              fontSize: 18, // Increased from 15
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 26, // Increased from 24
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            designation,
                            style: TextStyle(
                              fontSize: 16, // Increased from 14
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          if (!isLoggedIn) ...[
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: const Text(
                                'Guest Mode',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoSection(User? user, Map<String, dynamic>? userData) {
    final bool isLoggedIn = user != null;

    // Use the parameter for guest view
    final String fullName = userData?['fullName'] ??
        user?.displayName ??
        (isLoggedIn ? 'User' : widget.userName) ??
        'Guest User';

    final String email =
        userData?['email'] ?? user?.email ?? 'guest@ssatravels.com';
    final String phoneNumber =
        userData?['phoneNumber'] ?? user?.phoneNumber ?? '+91 00000 00000';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
            child: Row(
              children: [
                Icon(
                  Icons.contact_page,
                  color: _primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),

          Divider(color: _dividerColor, height: 1),

          // Full Name
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: _primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Full Name',
                        style: TextStyle(
                          fontSize: 14,
                          color: _secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 16,
                          color: _textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: _dividerColor, height: 1, indent: 20),

          // Email
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    color: _primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 14,
                          color: _secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 16,
                          color: _textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(color: _dividerColor, height: 1, indent: 20),

          // Phone
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.phone_outlined,
                    color: _primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mobile',
                        style: TextStyle(
                          fontSize: 14,
                          color: _secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phoneNumber,
                        style: TextStyle(
                          fontSize: 16,
                          color: _textColor,
                          fontWeight: FontWeight.w500,
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
  }

  Widget _buildProfileOptions() {
    final bool isLoggedIn = _auth.currentUser != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          // Edit Profile Option - Only for logged in users
          if (isLoggedIn)
            Column(
              children: [
                _buildProfileOptionItem(
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  icon: Icons.edit_outlined,
                  color: _primaryColor,
                  onTap: () => _handleOptionTap(context, 'Edit Profile'),
                ),
                Divider(color: _dividerColor, height: 1, indent: 72),
              ],
            ),
      
          // Settings Option
          _buildProfileOptionItem(
            title: 'Settings',
            subtitle: 'Manage your app settings',
            icon: Icons.settings_outlined,
            color: _primaryColor,
            onTap: () => _handleOptionTap(context, 'Settings'),
          ),

          Divider(color: _dividerColor, height: 1, indent: 72),

          // Help Center Option
          _buildProfileOptionItem(
            title: 'Help & Support',
            subtitle: 'Get help and support',
            icon: Icons.help_outline,
            color: _primaryColor,
            onTap: () => _handleOptionTap(context, 'Help & Support'),
          ),

          Divider(color: _dividerColor, height: 1, indent: 72),

          // Call Us Option
          _buildProfileOptionItem(
            title: 'Call Us',
            subtitle: 'Contact customer support',
            icon: Icons.call_outlined,
            color: _primaryColor,
            onTap: () => _handleOptionTap(context, 'Call Us'),
          ),

          Divider(color: _dividerColor, height: 1, indent: 72),

          // About App Option
          _buildProfileOptionItem(
            title: 'About App',
            subtitle: 'App version 1.0.0',
            icon: Icons.info_outline,
            color: _primaryColor,
            onTap: () => _handleOptionTap(context, 'About App'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: _secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _secondaryTextColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleOptionTap(BuildContext context, String title) {
    switch (title) {
      case 'Edit Profile':
        _showEditProfileDialog(context);
        break;
      case 'Settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
        break;
      case 'Help & Support':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HelpSupportPage()),
        );
        break;
      case 'Call Us':
        _makePhoneCall();
        break;
      case 'About App':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutPage()),
        );
        break;
    }
  }

  void _showEditProfileDialog(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) {
      _showMessage(context, 'Please login to edit profile', isError: true);
      return;
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    final TextEditingController nameController = TextEditingController(
        text: userData['fullName'] ?? user.displayName ?? '');
    final TextEditingController designationController =
        TextEditingController(text: userData['designation'] ?? 'SSA Traveler');
    final TextEditingController phoneController = TextEditingController(
        text: userData['phoneNumber'] ?? user.phoneNumber ?? '');
    final TextEditingController emailController =
        TextEditingController(text: userData['email'] ?? user.email ?? '');
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        // Create state variables outside the StatefulBuilder builder
        // so they persist across rebuilds
        bool showCurrentPassword = false;
        bool showNewPassword = false;
        bool showConfirmPassword = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.edit,
                                color: _primaryColor,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Personal Information Section
                          TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon:
                                  Icon(Icons.person, color: _primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: designationController,
                            decoration: InputDecoration(
                              labelText: 'Designation',
                              prefixIcon:
                                  Icon(Icons.work, color: _primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: phoneController,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon:
                                  Icon(Icons.phone, color: _primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: emailController,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon:
                                  Icon(Icons.email, color: _primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter email address';
                              }
                              if (!value.contains('@') ||
                                  !value.contains('.')) {
                                return 'Enter valid email address';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          // Change Password Section
                          Text(
                            'Change Password',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: currentPasswordController,
                            obscureText: !showCurrentPassword,
                            decoration: InputDecoration(
                              labelText: 'Current Password',
                              prefixIcon:
                                  Icon(Icons.lock, color: _primaryColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showCurrentPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: _primaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showCurrentPassword = !showCurrentPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: newPasswordController,
                            obscureText: !showNewPassword,
                            decoration: InputDecoration(
                              labelText: 'New Password',
                              prefixIcon: Icon(Icons.lock_outline,
                                  color: _primaryColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showNewPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: _primaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showNewPassword = !showNewPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) {
                              if (value != null &&
                                  value.isNotEmpty &&
                                  value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: !showConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm New Password',
                              prefixIcon:
                                  Icon(Icons.lock_reset, color: _primaryColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: _primaryColor,
                                ),
                                onPressed: () {
                                  setState(() {
                                    showConfirmPassword = !showConfirmPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) {
                              if (newPasswordController.text.isNotEmpty &&
                                  value != newPasswordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _primaryColor,
                                    side:
                                        BorderSide(color: Colors.grey.shade300),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (formKey.currentState!.validate()) {
                                      try {
                                        // Update profile information
                                        await _saveUserProfile(
                                          nameController.text,
                                          phoneController.text,
                                          emailController.text,
                                          designationController.text,
                                        );

                                        // Update Firebase Auth display name
                                        await user.updateDisplayName(
                                            nameController.text);

                                        // Change password if provided
                                        if (currentPasswordController
                                                .text.isNotEmpty &&
                                            newPasswordController
                                                .text.isNotEmpty) {
                                          // Re-authenticate user before changing password
                                          final credential =
                                              EmailAuthProvider.credential(
                                            email: user.email!,
                                            password:
                                                currentPasswordController.text,
                                          );
                                          await user
                                              .reauthenticateWithCredential(
                                                  credential);
                                          await user.updatePassword(
                                              newPasswordController.text);
                                        }

                                        if (context.mounted) {
                                          Navigator.pop(context);
                                          _showMessage(context,
                                              'Profile updated successfully!');
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          _showMessage(context, 'Error: $e',
                                              isError: true);
                                        }
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Save Changes'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

// Helper method to get initials from name
  String _getInitials(String name) {
    if (name.isEmpty || name == 'Guest User') return 'GU';

    // Handle names like "Abarna S" -> should return "AS"
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      // Take first letter of first name and first letter of last name
      return parts[0].substring(0, 1).toUpperCase() +
          parts[1].substring(0, 1).toUpperCase();
    } else if (parts.length == 1) {
      // Single name - take first letter
      return parts[0].substring(0, 1).toUpperCase();
    }

    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final isLoggedIn = user != null;

        if (isLoggedIn) {
          return StreamBuilder<DocumentSnapshot>(
            stream: _firestore.collection('users').doc(user.uid).snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: _primaryColor),
                  ),
                );
              }

              final userData =
                  userSnapshot.data?.data() as Map<String, dynamic>?;

              return _buildProfileContent(context, user, userData);
            },
          );
        }

        // Guest view - use widget.userName from constructor
        return _buildProfileContent(context, null, null);
      },
    );
  }

  Widget _buildProfileContent(
      BuildContext context, User? user, Map<String, dynamic>? userData) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: RefreshIndicator(
        color: _primaryColor,
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // User Status Header
              _buildUserStatusHeader(user, userData),

              // Contact Information Section
              _buildContactInfoSection(user, userData),

              // Profile Options
              _buildProfileOptions(),

              // Bottom Padding
              const SizedBox(height: 30),

              // App Version
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  'Developed by Rohil Technologies',
                  style: TextStyle(
                    fontSize: 12,
                    color: _secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
