import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:selforder/controllers/auth_controller.dart';
import 'package:selforder/controllers/order_controller.dart';
import 'package:selforder/models/order_model.dart';
import 'package:selforder/models/payment_model.dart';
import 'package:selforder/routes/app_routes.dart';
import 'package:selforder/theme/app_theme.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final orderController = Get.find<OrderController>();

    return Scaffold(
      body: Obx(() {
        if (!authController.isLoggedIn) {
          return _buildNotAuthenticatedView();
        }

        if (orderController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => orderController.refresh(),
          child: Column(
            children: [
              // Filter Section
              _buildFilterSection(orderController),

              // Orders List
              Expanded(
                child: orderController.filteredOrders.isEmpty
                    ? _buildEmptyOrdersView(orderController)
                    : _buildOrdersList(orderController),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildNotAuthenticatedView() {
    return Center(
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
            onPressed: () => Get.toNamed(AppRoutes.LOGIN),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Masuk'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(OrderController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Status:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 12),
          Obx(
            () => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: controller.filterOptions.map((filter) {
                  final isSelected = controller.selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(filter),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          controller.setFilter(filter);
                        }
                      },
                      selectedColor: AppColors.blue.withAlpha(51),
                      checkmarkColor: AppColors.blue,
                      backgroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.blue : AppColors.grey,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOrdersView(OrderController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: AppColors.grey),
          const SizedBox(height: 16),
          Obx(
            () => Text(
              controller.selectedFilter == 'All'
                  ? 'Pesanan tidak ditemukan'
                  : 'Tidak ada ${controller.selectedFilter} pesanan',
              style: TextStyle(fontSize: 16, color: AppColors.grey),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pesanan Anda akan ditampilkan di sini',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => controller.refresh(),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(OrderController controller) {
    return Obx(
      () => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.filteredOrders.length,
        itemBuilder: (context, index) {
          final order = controller.filteredOrders[index];
          return _buildOrderCard(order, controller);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order, OrderController controller) {
    final dateFormat = DateFormat('dd-MM-yyyy HH:mm');
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetails(order, currencyFormat, dateFormat),
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
                        currencyFormat.format(order.totalHarga),
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
                            dateFormat.format(order.created),
                            style: const TextStyle(
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

              //information
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: AppColors.orange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      order.status.label == 'Menunggu Pembayaran'
                          ? 'Segera melakukan pembayaran sebelum waktu habis.'
                          : order.status.label == 'Dibatalkan'
                          ? 'Pesanan ini telah dibatalkan.'
                          : order.status.label == 'Antrean'
                          ? 'Pesanan Anda sedang dalam antrean.'
                          : order.status.label == 'Proses'
                          ? 'Pesanan Anda sedang diproses, mohon menunggu.'
                          : order.status.label == 'Selesai'
                          ? 'Pesanan ini telah selesai.'
                          : 'Untuk informasi lebih lanjut, silakan cek detail pesanan.',
                      style: TextStyle(fontSize: 13, color: AppColors.orange),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action Buttons
              Row(
                children: [
                  // Detail
                  Expanded(
                    child: _actionButton(
                      icon: Icons.info_outline,
                      label: 'Detail',
                      onPressed: () =>
                          _showOrderDetails(order, currencyFormat, dateFormat),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Batalkan Pesanan
                  if (controller.canCancelOrder(order)) ...[
                    Expanded(
                      child: _actionButton(
                        icon: Icons.cancel_outlined,
                        label: 'Batalkan',
                        color: Colors.red.shade400,
                        onPressed: () async {
                          final confirm = await Get.dialog<bool>(
                            AlertDialog(
                              title: const Text('Batalkan Pesanan'),
                              content: Text(
                                'Apakah Anda yakin ingin membatalkan pesanan ${order.nomorInvoice}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(result: false),
                                  child: const Text('Tidak'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Get.back(result: true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Ya, Batalkan'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await controller.cancelOrder(order.id.toString());
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Aksi Pembayaran / Email / PDF
                  if (order.status.label != 'Dibatalkan') ...[
                    if (order.status.label == 'Menunggu Pembayaran' &&
                        order.payment?.paymentUrl != null &&
                        order.payment!.paymentUrl.isNotEmpty) ...[
                      Expanded(
                        child: _actionButton(
                          icon: Icons.payment,
                          label: 'Bayar',
                          color: AppColors.green,
                          onPressed: () =>
                              _openPaymentUrl(order.payment!.paymentUrl),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: _actionButton(
                          icon: Icons.email,
                          label: 'Email',
                          color: AppColors.orange,
                          onPressed: () =>
                              controller.sendInvoiceEmail(order.id.toString()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionButton(
                          icon: Icons.download,
                          label: 'PDF',
                          color: AppColors.blue,
                          onPressed: () => controller.downloadInvoicePdf(order),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        textStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showOrderDetails(
    Order order,
    NumberFormat currencyFormat,
    DateFormat dateFormat,
  ) {
    Get.dialog(
      AlertDialog(
        title: Text('Detail Pesanan #${order.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Invoice', order.nomorInvoice),
              _buildDetailRow('Table Number', order.nomorMeja),
              _buildDetailRow('Status', order.status.label),
              _buildDetailRow(
                'Total Amount',
                currencyFormat.format(order.totalHarga),
              ),
              _buildDetailRow(
                'Item Total',
                currencyFormat.format(order.totalHargaBarang),
              ),
              _buildDetailRow(
                'Payment Fee',
                currencyFormat.format(order.paymentFee),
              ),
              _buildDetailRow('Date', dateFormat.format(order.created)),

              if (order.orderItems.isNotEmpty) ...[
                const Divider(height: 20),
                const Text(
                  'Daftar Pesanan:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Column(
                  children: order.orderItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.displayText,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
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
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
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

  Future<void> _openPaymentUrl(String paymentUrl) async {
    try {
      final uri = Uri.parse(paymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        toastification.show(
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          title: Text('Error'),
          description: Text('Tidak dapat membuka tautan pembayaran.'),
          autoCloseDuration: const Duration(seconds: 2),
          alignment: Alignment.topCenter,
        );
      }
    } catch (e) {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: Text('Error'),
        description: Text('Terjadi kesalahan saat membuka tautan pembayaran.'),
        autoCloseDuration: const Duration(seconds: 2),
        alignment: Alignment.topCenter,
      );
    }
  }
}
