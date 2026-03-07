import 'package:flutter/material.dart';

class AdminAboutPage extends StatelessWidget {
  const AdminAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About App',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF00B14F),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // App Logo
            SizedBox(
              width: 140,
              height: 140,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/ssa-travels.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // About Us Content
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1), // Fixed deprecated withOpacity
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About Us',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00B14F),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildParagraph(
                    'SSA Tours & Travels is a trusted local travel service provider based in Virudhunagar, offering safe and reliable taxi services across Tamil Nadu.',
                  ),
                  const SizedBox(height: 12),
                  _buildParagraph(
                    'We specialize in one-way drop trips, round trips, local city rides, and outstation travel at affordable and transparent pricing.',
                  ),
                  const SizedBox(height: 12),
                  _buildParagraph(
                    'Our services cover Virudhunagar and surrounding areas including Sivakasi, Aruppukottai, Rajapalayam, Srivilliputhur, Madurai, and nearby towns.',
                  ),
                  const SizedBox(height: 12),
                  _buildParagraph(
                    'SSA Travels was started with a focus on customer comfort, fair pricing, and on-time service without unnecessary return or hidden charges.',
                  ),
                  const SizedBox(height: 12),
                  _buildParagraph(
                    'We provide well-maintained vehicles with experienced drivers to ensure a smooth and safe journey for families, business travelers, and tourists.',
                  ),
                  const SizedBox(height: 12),
                  _buildParagraph(
                    'With a growing customer base and strong local presence, SSA Tours & Travels continues to deliver dependable travel solutions every day.',
                  ),
                  const SizedBox(height: 20),

                  // Contact Information
                  _buildContactInfo(),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Features
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Features',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem('Easy Booking', 'Book rides in just a few taps'),
            _buildFeatureItem('Live Tracking', 'Track your ride in real-time'),
            _buildFeatureItem(
                'Multiple Payment Options', 'Cash, Card, UPI & Wallets'),
            _buildFeatureItem(
                'Ride History', 'Access your complete ride history'),
            _buildFeatureItem(
                '24/7 Support', 'Round-the-clock customer support'),

            const SizedBox(height: 30),

            // Version Information
            _buildVersionInfo(),

            const SizedBox(height: 30),

            // Copyright
            const Text(
              '© 2026 SSA Travels. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Helper method to build paragraphs
  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Color.fromARGB(255, 51, 50, 50),
        ),
      ),
    );
  }

  // New method to display contact information
  Widget _buildContactInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text(
          'Contact Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00B14F),
          ),
        ),
        const SizedBox(height: 16),
        _buildContactDetailItem(Icons.location_on, 'Virudhunagar, Tamil Nadu'),
        _buildContactDetailItem(Icons.phone, '+91 98765 43210'),
        _buildContactDetailItem(Icons.email, 'info@ssatravels.com'),
        _buildContactDetailItem(Icons.web, 'www.ssatravels.com'),
      ],
    );
  }

  // Helper method for contact details (renamed and used)
  Widget _buildContactDetailItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00B14F), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // New method for version information
  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'App Version',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00B14F).withValues(alpha: 0.1), // Fixed deprecated withOpacity
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '1.0.0',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00B14F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF00B14F).withValues(alpha: 0.1), // Fixed deprecated withOpacity
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle,
              color: Color(0xFF00B14F),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Note: _buildInfoRow and the original _buildContactDetail methods have been removed
  // as they were unused. The functionality is now covered by _buildContactDetailItem
}