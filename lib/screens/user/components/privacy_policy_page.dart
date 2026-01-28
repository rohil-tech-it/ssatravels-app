import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B14F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.security,
                        size: 30, color: Color(0xFF00B14F)),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'SSA Travels Virudhunagar',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00B14F)),
                  ),
                  const SizedBox(height: 5),
                  const Text('Privacy Policy',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sections
            _buildSection(
              'Introduction',
              'SSA Travels Virudhunagar protects your privacy. This policy explains how we collect, use, and safeguard your information.',
            ),
            _buildSection(
              'Information We Collect',
              '• Personal details (name, email, phone)\n• Payment information\n• Booking details\n• Location data',
            ),
            _buildSection(
              'How We Use Information',
              '• Process bookings\n• Send confirmations\n• Customer support\n• Improve services\n• Send offers (with consent)',
            ),
            _buildSection(
              'Data Security',
              'We use SSL encryption, secure payments, and regular audits to protect your information.',
            ),
            _buildSection(
              'Your Rights',
              '• Access your data\n• Correct information\n• Delete your data\n• Withdraw consent\n• Opt-out of marketing',
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF00B14F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'We may update this policy. Continued use means you accept changes.',
                style: TextStyle(fontSize: 13),
              ),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00B14F),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('I Understand & Agree'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        Text(
          title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00B14F)),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
      ],
    );
  }
}
