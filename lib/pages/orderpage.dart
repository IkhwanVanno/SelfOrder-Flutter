import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  bool _isAuthenticated = false; // Simulate authentication state
  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'Pending',
    'Processing',
    'Completed',
    'Cancelled',
  ];

  final DateFormat _dateFormat = DateFormat('dd-MM-yyyy HH:mm');
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  // Dummy orders data
  final List<Map<String, dynamic>> _allOrders = [
    {
      'ID': 1001,
      'InvoiceNumber': 'INV-2024-001',
      'TableNumber': 5,
      'Status': 'Completed',
      'PaymentMethod': 'Credit Card',
      'TotalAmount': 87500,
      'Created': DateTime.now().subtract(const Duration(hours: 2)),
      'Items': [
        {'ProductName': 'Cappuccino', 'Quantity': 2, 'Price': 25000},
        {'ProductName': 'Croissant', 'Quantity': 1, 'Price': 22000},
        {'ProductName': 'Cheesecake', 'Quantity': 1, 'Price': 40000},
      ],
    },
    {
      'ID': 1002,
      'InvoiceNumber': 'INV-2024-002',
      'TableNumber': 3,
      'Status': 'Processing',
      'PaymentMethod': 'Digital Wallet',
      'TotalAmount': 45000,
      'Created': DateTime.now().subtract(const Duration(minutes: 30)),
      'Items': [
        {'ProductName': 'Latte', 'Quantity': 1, 'Price': 28000},
        {'ProductName': 'Muffin', 'Quantity': 1, 'Price': 18000},
      ],
    },
    {
      'ID': 1003,
      'InvoiceNumber': 'INV-2024-003',
      'TableNumber': 8,
      'Status': 'Pending',
      'PaymentMethod': 'Bank Transfer',
      'TotalAmount': 32000,
      'Created': DateTime.now().subtract(const Duration(minutes: 15)),
      'Items': [
        {'ProductName': 'Americano', 'Quantity': 1, 'Price': 18000},
        {'ProductName': 'Green Tea', 'Quantity': 1, 'Price': 12000},
      ],
    },
    {
      'ID': 1004,
      'InvoiceNumber': 'INV-2024-004',
      'TableNumber': 2,
      'Status': 'Cancelled',
      'PaymentMethod': 'Cash',
      'TotalAmount': 25000,
      'Created': DateTime.now().subtract(const Duration(days: 1)),
      'Items': [
        {'ProductName': 'Espresso', 'Quantity': 1, 'Price': 15000},
      ],
    },
    {
      'ID': 1005,
      'InvoiceNumber': 'INV-2024-005',
      'TableNumber': 12,
      'Status': 'Completed',
      'PaymentMethod': 'Credit Card',
      'TotalAmount': 125000,
      'Created': DateTime.now().subtract(const Duration(days: 2)),
      'Items': [
        {'ProductName': 'Mocha', 'Quantity': 2, 'Price': 32000},
        {'ProductName': 'Tiramisu', 'Quantity': 2, 'Price': 45000},
        {'ProductName': 'Sandwich', 'Quantity': 1, 'Price': 35000},
      ],
    },
  ];

  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login').then((result) {
      if (result == true) {
        setState(() {
          _isAuthenticated = true;
        });
      }
    });
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedFilter == 'All') {
      return _allOrders;
    }
    return _allOrders.where((order) {
      final status = order['Status'] ?? 'Unknown';
      return status.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();
  }

  Future<void> _refreshOrders() async {
    // Simulate refresh
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }

  void _downloadReceipt(Map<String, dynamic> order) {
    _showSuccessSnackBar('Receipt download started (Demo)');
  }

  void _shareReceipt(Map<String, dynamic> order) {
    _showSuccessSnackBar('Receipt shared successfully (Demo)');
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Order ID', order['ID']?.toString() ?? 'N/A'),
              _buildDetailRow('Invoice', order['InvoiceNumber'] ?? 'N/A'),
              _buildDetailRow(
                'Table Number',
                order['TableNumber']?.toString() ?? 'N/A',
              ),
              _buildDetailRow('Status', order['Status'] ?? 'N/A'),
              _buildDetailRow(
                'Payment Method',
                order['PaymentMethod'] ?? 'N/A',
              ),
              _buildDetailRow(
                'Total Amount',
                _currencyFormat.format(order['TotalAmount'] ?? 0),
              ),
              _buildDetailRow('Date', _formatDate(order['Created'])),
              if (order['Items'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Items:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...((order['Items'] as List).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text(
                      '• ${item['ProductName']} x${item['Quantity']} - Rp ${_formatCurrencySimple(item['Price'])}',
                    ),
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _downloadReceipt(order);
            },
            child: const Text('Download Receipt'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    DateTime dateTime;
    if (date is String) {
      dateTime = DateTime.tryParse(date) ?? DateTime.now();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'N/A';
    }

    return _dateFormat.format(dateTime);
  }

  String _formatCurrencySimple(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Simulate authentication - for demo, set to true after a delay
    if (!_isAuthenticated) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
          });
        }
      });
    }

    if (!_isAuthenticated) {
      return _buildNotAuthenticatedView();
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: Column(
          children: [
            // Filter Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Filter by Status:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filterOptions.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(filter),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                }
                              },
                              selectedColor: Colors.blue.withAlpha(51),
                              checkmarkColor: Colors.blue,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Orders List
            Expanded(
              child: _filteredOrders.isEmpty
                  ? _buildEmptyOrdersView()
                  : _buildOrdersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotAuthenticatedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Please login to view your orders',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _navigateToLogin,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All'
                ? 'No orders found'
                : 'No $_selectedFilter orders',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Your orders will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: _refreshOrders, child: const Text('Refresh')),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredOrders.length,
      itemBuilder: (context, index) {
        final order = _filteredOrders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['Status'] ?? 'Unknown';
    final statusColor = _getStatusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order['ID'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Order Details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invoice: ${order['InvoiceNumber'] ?? 'N/A'}'),
                        Text('Table: ${order['TableNumber'] ?? 'N/A'}'),
                        Text('Payment: ${order['PaymentMethod'] ?? 'N/A'}'),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currencyFormat.format(order['TotalAmount'] ?? 0),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        _formatDate(order['Created']),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _shareReceipt(order),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('Share'),
                    style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () => _downloadReceipt(order),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Download'),
                    style: TextButton.styleFrom(foregroundColor: Colors.green),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
