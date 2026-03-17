import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

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
            // FAQ Section
            _buildSection(
              title: 'Frequently Asked Questions',
              children: [
                _buildFAQItem(
                  question: 'How do I book a trip with SSA Travels?',
                  answer:
                      'You can book a trip by selecting your pickup location and destination, choosing the vehicle type, and confirming the trip through the SSA Travels app or by contacting our support.',
                ),
                _buildFAQItem(
                  question: 'Which areas do you serve?',
                  answer:
                      'We provide taxi services in Virudhunagar and surrounding areas including Sivakasi, Aruppukottai, Rajapalayam, Srivilliputhur, Madurai, and nearby towns.',
                ),
                _buildFAQItem(
                  question: 'Do you provide one-way drop trips?',
                  answer:
                      'Yes, we specialize in one-way drop trips as well as round trips at affordable and transparent pricing.',
                ),
                _buildFAQItem(
                  question: 'What payment methods are accepted?',
                  answer:
                      'We accept cash, UPI payments, and popular digital payment options for your convenience.',
                ),
                _buildFAQItem(
                  question: 'Can I cancel or reschedule my trip?',
                  answer:
                      'Yes, trips can be cancelled or rescheduled based on availability. Please contact support as early as possible to avoid cancellation charges.',
                ),
                _buildFAQItem(
                  question: 'Are your drivers experienced and verified?',
                  answer:
                      'Yes, all our drivers are experienced, locally knowledgeable, and verified to ensure a safe and comfortable journey.',
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Contact Support
            _buildSection(
              title: 'Contact Support',
              children: [
                _buildContactOption(
                  icon: Icons.call,
                  title: 'Call Us',
                  subtitle: 'Available 24/7',
                  onTap: () => _makePhoneCall(context, '6374049582'),
                ),
                _buildContactOption(
                  icon: Icons.email,
                  title: 'Email Support',
                  subtitle: 'ssasahinaabideen@gmail.com',
                  onTap: () => _sendEmail(context, 'ssasahinaabideen@gmail.com'),
                ),
                _buildContactOption(
                  icon: Icons.chat,
                  title: 'Live Chat',
                  subtitle: 'Chat with our support team',
                  onTap: () => _openWhatsApp(context, '6374049582'),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Safety Tips
            _buildSection(
              title: 'Safety Tips',
              children: [
                _buildSafetyTip(
                  tip: 'Always verify the vehicle number and driver details',
                ),
                _buildSafetyTip(
                  tip: 'Share your ride details with family/friends',
                ),
                _buildSafetyTip(
                  tip: 'Rate your driver after every ride',
                ),
                _buildSafetyTip(
                  tip: 'Keep emergency contacts saved',
                ),
                _buildSafetyTip(
                  tip: 'Always wear seatbelts during the ride',
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
            color: Color(0xFF00B14F),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
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
              style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 34, 34, 34)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF00B14F).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF00B14F)),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFF00B14F)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSafetyTip({required String tip}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00B14F)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
      if (context.mounted) {
        _showSnackBar(context, 'Could not launch phone app');
      }
    }
  }

  // Email Functionality
  Future<void> _sendEmail(BuildContext context, String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'SSA Travels Support Request',
        'body': 'Hello SSA Travels Team,',
      },
    );

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
        _showSnackBar(context, 'Could not launch email app');
      }
    }
  }

  // WhatsApp Functionality
  Future<void> _openWhatsApp(BuildContext context, String phoneNumber) async {
    // Remove any spaces or special characters
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Check if number starts with country code
    if (!cleanNumber.startsWith('91') && cleanNumber.length == 10) {
      cleanNumber = '91$cleanNumber';
    }

    final url =
        'https://wa.me/$cleanNumber?text=Hello%20SSA%20Travels%20Team,%20I%20need%20assistance%20with:';
    final Uri launchUri = Uri.parse(url);

    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
        _showSnackBar(context, 'Could not launch WhatsApp');
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00B14F),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}