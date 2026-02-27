import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this for Clipboard
import 'package:qr_flutter/qr_flutter.dart';
import 'package:ssatravels_app/screens/user/user_home_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer; // For debugPrint

class PaymentScreen extends StatefulWidget {
  final String? bookingId;
  final double? amount;

  const PaymentScreen({
    super.key,
    this.bookingId,
    this.amount,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final String _upiId = "syedsahina18-1@okaxis";
  final String _gpayNumber = "9751867879"; // Updated to your number
  final String _whatsappNumber = "9751867879"; // WhatsApp number
  final String _bankName = "Federal Bank";
  final String _accountSuffix = "3931";
  final Color _primaryGreen = const Color(0xFF00B14F);

  int _selectedIndex = 0; // 0: QR Code, 1: GPay Number, 2: UPI ID
  bool _paymentSuccess = false;

  // Updated tab names
  final List<String> _tabs = ['QR Code', 'GPay', 'UPI'];
  final List<IconData> _tabIcons = [
    Icons.qr_code,
    Icons.phone_android,
    Icons.payment
  ];

  // Helper method to copy text to clipboard
  Future<void> _copyToClipboard(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return _paymentSuccess
        ? _buildSuccessScreen()
        : _buildPaymentScreen(isSmallScreen);
  }

  Widget _buildPaymentScreen(bool isSmallScreen) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header removed - now only SafeArea with no header
            const SizedBox(height: 20),

            // Segmented Control with Icons on top and text below
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndex = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 8 : 12),
                          decoration: BoxDecoration(
                            color: _selectedIndex == index
                                ? _primaryGreen
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _tabIcons[index],
                                size: isSmallScreen ? 22 : 26,
                                color: _selectedIndex == index
                                    ? Colors.white
                                    : Colors.grey[600],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _tabs[index],
                                style: TextStyle(
                                  color: _selectedIndex == index
                                      ? Colors.white
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                  fontSize: isSmallScreen ? 11 : 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Content Area
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _getContentWidget(isSmallScreen),
              ),
            ),

            // Confirm Payment Button
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _paymentSuccess = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 16 : 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'I have made the payment',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getContentWidget(bool isSmallScreen) {
    switch (_selectedIndex) {
      case 0:
        return _buildQRCodeView(isSmallScreen);
      case 1:
        return _buildGPayNumberView(isSmallScreen);
      case 2:
        return _buildUPIIDView(isSmallScreen);
      default:
        return _buildQRCodeView(isSmallScreen);
    }
  }

  Widget _buildQRCodeView(bool isSmallScreen) {
    String qrData = "upi://pay?pa=$_upiId&pn=Syed%20Abideen&cu=INR";
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      key: const ValueKey(0),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          children: [
            // QR Code Container
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.grey[200]!, width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: screenWidth * (isSmallScreen ? 0.45 : 0.5),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 12 : 16,
                        vertical: isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: _primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            color: _primaryGreen,
                            size: isSmallScreen ? 14 : 16),
                        SizedBox(width: isSmallScreen ? 4 : 6),
                        Text(
                          'Scan with any UPI app',
                          style: TextStyle(
                            color: _primaryGreen,
                            fontWeight: FontWeight.w500,
                            fontSize: isSmallScreen ? 11 : 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            // Bank Details Card
            _buildInfoCard(
              icon: Icons.account_balance,
              title: 'Bank Account',
              value: 'Federal Bank $_accountSuffix',
              isSmallScreen: isSmallScreen,
            ),
            SizedBox(height: isSmallScreen ? 10 : 12),

            // UPI ID Card with Copy
            _buildInfoCard(
              icon: Icons.payment,
              title: 'UPI ID',
              value: _upiId,
              showCopy: true,
              onCopy: () => _copyToClipboard(_upiId, 'UPI ID copied to clipboard'),
              isSmallScreen: isSmallScreen,
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            // UPI Circle Option
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _primaryGreen.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                    decoration: BoxDecoration(
                      color: _primaryGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.group_add,
                      color: _primaryGreen,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  const Expanded(
                    child: Text(
                      'Want to join UPI Circle?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      foregroundColor: _primaryGreen,
                    ),
                    child: const Text("Switch QR"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGPayNumberView(bool isSmallScreen) {
    return SingleChildScrollView(
      key: const ValueKey(1),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          children: [
            // GPay Number Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
              decoration: BoxDecoration(
                color: _primaryGreen,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _primaryGreen.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_android,
                      size: isSmallScreen ? 40 : 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Google Pay Number',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _gpayNumber,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    children: [
                      _buildActionButton(
                        icon: Icons.copy,
                        label: 'Copy',
                        onTap: () => _copyToClipboard(_gpayNumber, 'Number copied to clipboard'),
                        isSmallScreen: isSmallScreen,
                      ),
                      _buildActionButton(
                        icon: Icons.call,
                        label: 'Call',
                        onTap: () async {
                          final Uri telUri = Uri(scheme: 'tel', path: _gpayNumber);
                          if (await canLaunchUrl(telUri)) {
                            await launchUrl(telUri);
                          } else {
                            _copyToClipboard(_gpayNumber, 'Number copied to clipboard');
                          }
                        },
                        isOutlined: true,
                        isSmallScreen: isSmallScreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            // Instructions Card
            _buildInstructionsCard([
              'Open Google Pay app',
              'Tap on "Send money" or "New payment"',
              'Enter this number: $_gpayNumber',
              'Enter the amount: ₹${widget.amount?.toStringAsFixed(2) ?? 'Your amount'}',
              'Add note: "Travel Booking"',
              'Complete the payment',
            ], isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildUPIIDView(bool isSmallScreen) {
    return SingleChildScrollView(
      key: const ValueKey(2),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Column(
          children: [
            // UPI ID Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isSmallScreen ? 20 : 30),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.grey[200]!, width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    decoration: BoxDecoration(
                      color: _primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.payment,
                      size: isSmallScreen ? 40 : 50,
                      color: _primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'UPI ID',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _upiId,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  _buildActionButton(
                    icon: Icons.copy,
                    label: 'Copy UPI ID',
                    onTap: () => _copyToClipboard(_upiId, 'UPI ID copied to clipboard'),
                    isSmallScreen: isSmallScreen,
                  ),
                ],
              ),
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            // Bank Details
            _buildInfoCard(
              icon: Icons.account_balance,
              title: 'Bank Account',
              value: 'Federal Bank $_accountSuffix',
              isSmallScreen: isSmallScreen,
            ),

            SizedBox(height: isSmallScreen ? 10 : 12),

            // Account Holder
            _buildInfoCard(
              icon: Icons.person,
              title: 'Account Holder',
              value: 'Syed Abideen',
              isSmallScreen: isSmallScreen,
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            // Instructions Card
            _buildInstructionsCard([
              'Open any UPI app (GPay, PhonePe, PayTM)',
              'Select "Pay to UPI ID" option',
              'Enter UPI ID: $_upiId',
              'Enter the amount: ₹${widget.amount?.toStringAsFixed(2) ?? 'Your amount'}',
              'Add payment reference',
              'Complete the payment',
            ], isSmallScreen),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    bool showCopy = false,
    VoidCallback? onCopy,
    required bool isSmallScreen,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
            decoration: BoxDecoration(
              color: _primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                Icon(icon, color: _primaryGreen, size: isSmallScreen ? 20 : 24),
          ),
          SizedBox(width: isSmallScreen ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (showCopy && onCopy != null)
            Container(
              decoration: BoxDecoration(
                color: _primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: Icon(Icons.copy,
                    color: _primaryGreen, size: isSmallScreen ? 18 : 20),
                onPressed: onCopy,
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                constraints: const BoxConstraints(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isOutlined = false,
    required bool isSmallScreen,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: isSmallScreen ? 16 : 18),
        label: Text(
          label,
          style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white),
          padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 20,
              vertical: isSmallScreen ? 10 : 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: isSmallScreen ? 16 : 18),
      label: Text(
        label,
        style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _primaryGreen,
        padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 20,
            vertical: isSmallScreen ? 10 : 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildInstructionsCard(List<String> steps, bool isSmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: _primaryGreen,
                  size: isSmallScreen ? 16 : 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'How to Pay',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: isSmallScreen ? 10 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isSmallScreen ? 22 : 24,
                    height: isSmallScreen ? 22 : 24,
                    decoration: BoxDecoration(
                      color: _primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: TextStyle(
                          color: _primaryGreen,
                          fontSize: isSmallScreen ? 11 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: Colors.grey[700],
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: isSmallScreen ? 20 : 40),

                // Success Icon
                Container(
                  width: isSmallScreen ? 100 : 140,
                  height: isSmallScreen ? 100 : 140,
                  decoration: BoxDecoration(
                    color: _primaryGreen,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primaryGreen.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check,
                    size: isSmallScreen ? 60 : 80,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 20 : 30),

                // Success Text
                Text(
                  'Payment Successful!',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 24 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your payment has been confirmed',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: isSmallScreen ? 30 : 40),

                // Payment Details Card - Simplified like your image
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Booking ID
                      Text(
                        'Booking ID',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.bookingId ??
                            'SSA-${DateTime.now().millisecondsSinceEpoch}',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Payment Time
                      Text(
                        'Payment Time',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateTime.now().formatTime(),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Payment Method
                      Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Google Pay',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),

                      if (widget.amount != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Amount Paid',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${widget.amount!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: _primaryGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: isSmallScreen ? 30 : 40),

                // WhatsApp Share Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sharePaymentOnWhatsApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF25D366), // WhatsApp green
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 16 : 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share, size: isSmallScreen ? 20 : 24),
                        const SizedBox(width: 10),
                        Text(
                          'Share Payment on WhatsApp',
                          style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 17,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Back to Home Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => UserHomeScreen()),
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryGreen,
                      side: BorderSide(color: _primaryGreen, width: 1.5),
                      padding: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 16 : 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Back to Home',
                      style: TextStyle(
                          fontSize: isSmallScreen ? 15 : 17,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // WhatsApp sharing function - Fixed to work properly with the phone number
  Future<void> _sharePaymentOnWhatsApp() async {
    String bookingId =
        widget.bookingId ?? 'SSA-${DateTime.now().millisecondsSinceEpoch}';
    String amount =
        widget.amount != null ? '₹${widget.amount!.toStringAsFixed(2)}' : '';
    String dateTime = DateTime.now().formatTime();

    // Format the message
    String message = '''
*SSA Travels*

*Payment Successful!*

Your payment has been confirmed

Booking ID
$bookingId

Payment Time
$dateTime

Payment Method
Google Pay
''';

    // Add amount if available
    if (widget.amount != null) {
      message += '''
    
Amount Paid
$amount''';
    }

    message += '''

Thank you for choosing SSA Travels!''';

    // Clean the phone number - remove any spaces or special characters
    String phoneNumber = _whatsappNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // For Indian numbers, ensure it has +91
    // If the number starts with 91, add +, otherwise add +91
    if (phoneNumber.length == 10) {
      phoneNumber = '91$phoneNumber'; // Add India code for 10-digit numbers
    }

    // Create multiple URL schemes for better compatibility
    final urls = [
      'whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}',
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    ];

    bool launched = false;

    for (String url in urls) {
      if (!launched) {
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            launched = true;
            break;
          }
        } catch (e) {
          debugPrint('Error launching $url: $e');
          // Continue to next URL
        }
      }
    }

    if (!launched) {
      // If WhatsApp couldn't be opened, show a dialog with instructions
      _showWhatsAppInstructions();
    }
  }

// Show instructions dialog when WhatsApp can't be opened
  void _showWhatsAppInstructions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: _primaryGreen),
              const SizedBox(width: 8),
              const Text(
                'Share via WhatsApp',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To share payment receipt:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              _buildInstructionStep(1, 'Open WhatsApp manually'),
              _buildInstructionStep(
                  2, 'Search for this number: $_whatsappNumber'),
              _buildInstructionStep(3, 'Paste this message:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking ID: ${widget.bookingId ?? 'SSA-${DateTime.now().millisecondsSinceEpoch}'}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (widget.amount != null)
                      Text(
                        'Amount: ₹${widget.amount!.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    Text(
                      'Time: ${DateTime.now().formatTime()}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Text(
                      'Method: Google Pay',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _copyToClipboard(_whatsappNumber, 'Number copied to clipboard');
                Navigator.of(context).pop();
              },
              child: Text(
                'Copy Number',
                style: TextStyle(color: _primaryGreen),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

// Helper method for instruction steps
  Widget _buildInstructionStep(int step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  color: _primaryGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    FontWeight? valueWeight,
    required bool isSmallScreen,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
          decoration: BoxDecoration(
            color: _primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(icon, color: _primaryGreen, size: isSmallScreen ? 18 : 20),
        ),
        SizedBox(width: isSmallScreen ? 10 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: valueWeight ?? FontWeight.w500,
                  color: valueColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Extension for time formatting
extension DateTimeExtension on DateTime {
  String formatTime() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} | $day/${month.toString().padLeft(2, '0')}/$year';
  }
}