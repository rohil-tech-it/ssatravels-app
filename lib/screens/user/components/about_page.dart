import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About App',
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
          children: [
            // App Logo
            Container(
              width: 140,
              height: 140,
              child: Padding(
                padding: const EdgeInsets.all(6), // ⬅ reduce padding
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
                    color: Colors.grey.withOpacity(0.1),
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
                      color: Color(0xFF00B14F), // Green heading
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
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Features (Unchanged - Keep existing)
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
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
              color: const Color(0xFF00B14F).withOpacity(0.1),
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

  Widget _buildContactDetail(IconData icon, String text) {
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
}
