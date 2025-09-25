import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:selforder/models/payment_model.dart';
import 'package:selforder/services/api_service.dart';
import 'package:selforder/services/auth_service.dart';
import 'package:selforder/models/order_model.dart';
import 'package:selforder/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  String _selectedFilter = 'All';
  final List<String> _filterOptions = [
    'All',
    'Menunggu Pembayaran',
    'Antrean',
    'Proses',
    'Terkirim',
    'Dibatalkan',
  ];

  final DateFormat _dateFormat = DateFormat('dd-MM-yyyy HH:mm');

  List<Order> _allOrders = [];
  bool _isLoading = true;

  late Function() _authListener;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _loadOrders();
  }

  @override
  void dispose() {
    AuthService.removeAuthStateListener(_authListener);
    super.dispose();
  }

  void _setupAuthListener() {
    _authListener = () {
      if (mounted) {
        setState(() {});
        _loadOrders();
      }
    };
    AuthService.addAuthStateListener(_authListener);
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);

    try {
      if (!AuthService.isLoggedIn) {
        setState(() {
          _allOrders = [];
          _isLoading = false;
        });
        return;
      }

      final orders = await ApiService.fetchOrders();
      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Gagal memuat pesanan: ${e.toString()}');
    }
  }

  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login').then((result) {});
  }

  List<Order> get _filteredOrders {
    if (_selectedFilter == 'All') {
      return _allOrders;
    }
    return _allOrders.where((order) {
      return order.status.label == _selectedFilter;
    }).toList();
  }

  Future<void> _refreshOrders() async {
    await _loadOrders();
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Pesanan #${order.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Invoice', order.nomorInvoice),
              _buildDetailRow('Table Number', order.nomorMeja),
              _buildDetailRow('Status', order.status.label),
              _buildDetailRow('Total Amount', 'Rp ${order.totalHarga}'),

              _buildDetailRow('Item Total', 'Rp ${order.totalHargaBarang}'),
              _buildDetailRow('Payment Fee', 'Rp ${order.paymentFee}'),
              _buildDetailRow('Date', _formatDate(order.created)),
              if (order.member != null) ...[
                const Divider(height: 20),
                const Text(
                  'Customer Information:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('Name: ${order.member!.fullName}'),
                Text('Email: ${order.member!.email}'),
              ],
              if (order.payment != null) ...[
                const Divider(height: 20),
                const Text(
                  'Informasi Pembayaran:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('Method: ${order.payment!.metodePembayaran}'),
                Text('Status: ${order.payment!.status.label}'),
                if (order.payment!.reference.isNotEmpty)
                  Text('Reference: ${order.payment!.reference}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _openPaymentUrl(String paymentUrl) async {
    final uri = Uri.parse(paymentUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Tidak dapat membuka halaman pembayaran');
    }
  }

  Future<void> _sendInvoiceEmail(Order order) async {
    try {
      final success = await ApiService.sendInvoiceEmail(order.id.toString());
      if (success) {
        _showSuccessSnackBar('Invoice berhasil dikirim ke Email');
      } else {
        _showErrorSnackBar('Gagal mengirim invoice ke email');
      }
    } catch (e) {
      _showErrorSnackBar('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<void> _downloadInvoicePdf(Order order) async {
    try {
      final pdfBytes = await ApiService.getInvoicePdfBytes(order.id.toString());

      // Simpan ke file sementara
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/Invoice-${order.nomorInvoice}.pdf';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Buka file PDF
      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        _showErrorSnackBar('Gagal membuka file PDF');
      }
    } catch (e) {
      _showErrorSnackBar('Terjadi kesalahan: ${e.toString()}');
    }
  }

  String _formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthService.isLoggedIn) {
      return _buildNotAuthenticatedView();
    }

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshOrders,
        child: Column(
          children: [
            // Filter Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Status:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
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
                            selectedColor: AppColors.blue.withAlpha(51),
                            checkmarkColor: AppColors.blue,
                            backgroundColor: AppColors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.blue
                                    : AppColors.grey,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.login, size: 80, color: AppColors.grey),
            const SizedBox(height: 16),
            Text(
              'Silahkan masuk untuk melihat pesanan anda',
              style: TextStyle(fontSize: 16, color: AppColors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
              child: const Text('Masuk'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyOrdersView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.grey),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'All'
                ? 'Pesanan tidak ditemukan'
                : 'Tidak ada $_selectedFilter pesanan',
            style: TextStyle(fontSize: 16, color: AppColors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Pesanan Anda akan ditampilkan di sini',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
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

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
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
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: order.status.color.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: order.status.color),
                    ),
                    child: Text(
                      order.status.label,
                      style: TextStyle(
                        color: order.status.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Order Details
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.receipt,
                              size: 16,
                              color: AppColors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.nomorInvoice,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.table_restaurant,
                              size: 16,
                              color: AppColors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Meja ${order.nomorMeja}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        if (order.payment != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.payment,
                                size: 16,
                                color: AppColors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                order.payment!.metodePembayaran,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rp ${order.totalHarga}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(order.created),
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tombol Detail (selalu muncul di semua kondisi)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showOrderDetails(order),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Detail'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        textStyle: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),

                  // Tambahan kondisi: jika status == "Dibatalkan", tidak tampilkan tombol lain
                  if (order.status.label == 'Dibatalkan')
                    const SizedBox()
                  else if (order.status.label == 'Menunggu Pembayaran' &&
                      order.payment?.paymentUrl != null &&
                      order.payment!.paymentUrl.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _openPaymentUrl(order.payment!.paymentUrl),
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Bayar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _sendInvoiceEmail(order),
                        icon: const Icon(Icons.email, size: 16),
                        label: const Text('Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadInvoicePdf(order),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
