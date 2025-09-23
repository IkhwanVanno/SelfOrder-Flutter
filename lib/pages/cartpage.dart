import 'package:flutter/material.dart';
import 'package:selforder/models/cartitem_model.dart';
import 'package:selforder/models/product_model.dart';
import 'package:selforder/services/api_service.dart';
import 'package:selforder/services/auth_service.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final TextEditingController _tableNumberController = TextEditingController();

  bool _isProcessingOrder = false;
  bool _isLoading = true;
  List<CartItem> _cartItems = [];
  Map<int, Product> _productCache = {};

  late Function() _authListener;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _loadCartItems();
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    AuthService.removeAuthStateListener(_authListener);
    super.dispose();
  }

  void _setupAuthListener() {
    _authListener = () {
      if (mounted) {
        setState(() {});
        _loadCartItems();
      }
    };
    AuthService.addAuthStateListener(_authListener);
  }

  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);

    try {
      if (!AuthService.isLoggedIn) {
        setState(() {
          _cartItems = [];
          _isLoading = false;
        });
        return;
      }

      final cartItems = await ApiService.fetchCartItems();
      final products = await ApiService.fetchProducts();

      _productCache.clear();
      for (final product in products) {
        _productCache[product.id] = product;
      }

      setState(() {
        _cartItems = cartItems;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('Gagal memuat keranjang: ${e.toString()}');
      setState(() => _isLoading = false);
    }
  }

  void _updateQuantity(int cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItem(cartItemId);
      return;
    }

    try {
      await ApiService.updateCartItem(cartItemId, newQuantity);
      await _loadCartItems();
      _showSuccessSnackBar('Cart diperbarui');
    } catch (e) {
      _showErrorSnackBar('Gagal memperbarui keranjang: ${e.toString()}');
    }
  }

  Future<void> _removeItem(int cartItemId) async {
    try {
      await ApiService.removeFromCart(cartItemId);
      await _loadCartItems();
      _showSuccessSnackBar('Item telah dihapus dari keranjang');
    } catch (e) {
      _showErrorSnackBar('Gagal menghapus: ${e.toString()}');
    }
  }

  Future<void> _processOrder() async {
    if (!AuthService.isLoggedIn) {
      _showErrorSnackBar('Silahkan Masuk terlebih dahulu');
      return;
    }

    if (_tableNumberController.text.trim().isEmpty) {
      _showErrorSnackBar('Silahkan masukkan nomor meja');
      return;
    }

    if (_cartItems.isEmpty) {
      _showErrorSnackBar('Kerajang kosong');
      return;
    }

    setState(() => _isProcessingOrder = true);

    try {
      final orderItems = _cartItems.map((cartItem) {
        final product = _productCache[cartItem.productId];
        return {
          'ProductID': cartItem.productId,
          'Kuantitas': cartItem.quantity,
          'HargaSatuan': product?.price ?? 0,
        };
      }).toList();

      final order = await ApiService.createOrder(
        tableNumber: _tableNumberController.text.trim(),
        paymentMethod: 'Cash',
        items: orderItems,
      );

      await ApiService.clearCart();

      setState(() => _isProcessingOrder = false);

      _showOrderSuccessDialog(order.id, order.nomorInvoice);
    } catch (e) {
      setState(() => _isProcessingOrder = false);
      _showErrorSnackBar('Gagal membuat pesanan: ${e.toString()}');
    }
  }

  void _showOrderSuccessDialog(int orderId, String invoiceNumber) {
    final cartSummary = _getCartSummary();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Pesanan telah berhasil dipesan.!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pesanan Anda telah berhasil diproses.'),
            const SizedBox(height: 16),
            Text('Order ID: #$orderId'),
            Text('Invoice: $invoiceNumber'),
            Text('Table: ${_tableNumberController.text}'),
            Text('Total: Rp ${_formatCurrency(cartSummary['total'] ?? 0)}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearCartUI();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearCartUI() {
    setState(() {
      _cartItems.clear();
      _tableNumberController.clear();
    });
    _showSuccessSnackBar('Pesanan telah selesai dengan sukses');
  }

  Map<String, int> _getCartSummary() {
    final subtotal = _cartItems.fold<int>(0, (sum, item) {
      final product = _productCache[item.productId];
      return sum + ((product?.price ?? 0) * item.quantity);
    });

    const paymentFee = 0;
    final total = subtotal + paymentFee;

    return {'subtotal': subtotal, 'paymentFee': paymentFee, 'total': total};
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _navigateToLogin() {
    Navigator.pushNamed(context, '/login').then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!AuthService.isLoggedIn) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Silahkan masuk untuk melihat keranjang anda',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _navigateToLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Masuk'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _cartItems.isEmpty ? _buildEmptyCart() : _buildCartContent(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Keranjang anda kosong',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan Item untuk memulai',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadCartItems,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    final cartSummary = _getCartSummary();

    return RefreshIndicator(
      onRefresh: _loadCartItems,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Cart Items List
            Expanded(
              child: ListView.builder(
                itemCount: _cartItems.length,
                itemBuilder: (context, index) {
                  final item = _cartItems[index];
                  final product = _productCache[item.productId];
                  return _buildCartItemCard(item, product);
                },
              ),
            ),

            const SizedBox(height: 12),

            // Table Number
            TextField(
              controller: _tableNumberController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Nomor Meja',
                border: OutlineInputBorder(),
                hintText: 'Masukkan nomor meja',
              ),
            ),

            const SizedBox(height: 20),

            // Payment Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Total Belanja',
                    cartSummary['subtotal'] ?? 0,
                  ),
                  const Divider(height: 24, thickness: 1),
                  _buildSummaryRow(
                    'Total Pembayaran',
                    cartSummary['total'] ?? 0,
                    bold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Process Order Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessingOrder ? null : _processOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessingOrder
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text("Memproses..."),
                        ],
                      )
                    : const Text(
                        "Melakukan pesanan",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item, Product? product) {
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
                                color: Colors.grey[300],
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
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ))
                  : Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[300],
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
                      color: Colors.green,
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
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () =>
                            _updateQuantity(item.id, item.quantity - 1),
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
                        onTap: () =>
                            _updateQuantity(item.id, item.quantity + 1),
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
                  onTap: () => _removeItem(item.id),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.red,
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

  Widget _buildSummaryRow(String title, int value, {bool bold = false}) {
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
            color: bold ? Colors.green : Colors.green[700],
          ),
        ),
      ],
    );
  }
}
