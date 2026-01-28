import 'package:flutter/material.dart';

class WalletTab extends StatefulWidget {
  @override
  _WalletTabState createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  double _balance = 1250.50;
  List<Map<String, dynamic>> _transactions = [
    {'type': 'credit', 'amount': 500.00, 'description': 'Wallet Top-up', 'date': 'Today', 'time': '10:30 AM'},
    {'type': 'debit', 'amount': 250.00, 'description': 'Trip Payment', 'date': 'Yesterday', 'time': '04:15 PM'},
    {'type': 'credit', 'amount': 1000.00, 'description': 'Wallet Top-up', 'date': 'Dec 15', 'time': '11:20 AM'},
    {'type': 'debit', 'amount': 150.00, 'description': 'Trip Payment', 'date': 'Dec 14', 'time': '09:45 AM'},
    {'type': 'debit', 'amount': 300.00, 'description': 'Trip Payment', 'date': 'Dec 12', 'time': '02:30 PM'},
    {'type': 'credit', 'amount': 500.00, 'description': 'Refund', 'date': 'Dec 10', 'time': '05:10 PM'},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
               const Color(0xFF00B14F),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Wallet Balance Card
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                     const Color(0xFF00B14F),
                     const Color(0xFF00B14F),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Wallet Balance',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '₹$_balance',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildWalletAction(
                        icon: Icons.add,
                        label: 'Add Money',
                        onTap: _addMoney,
                      ),
                      _buildWalletAction(
                        icon: Icons.history,
                        label: 'History',
                        onTap: () {
                          // Show transaction history
                        },
                      ),
                      _buildWalletAction(
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () {
                          // Share wallet
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Quick Actions
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.qr_code,
                      label: 'Pay',
                      color: Colors.blue,
                      onTap: () {
                        // Show QR code for payment
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.account_balance,
                      label: 'Bank',
                      color: Colors.orange,
                      onTap: () {
                        // Bank details
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAction(
                      icon: Icons.security,
                      label: 'Security',
                      color: Colors.purple,
                      onTap: () {
                        // Security settings
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Recent Transactions
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // View all transactions
                        },
                        child: Text(
                          'View All',
                          style: TextStyle(color:  const Color(0xFF00B14F)),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  ..._transactions.map((transaction) => _buildTransactionItem(
                    type: transaction['type'],
                    amount: transaction['amount'],
                    description: transaction['description'],
                    date: transaction['date'],
                    time: transaction['time'],
                  )).toList(),
                ],
              ),
            ),

            // Offers Section
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Offers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildOfferCard(
                    title: 'First Ride Offer',
                    description: 'Get 20% off on your first ride',
                    code: 'FIRST20',
                    validUntil: 'Valid until Dec 31, 2023',
                  ),
                  SizedBox(height: 12),
                  _buildOfferCard(
                    title: 'Weekend Special',
                    description: 'Flat ₹100 off on weekend rides',
                    code: 'WEEKEND100',
                    validUntil: 'Valid every weekend',
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem({
    required String type,
    required double amount,
    required String description,
    required String date,
    required String time,
  }) {
    bool isCredit = type == 'credit';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCredit ?  const Color(0xFF00B14F).withOpacity(0.1) : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ?  const Color(0xFF00B14F) : Colors.red,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '$date • $time',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : '-'}₹$amount',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isCredit ?  const Color(0xFF00B14F) : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard({
    required String title,
    required String description,
    required String code,
    required String validUntil,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
             const Color(0xFF00B14F),
             const Color(0xFF00B14F),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color:  const Color(0xFF00B14F)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color:  const Color(0xFF00B14F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.local_offer,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color:  const Color(0xFF00B14F),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color:  const Color(0xFF00B14F)),
                      ),
                      child: Text(
                        'CODE: $code',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:  const Color(0xFF00B14F),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      validUntil,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            color:  const Color(0xFF00B14F),
            size: 16,
          ),
        ],
      ),
    );
  }

  void _addMoney() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Money to Wallet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:  const Color(0xFF00B14F),
              ),
            ),
            SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildAmountOption('₹100'),
                _buildAmountOption('₹200'),
                _buildAmountOption('₹500'),
                _buildAmountOption('₹1000'),
                _buildAmountOption('₹2000'),
                _buildAmountOption('Other'),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Payment gateway will open...'),
                    backgroundColor:  const Color(0xFF00B14F),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:  const Color(0xFF00B14F),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Proceed to Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountOption(String amount) {
    return GestureDetector(
      onTap: () {
        // Handle amount selection
      },
      child: Container(
        decoration: BoxDecoration(
          color:  const Color(0xFF00B14F),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color:  const Color(0xFF00B14F)),
        ),
        child: Center(
          child: Text(
            amount,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color:  const Color(0xFF00B14F),
            ),
          ),
        ),
      ),
    );
  }
}