import 'package:flutter/material.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(
            color: Colors.white, // ⬅ white text
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF00B14F),
        iconTheme: const IconThemeData(
          color: Colors.white, // ⬅ back arrow white
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B14F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.description,
                      size: 40,
                      color: Color(0xFF00B14F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'SSA Travels Virudhunagar',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00B14F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Effective Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Acceptance Section
            _buildSectionHeader('1. Acceptance of Terms'),
            const SizedBox(height: 10),
            const Text(
              'By accessing and using the SSA Travels mobile application ("the App"), you agree to be bound by these Terms and Conditions. If you do not agree with any part of these terms, you must not use our App or services.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 20),

            // Account Registration
            _buildSectionHeader('2. Account Registration'),
            const SizedBox(height: 10),

            _buildBulletPoint(
                'Provide accurate and complete information during registration'),
            _buildBulletPoint(
                'You are responsible for maintaining the confidentiality of your account'),
            _buildBulletPoint(
                'Notify us immediately of any unauthorized use of your account'),
            _buildBulletPoint(
                'We reserve the right to suspend or terminate accounts that violate our terms'),

            const SizedBox(height: 20),

            // Booking Terms
            _buildSectionHeader('3. Booking & Ticketing'),
            const SizedBox(height: 10),
            _buildBulletPoint('All bookings are subject to seat availability'),
            _buildBulletPoint(
                'Fares are subject to change without prior notice'),
            _buildBulletPoint(
                'Bookings must be paid in full at the time of reservation'),
            _buildBulletPoint(
                'E-tickets will be sent to your registered email and mobile'),
            _buildBulletPoint('Present valid ID proof during boarding'),

            const SizedBox(height: 20),

            // Cancellation & Refund
            _buildSectionHeader('4. Cancellation & Refund Policy'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00B14F).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF00B14F).withOpacity(0.2)),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.watch_later,
                          size: 18, color: Color(0xFF00B14F)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Before 24 hours of departure: 90% refund',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.watch_later,
                          size: 18, color: Color(0xFF00B14F)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Before 12 hours of departure: 50% refund',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.watch_later,
                          size: 18, color: Color(0xFF00B14F)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Less than 12 hours: No refund',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // User Responsibilities
            _buildSectionHeader('5. User Responsibilities'),
            const SizedBox(height: 10),
            _buildBulletPoint(
                'Arrive at the boarding point at least 30 minutes before departure'),
            _buildBulletPoint('Follow safety instructions during travel'),
            _buildBulletPoint('Respect other passengers and staff'),
            _buildBulletPoint('Do not carry prohibited items'),

            const SizedBox(height: 20),

            // Prohibited Items
            _buildSectionHeader('6. Prohibited Items'),
            const SizedBox(height: 10),

// For mobile - vertical layout
            if (MediaQuery.of(context).size.width < 600)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProhibitedItem(Icons.no_drinks, 'Alcohol'),
                  _buildProhibitedItem(Icons.smoking_rooms, 'Smoking'),
                  _buildProhibitedItem(
                      Icons.fire_extinguisher, 'Flammable items'),
                  _buildProhibitedItem(
                      Icons.pets, 'Pets (except service animals)'),
                  _buildProhibitedItem(Icons.dangerous, 'Weapons'),
                  _buildProhibitedItem(
                      Icons.local_fire_department, 'Explosives'),
                ],
              ),
// For tablet/desktop - 2 column layout
            if (MediaQuery.of(context).size.width >= 600)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProhibitedItem(Icons.no_drinks, 'Alcohol'),
                        _buildProhibitedItem(Icons.smoking_rooms, 'Smoking'),
                        _buildProhibitedItem(
                            Icons.fire_extinguisher, 'Flammable items'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProhibitedItem(
                            Icons.pets, 'Pets (except service animals)'),
                        _buildProhibitedItem(Icons.dangerous, 'Weapons'),
                        _buildProhibitedItem(
                            Icons.local_fire_department, 'Explosives'),
                      ],
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20),
            // Liability
            _buildSectionHeader('7. Liability Limitations'),
            const SizedBox(height: 10),
            const Text(
              'SSA Travels shall not be liable for:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            _buildBulletPoint(
                'Delays caused by traffic, weather, or road conditions'),
            _buildBulletPoint('Loss or damage to personal belongings'),
            _buildBulletPoint('Changes in schedule beyond our control'),
            _buildBulletPoint(
                'Acts of government authorities or force majeure'),

            const SizedBox(height: 20),

            // Intellectual Property
            _buildSectionHeader('8. Intellectual Property'),
            const SizedBox(height: 10),
            const Text(
              'All content, logos, and trademarks displayed on the App are the property of SSA Travels Virudhunagar. You may not reproduce, distribute, or create derivative works without our written permission.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 20),

            // App Usage
            _buildSectionHeader('9. App Usage Guidelines'),
            const SizedBox(height: 10),
            _buildBulletPoint('Do not attempt to hack or modify the App'),
            _buildBulletPoint('Do not use automated scripts or bots'),
            _buildBulletPoint('Respect other users\' privacy'),
            _buildBulletPoint('Report bugs or issues to our support team'),

            const SizedBox(height: 20),

            // Termination
            _buildSectionHeader('10. Termination'),
            const SizedBox(height: 10),
            const Text(
              'We reserve the right to terminate or suspend your access to the App at our sole discretion, without prior notice, for conduct that we believe violates these Terms or is harmful to other users, us, or third parties.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 20),

            // Changes to Terms
            _buildSectionHeader('11. Changes to Terms'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF00B14F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'We may modify these Terms at any time. Continued use of the App after changes constitutes acceptance of the modified Terms.',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Governing Law
            _buildSectionHeader('13. Governing Law'),
            const SizedBox(height: 10),
            const Text(
              'These Terms shall be governed by and construed in accordance with the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts in Virudhunagar, Tamil Nadu.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 30),

            // Agreement Checkbox
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B14F),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'By using SSA Travels App, you acknowledge that you have read, understood, and agree to be bound by these Terms & Conditions.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Accept & Continue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B14F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF00B14F),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 10),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF00B14F),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProhibitedItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.red[600]),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF00B14F)),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }

  void _showDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Download Terms',
          style: TextStyle(color: Color(0xFF00B14F)),
        ),
        content: const Text('Download Terms & Conditions as PDF document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terms downloaded successfully'),
                  backgroundColor: Color(0xFF00B14F),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B14F),
            ),
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
}
