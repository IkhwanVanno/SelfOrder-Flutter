import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:selforder/controllers/auth_controller.dart';
import 'package:selforder/controllers/cart_controller.dart';
import 'package:selforder/controllers/product_controller.dart';
import 'package:selforder/models/cartitem_model.dart';
import 'package:selforder/models/order_model.dart';
import 'package:selforder/models/product_model.dart';
import 'package:selforder/models/paymentmethod_model.dart';
import 'package:selforder/routes/app_routes.dart';
import 'package:selforder/theme/app_theme.dart';
import 'package:toastification/toastification.dart';
import 'package:url_launcher/url_launcher.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final cartController = Get.find<CartController>();

    return Scaffold(
      body: Obx(() {
        if (!authController.isLoggedIn) {
          return _buildNotLoggedInView();
        }

        if (cartController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (cartController.cartItems.isEmpty) {
          return _buildEmptyCart(cartController);
        }

        return _buildCartContent(cartController);
      }),
    );
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 80, color: AppColors.grey),
          const SizedBox(height: 16),
          Text(
            'Silahkan masuk untuk melihat keranjang anda',
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

  Widget _buildEmptyCart(CartController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 100, color: AppColors.grey),
          const SizedBox(height: 16),
          Text(
            'Keranjang anda kosong',
            style: TextStyle(fontSize: 18, color: AppColors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan Item untuk memulai',
            style: TextStyle(fontSize: 14, color: AppColors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => controller.refresh(),
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(CartController cartController) {
    final tableNumberController = TextEditingController();
    final productController = Get.find<ProductController>();

    return RefreshIndicator(
      onRefresh: () => cartController.refresh(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Cart Items List
            Expanded(
              child: Obx(
                () => ListView.builder(
                  itemCount: cartController.cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartController.cartItems[index];
                    final product = productController.getProductById(
                      item.productId,
                    );
                    return _buildCartItemCard(item, product, cartController);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Table Number
            TextField(
              controller: tableNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nomor Meja',
                border: OutlineInputBorder(),
                hintText: 'Masukkan nomor meja',
              ),
            ),

            const SizedBox(height: 16),

            // Payment Method Dropdown
            Obx(
              () => Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: cartController.isLoadingPayment
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Memuat metode pembayaran...'),
                        ],
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<PaymentMethod>(
                          isExpanded: true,
                          value: cartController.selectedPaymentMethod,
                          hint: const Text('Pilih Metode Pembayaran'),
                          items: cartController.paymentMethods.map((method) {
                            return DropdownMenuItem<PaymentMethod>(
                              value: method,
                              child: Row(
                                children: [
                                  if (method.paymentImage.isNotEmpty)
                                    Image.network(
                                      method.paymentImage,
                                      width: 24,
                                      height: 24,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.payment,
                                              size: 24,
                                            );
                                          },
                                    )
                                  else
                                    const Icon(Icons.payment, size: 24),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(method.paymentName)),
                                  if (method.totalFee > 0)
                                    Text(
                                      '+Rp ${_formatCurrency(method.totalFee)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.orange,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (method) {
                            cartController.selectPaymentMethod(method);
                          },
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // Payment Summary
            Obx(
              () => Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.grey.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.grey),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Total Belanja',
                      cartController.calculateSubtotal(),
                    ),
                    if (cartController.calculatePaymentFee() > 0) ...[
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Biaya Admin',
                        cartController.calculatePaymentFee(),
                        color: AppColors.orange,
                      ),
                    ],
                    const Divider(height: 24, thickness: 1),
                    _buildSummaryRow(
                      'Total Pembayaran',
                      cartController.calculateTotal(),
                      bold: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Process Order Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () =>
                    _processOrder(tableNumberController.text, cartController),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Buat Pesanan & Bayar",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(
    CartItem item,
    Product? product,
    CartController controller,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product?.imageURL != null && product!.imageURL.isNotEmpty
                  ? (product.imageURL.startsWith('http')
                        ? Image.network(
                            product.imageURL,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 70,
                                height: 70,
                                color: AppColors.grey,
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          )
                        : Image.asset(
                            product.imageURL,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 70,
                                height: 70,
                                color: AppColors.grey,
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ))
                  : Container(
                      width: 70,
                      height: 70,
                      color: AppColors.grey,
                      child: const Icon(Icons.image_not_supported),
                    ),
            ),
            const SizedBox(width: 12),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product?.name ?? 'Produk tidak diketahui',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatCurrency(product?.price ?? 0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subtotal: Rp ${_formatCurrency((product?.price ?? 0) * item.quantity)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                // Quantity Controls
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => controller.updateQuantity(
                          item.id,
                          item.quantity - 1,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.remove, size: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      InkWell(
                        onTap: () => controller.updateQuantity(
                          item.id,
                          item.quantity + 1,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.add, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Delete Button
                InkWell(
                  onTap: () => controller.removeFromCart(item.id),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.red.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.red),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: AppColors.red,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String title,
    int value, {
    bool bold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            fontSize: bold ? 16 : 14,
          ),
        ),
        Text(
          'Rp ${_formatCurrency(value)}',
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            fontSize: bold ? 16 : 14,
            color: color ?? (bold ? Colors.green : AppColors.black),
          ),
        ),
      ],
    );
  }

  Future<void> _processOrder(
    String tableNumber,
    CartController controller,
  ) async {
    if (tableNumber.trim().isEmpty) {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: Text('Error'),
        description: Text('Silahkan masukkan nomor meja'),
        autoCloseDuration: const Duration(seconds: 2),
        alignment: Alignment.topCenter,
      );
      return;
    }

    if (controller.selectedPaymentMethod == null) {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: Text('Error'),
        description: Text('Silahkan pilih metode pembayaran'),
        autoCloseDuration: const Duration(seconds: 2),
        alignment: Alignment.topCenter,
      );
      return;
    }

    if (controller.cartItems.isEmpty) {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: Text('Error'),
        description: Text('Keranjang anda kosong'),
        autoCloseDuration: const Duration(seconds: 2),
        alignment: Alignment.topCenter,
      );
      return;
    }

    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );

    try {
      final order = await controller.createOrder(tableNumber.trim());
      Get.back(); // Close loading dialog

      _showPaymentDialog(order);
    } catch (e) {
      Get.back(); // Close loading dialog
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        title: Text('Error'),
        description: Text('Gagal membuat pesanan: ${e.toString()}'),
        autoCloseDuration: const Duration(seconds: 3),
        alignment: Alignment.topCenter,
      );
    }
  }

  void _showPaymentDialog(Order order) {
    final paymentUrl = order.payment?.paymentUrl ?? '';

    Get.dialog(
      AlertDialog(
        title: const Text('Pesanan Berhasil Dibuat!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pesanan Anda telah berhasil dibuat.'),
            const SizedBox(height: 16),
            Text('Invoice: ${order.nomorInvoice}'),
            Text('Total: Rp ${_formatCurrency(order.totalHarga.toInt())}'),
            Text('Meja: ${order.nomorMeja}'),
            if (order.payment != null)
              Text('Pembayaran: ${order.payment!.metodePembayaran}'),
            const SizedBox(height: 16),
            const Text(
              'Anda akan diarahkan ke halaman pembayaran Duitku.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Nanti')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              if (paymentUrl.isNotEmpty) {
                _openPaymentUrl(paymentUrl);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Bayar Sekarang'),
          ),
        ],
      ),
      barrierDismissible: false,
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

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
