// lib/screens/admin/admin_dashboard.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class AdminDashboard extends StatefulWidget {
  final VoidCallback? onViewBookings;
  final VoidCallback? onUpdatePrices;

  const AdminDashboard({
    super.key, // ← super parameter
    this.onViewBookings,
    this.onUpdatePrices,
  });

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _totalBookings = 0;
  final int _activeVehicles = 8;
  double _todayRevenue = 0.0;
  double _monthlyRevenue = 0.0;
  int _pendingActions = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentBookings = [];

  // Responsive variables
  late bool _isMobile;
  late bool _isTablet;
  late double _screenWidth;

  // Admin theme colors
  final Color _adminPrimaryColor = const Color(0xFF00C853);
  final Color _adminBackground = const Color(0xFFF5FDF8);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      DateTime now = DateTime.now();
      DateTime todayStart = DateTime(now.year, now.month, now.day);
      DateTime todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
      DateTime monthStart = DateTime(now.year, now.month, 1);
      DateTime monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Get total bookings count
      var bookingsSnapshot =
          await FirebaseFirestore.instance.collection('bookings').get();
      _totalBookings = bookingsSnapshot.docs.length;

      // Get today's revenue
      var todayBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('createdAt', isGreaterThanOrEqualTo: todayStart)
          .where('createdAt', isLessThanOrEqualTo: todayEnd)
          .get();

      _todayRevenue = todayBookings.docs.fold(0.0, (total, doc) {
        return total + (doc['amount'] as double);
      });

      // Get monthly revenue
      var monthlyBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('createdAt', isGreaterThanOrEqualTo: monthStart)
          .where('createdAt', isLessThanOrEqualTo: monthEnd)
          .get();

      _monthlyRevenue = monthlyBookings.docs.fold(0.0, (total, doc) {
        return total + (doc.data()['totalAmount'] ?? 0.0);
      });

      // Get recent bookings
      var recentBookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      _recentBookings = recentBookingsSnapshot.docs.map((doc) {
        var data = doc.data();
        return {
          'id': doc.id,
          'customerName': data['customerName'] ?? 'N/A',
          'vehicleType': data['vehicleType'] ?? 'N/A',
          'amount': data['totalAmount'] ?? 0.0,
          'status': data['status'] ?? 'pending',
          'time': _formatTime(data['createdAt']),
        };
      }).toList();

      // Get pending actions
      var pendingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('status', whereIn: ['pending', 'processing']).get();
      _pendingActions = pendingSnapshot.docs.length;

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';

    DateTime time = timestamp.toDate();
    DateTime now = DateTime.now();
    Duration difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('dd MMM yyyy').format(time);
    }
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    _screenWidth = MediaQuery.of(context).size.width;
    _isMobile = _screenWidth < 600;
    _isTablet = _screenWidth >= 600 && _screenWidth < 1200;

    return Scaffold(
      backgroundColor: _adminBackground,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: _adminPrimaryColor,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(_isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              _buildWelcomeCard(),
              SizedBox(height: _isMobile ? 16 : 20),

              // Quick Stats Grid
              Text(
                'Quick Overview',
                style: TextStyle(
                  fontSize: _isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: _isMobile ? 10 : 12),
              _buildStatsGrid(),

              SizedBox(height: _isMobile ? 20 : 25),

              // Quick Actions
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: _isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: _isMobile ? 10 : 12),
              _buildQuickActions(),

              SizedBox(height: _isMobile ? 20 : 25),

              // Recent Activity
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(_isMobile ? 16 : 20),
        child: Row(
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: _isMobile ? 32 : 40,
              color: _adminPrimaryColor,
            ),
            SizedBox(width: _isMobile ? 12 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, Admin!',
                    style: TextStyle(
                      fontSize: _isMobile ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: _isMobile ? 3 : 5),
                  Text(
                    'Manage your travel operations efficiently',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: _isMobile ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              CircularProgressIndicator(
                color: _adminPrimaryColor,
                strokeWidth: 2,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_isLoading) return _buildLoadingStats();

    int crossAxisCount = _isMobile ? 2 : (_isTablet ? 3 : 4);
    double childAspectRatio = _isMobile ? 1.2 : (_isTablet ? 1.4 : 1.3);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: _isMobile ? 8 : 12,
      mainAxisSpacing: _isMobile ? 8 : 12,
      childAspectRatio: childAspectRatio,
      children: [
        _buildStatCard(
          title: 'Total Bookings',
          value: '$_totalBookings',
          icon: Icons.book,
          color: Colors.blue,
          subTitle: 'All time bookings',
        ),
        _buildStatCard(
          title: 'Active Vehicles',
          value: '$_activeVehicles',
          icon: Icons.directions_car,
          color: _adminPrimaryColor,
          subTitle: 'All operational',
        ),
        _buildStatCard(
          title: 'Today\'s Revenue',
          value: _formatCurrency(_todayRevenue),
          icon: Icons.currency_rupee,
          color: Colors.orange,
          subTitle: 'From today bookings',
        ),
        _buildStatCard(
          title: 'Monthly Revenue',
          value: _formatCurrency(_monthlyRevenue),
          icon: Icons.bar_chart,
          color: Colors.purple,
          subTitle: DateFormat('MMMM yyyy').format(DateTime.now()),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subTitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(_isMobile ? 12 : 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(_isMobile ? 6 : 8),
                  decoration: BoxDecoration(
                    color: color.withAlpha((0.1 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: _isMobile ? 16 : 20),
                ),
              ],
            ),
            SizedBox(height: _isMobile ? 8 : 12),
            Text(
              value,
              style: TextStyle(
                fontSize: _isMobile ? 18 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: _isMobile ? 11 : 13,
              ),
            ),
            if (subTitle != null) ...[
              SizedBox(height: _isMobile ? 2 : 4),
              Text(
                subTitle,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: _isMobile ? 9 : 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingStats() {
    int crossAxisCount = _isMobile ? 2 : (_isTablet ? 3 : 4);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: _isMobile ? 8 : 12,
      mainAxisSpacing: _isMobile ? 8 : 12,
      childAspectRatio: _isMobile ? 1.2 : 1.3,
      children: List.generate(4, (index) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(_isMobile ? 12 : 16),
            child: Center(
              child: CircularProgressIndicator(
                color: _adminPrimaryColor,
                strokeWidth: 2,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildQuickActions() {
    int crossAxisCount = _isMobile ? 2 : 2;
    double childAspectRatio = _isMobile ? 1.4 : 1.5;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: _isMobile ? 8 : 12,
      mainAxisSpacing: _isMobile ? 8 : 12,
      childAspectRatio: childAspectRatio,
      children: [
        _buildActionCard(
          title: 'Update Prices',
          icon: Icons.price_change,
          onTap: () {
            if (widget.onUpdatePrices != null) {
              widget.onUpdatePrices!();
            }
          },
        ),
        _buildActionCard(
          title: 'View Bookings',
          icon: Icons.list_alt,
          onTap: () {
            if (widget.onViewBookings != null) {
              widget.onViewBookings!();
            }
          },
        ),
        _buildActionCard(
          title: 'Generate Report',
          icon: Icons.assignment,
          onTap: () {
            _showReportOptions(context);
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(_isMobile ? 12 : 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: _isMobile ? 24 : 30,
                color: _adminPrimaryColor,
              ),
              SizedBox(height: _isMobile ? 6 : 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                  fontSize: _isMobile ? 12 : 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: EdgeInsets.all(_isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history,
                    color: _adminPrimaryColor, size: _isMobile ? 18 : 24),
                SizedBox(width: _isMobile ? 6 : 8),
                Text(
                  'Recent Bookings',
                  style: TextStyle(
                    fontSize: _isMobile ? 14 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_recentBookings.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      if (widget.onViewBookings != null) {
                        widget.onViewBookings!();
                      }
                    },
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color: _adminPrimaryColor,
                        fontSize: _isMobile ? 11 : 12,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: _isMobile ? 10 : 12),
            _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: _adminPrimaryColor))
                : _recentBookings.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'No recent bookings',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    : Column(
                        children: _recentBookings
                            .map((booking) => _buildBookingItem(booking))
                            .toList(),
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingItem(Map<String, dynamic> booking) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _isMobile ? 6 : 8),
      child: Row(
        children: [
          Container(
            width: _isMobile ? 6 : 8,
            height: _isMobile ? 6 : 8,
            decoration: BoxDecoration(
              color: _getStatusColor(booking['status']),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: _isMobile ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking['customerName']} - ${booking['vehicleType']}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: _isMobile ? 12 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: _isMobile ? 1 : 2),
                Text(
                  '${_formatCurrency(booking['amount'])} • ${booking['status']}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: _isMobile ? 10 : 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            booking['time'],
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: _isMobile ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF00B14F);
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return _adminPrimaryColor;
    }
  }

  void _showReportOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Generate Report',
            style: TextStyle(color: _adminPrimaryColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.picture_as_pdf, color: _adminPrimaryColor),
              title: const Text('PDF Report'),
              subtitle: const Text('Detailed report in PDF format'),
              onTap: () {
                Navigator.pop(context);
                _generatePDFReport(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today, color: _adminPrimaryColor),
              title: const Text('Monthly Report'),
              subtitle: const Text('This month\'s performance'),
              onTap: () {
                Navigator.pop(context);
                _generateMonthlyReport(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.summarize, color: _adminPrimaryColor),
              title: const Text('Quick Summary'),
              subtitle: const Text('Today\'s overview'),
              onTap: () {
                Navigator.pop(context);
                _generateQuickSummary(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  Future<void> _generatePDFReport(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _adminPrimaryColor),
                const SizedBox(height: 20),
                const Text('Generating PDF Report...'),
              ],
            ),
          ),
        ),
      );

      // Create a new PDF document
      PdfDocument document = PdfDocument();

      // Add a new page
      PdfPage page = document.pages.add();
      PdfGraphics graphics = page.graphics;

      // Load font
      final PdfFont font = PdfStandardFont(PdfFontFamily.helvetica, 12);
      final PdfFont titleFont = PdfStandardFont(PdfFontFamily.helvetica, 20,
          style: PdfFontStyle.bold);
      final PdfFont headerFont = PdfStandardFont(PdfFontFamily.helvetica, 16,
          style: PdfFontStyle.bold);

      // Draw title
      graphics.drawString('SSA TRAVELS - ADMIN REPORT', titleFont,
          bounds: Rect.fromLTWH(0, 20, page.getClientSize().width, 50),
          format: PdfStringFormat(alignment: PdfTextAlignment.center));

      // Draw report date
      String reportDate =
          DateFormat('dd MMMM yyyy hh:mm a').format(DateTime.now());
      graphics.drawString('Generated on: $reportDate', font,
          bounds: Rect.fromLTWH(0, 80, page.getClientSize().width, 20),
          format: PdfStringFormat(alignment: PdfTextAlignment.center));

      // Draw summary section
      graphics.drawString('SUMMARY', headerFont,
          bounds: Rect.fromLTWH(50, 120, page.getClientSize().width, 30));

      double yPos = 160;
      List<String> summaryItems = [
        '• Total Bookings: $_totalBookings',
        '• Active Vehicles: $_activeVehicles',
        '• Today\'s Revenue: ${_formatCurrency(_todayRevenue)}',
        '• Monthly Revenue: ${_formatCurrency(_monthlyRevenue)}',
        '• Pending Actions: $_pendingActions',
        '• Recent Bookings: ${_recentBookings.length}',
      ];

      for (var item in summaryItems) {
        graphics.drawString(item, font,
            bounds: Rect.fromLTWH(70, yPos, page.getClientSize().width, 20));
        yPos += 25;
      }

      // Draw recent bookings section
      yPos += 30;
      graphics.drawString('RECENT BOOKINGS', headerFont,
          bounds: Rect.fromLTWH(50, yPos, page.getClientSize().width, 30));

      yPos += 40;
      for (var booking in _recentBookings.take(10)) {
        String bookingText =
            '• ${booking['customerName']} - ${booking['vehicleType']} - ${_formatCurrency(booking['amount'])} - ${booking['status']}';
        graphics.drawString(bookingText, font,
            bounds: Rect.fromLTWH(70, yPos, page.getClientSize().width, 20));
        yPos += 25;
      }

      // Save the document
      List<int> bytes = await document.save();
      document.dispose();

      // Get application documents directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception("Could not access storage directory");
      }

      // Create PDF file
      String fileName =
          'SSA_Travels_Report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      String filePath = '${directory.path}/$fileName';
      File file = File(filePath);

      // Write PDF bytes to file
      await file.writeAsBytes(bytes, flush: true);

      // Close loading dialog
      Navigator.pop(context);

      // Open the PDF file
      await OpenFile.open(filePath);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF report saved to: $filePath'),
          backgroundColor: _adminPrimaryColor,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating report: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateMonthlyReport(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _adminPrimaryColor),
                const SizedBox(height: 20),
                const Text('Generating Monthly Report...'),
              ],
            ),
          ),
        ),
      );

      // Fetch monthly data
      DateTime now = DateTime.now();
      DateTime monthStart = DateTime(now.year, now.month, 1);
      DateTime monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      var monthlyBookings = await FirebaseFirestore.instance
          .collection('bookings')
          .where('createdAt', isGreaterThanOrEqualTo: monthStart)
          .where('createdAt', isLessThanOrEqualTo: monthEnd)
          .get();

      // Generate report
      String monthName = DateFormat('MMMM yyyy').format(now);
      String reportContent = '''
SSA TRAVELS - MONTHLY REPORT ($monthName)

📊 SUMMARY:
• Total Bookings: ${monthlyBookings.docs.length}
• Monthly Revenue: ${_formatCurrency(_monthlyRevenue)}
• Average per Booking: ${_formatCurrency(_monthlyRevenue / (monthlyBookings.docs.length == 0 ? 1 : monthlyBookings.docs.length))}
• Pending Bookings: $_pendingActions

Generated on: ${DateFormat('dd MMM yyyy hh:mm a').format(DateTime.now())}
      ''';

      Navigator.pop(context);

      // Show report
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Monthly Report - $monthName'),
          content: SingleChildScrollView(
            child: Text(reportContent),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () => _generatePDFReport(context),
              child: Text('Export as PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _adminPrimaryColor,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateQuickSummary(BuildContext context) async {
    String summary = '''
🚀 SSA TRAVELS - QUICK SUMMARY

📈 TODAY'S PERFORMANCE:
• Revenue: ${_formatCurrency(_todayRevenue)}
• Recent Bookings: ${_recentBookings.length}
• Pending Actions: $_pendingActions

📊 OVERALL STATS:
• Total Bookings: $_totalBookings
• Active Vehicles: $_activeVehicles
• Monthly Revenue: ${_formatCurrency(_monthlyRevenue)}

⏰ LAST UPDATED: ${DateFormat('hh:mm a').format(DateTime.now())}
    ''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Summary'),
        content: SingleChildScrollView(
          child: Text(summary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => _generatePDFReport(context),
            child: const Text('Save as PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _adminPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
