import 'package:flutter/material.dart';

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
            // Admin FAQ Section
            _buildSection(
              title: 'Admin FAQs',
              children: [
                _buildFAQItem(
                  question: 'How to view all bookings?',
                  answer:
                      'Go to the Bookings section in the admin panel. You can see all trip bookings with customer and driver details.',
                ),
                _buildFAQItem(
                  question: 'How to view trip history?',
                  answer:
                      'Go to the Trips or Reports section in the admin panel. Here you can view all completed trips with customer details, driver information and trip earnings.',
                ),
                _buildFAQItem(
                  question: 'How to check toll charges?',
                  answer:
                      'Go to the Toll Management section where you can view toll routes, toll plazas and their charges stored in the database.',
                ),
                _buildFAQItem(
                  question: 'How to manage vehicles?',
                  answer:
                      'Navigate to Vehicle Management. Here you can add new vehicles, edit vehicle details or remove inactive vehicles.',
                ),
                _buildFAQItem(
                  question: 'How to update vehicle details?',
                  answer:
                      'Go to Vehicle Management, select the vehicle you want to update and edit the required details such as vehicle number, type or status.',
                ),
                _buildFAQItem(
                  question: 'How to view customer details?',
                  answer:
                      'Go to the Users section and select the customer profile to view their booking history and contact information.',
                ),
              ],
            ),
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
                _buildSafetyTip(
                  tip: 'Regularly monitor driver availability and trip status',
                ),
                _buildSafetyTip(
                  tip: 'Ensure toll charges are updated in the database',
                ),
                _buildSafetyTip(
                  tip: 'Review cancelled trips to identify possible issues',
                ),
                _buildSafetyTip(
                  tip: 'Check payment status and resolve pending transactions',
                ),
                _buildSafetyTip(
                  tip: 'Keep vehicle details updated in the system',
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

  Widget _buildSafetyTip({required String tip}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF00B14F)
            .withValues(alpha: 0.1), // Fixed deprecated withOpacity
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

}
