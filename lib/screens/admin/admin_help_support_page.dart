import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminHelpSupportPage extends StatelessWidget {
  const AdminHelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Help & Support',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin FAQ Section (Updated)
            _buildSection(
              title: 'Admin FAQs',
              children: [
                _buildFAQItem(
                  question: 'How to add new driver?',
                  answer:
                      'Go to Driver Management > Add New Driver. Fill driver details, vehicle info and upload documents.',
                ),
                _buildFAQItem(
                  question: 'How to check daily earnings?',
                  answer:
                      'Go to Reports section. You can see daily, weekly and monthly earnings with trip details.',
                ),
                _buildFAQItem(
                  question: 'How to handle customer complaints?',
                  answer:
                      'Check Complaints section, view trip details and contact customer directly through app.',
                ),
                _buildFAQItem(
                  question: 'How to update fare rates?',
                  answer:
                      'Go to Settings > Fare Management. Update base fare and per km rates.',
                ),
                _buildFAQItem(
                  question: 'How to block user?',
                  answer:
                      'Go to User Management, search user and click block option.',
                ),
              ],
            ),
            const SizedBox(height: 30),


          

            const SizedBox(height: 30),

            // Safety Tips (Updated for admin)
            _buildSection(
              title: 'Admin Tips',
              children: [
                _buildSafetyTip(
                  tip: 'Check driver documents carefully before approval',
                ),
                _buildSafetyTip(
                  tip: 'Verify customer complaints with trip details',
                ),
                _buildSafetyTip(
                  tip: 'Take backup of daily reports',
                ),
                _buildSafetyTip(
                  tip: 'Update fare rates during festival seasons',
                ),
              ],
            ),

            const SizedBox(height: 30),            
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00B14F)),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

 
  Widget _buildToolCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00B14F), size: 24),
          const SizedBox(width: 12),
          Column(
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
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip({required String tip}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF00B14F).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF00B14F), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

 

  // Call Functionality
  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showSnackBar(context, 'Could not launch phone app');
    }
  }

  // WhatsApp Functionality
  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (!cleanNumber.startsWith('91') && cleanNumber.length == 10) {
      cleanNumber = '91$cleanNumber';
    }

    final url =
        'https://wa.me/$cleanNumber?text=Hello%20Admin%20Team,%20I%20need%20help';
    final Uri launchUri = Uri.parse(url);

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showSnackBar(context, 'Could not launch WhatsApp');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00B14F),
      ),
    );
  }
}

class _BuildTimingRow extends StatelessWidget {
  final String day;
  final String time;

  const _BuildTimingRow(this.day, this.time);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF00B14F),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}