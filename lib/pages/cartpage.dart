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
  String? _selectedPaymentMethod = 'Credit Card';
  final List<String> _paymentMethods = [
    'Credit Card',
    'Debit Card',
    'Digital Wallet',
    'Bank Transfer',
    'Cash',
  ];

  bool _isProcessingOrder = false;
  bool _isLoading = true;
  List<CartItem> _cartItems = [];
  Map<int, Product> _productCache = {};

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    super.dispose();
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

      // Cache products for easy lookup
      _productCache.clear();
      for (final product in products) {
        _productCache[product.id] = product;
      }

      setState(() {
        _cartItems = cartItems;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load cart: ${e.toString()}');
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
      await _loadCartItems(); // Refresh cart
      _showSuccessSnackBar('Cart updated');
    } catch (e) {
      _showErrorSnackBar('Failed to update cart: ${e.toString()}');
    }
  }

  Future<void> _removeItem(int cartItemId) async {
    try {
      await ApiService.removeFromCart(cartItemId);
      await _loadCartItems(); // Refresh cart
      _showSuccessSnackBar('Item removed from cart');
    } catch (e) {
      _showErrorSnackBar('Failed to remove item: ${e.toString()}');
    }
  }

  Future<void> _processOrder() async {
    if (!AuthService.isLoggedIn) {
      _showErrorSnackBar('Please login to place an order');
      return;
    }

    if (_tableNumberController.text.isEmpty) {
      _showErrorSnackBar('Please enter table number');
      return;
    }

    if (_cartItems.isEmpty) {
      _showErrorSnackBar('Cart is empty');
      return;
    }

    if (_selectedPaymentMethod == null) {
      _showErrorSnackBar('Please select payment method');
      return;
    }

    setState(() => _isProcessingOrder = true);

    try {
      // Prepare order items
      final orderItems = _cartItems.map((cartItem) {
        final product = _productCache[cartItem.productId];
        return {
          'ProductID': cartItem.productId,
          'Kuantitas': cartItem.quantity,
          'HargaSatuan': product?.price ?? 0,
        };
      }).toList();

      // Create order
      final order = await ApiService.createOrder(
        tableNumber: _tableNumberController.text,
        paymentMethod: _selectedPaymentMethod!,
        items: orderItems,
      );

      // Clear cart after successful order
      await ApiService.clearCart();

      setState(() => _isProcessingOrder = false);

      // Show success dialog
      _showOrderSuccessDialog(order.id, order.nomorInvoice);
    } catch (e) {
      setState(() => _isProcessingOrder = false);
      _showErrorSnackBar('Failed to create order: ${e.toString()}');
    }
  }

  void _showOrderSuccessDialog(int orderId, String invoiceNumber) {
    final cartSummary = _getCartSummary();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Order Placed Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your order has been placed successfully.'),
            const SizedBox(height: 16),
            Text('Order ID: #$orderId'),
            Text('Invoice: $invoiceNumber'),
            Text('Table: ${_tableNumberController.text}'),
            Text('Payment Method: $_selectedPaymentMethod'),
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
    _showSuccessSnackBar('Order completed successfully');
  }

  Map<String, int> _getCartSummary() {
    final subtotal = _cartItems.fold<int>(0, (sum, item) {
      final product = _productCache[item.productId];
      return sum + ((product?.price ?? 0) * item.quantity);
    });

    const adminFee = 2500;
    final paymentFee = _getPaymentFee();
    final total = subtotal + adminFee + paymentFee;

    return {
      'subtotal': subtotal,
      'adminFee': adminFee,
      'paymentFee': paymentFee,
      'total': total,
    };
  }

  int _getPaymentFee() {
    switch (_selectedPaymentMethod) {
      case 'Credit Card':
        return 2000;
      case 'Digital Wallet':
        return 1500;
      case 'Bank Transfer':
        return 3000;
      default:
        return 0;
    }
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
                'Please login to view your cart',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Login'),
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
            'Your cart is empty',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some items to get started',
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
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nomor Meja',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // Payment Method
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Metode Pembayaran',
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value;
                });
              },
              items: _paymentMethods.map((method) {
                return DropdownMenuItem(value: method, child: Text(method));
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Payment Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Total Belanja',
                    cartSummary['subtotal'] ?? 0,
                  ),
                  const SizedBox(height: 4),
                  _buildSummaryRow('Biaya Admin', cartSummary['adminFee'] ?? 0),
                  const SizedBox(height: 4),
                  _buildSummaryRow(
                    'Biaya Payment',
                    cartSummary['paymentFee'] ?? 0,
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
              child: ElevatedButton(
                onPressed: _isProcessingOrder ? null : _processOrder,
                child: _isProcessingOrder
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text("Processing..."),
                        ],
                      )
                    : const Text("Lanjut Pembayaran"),
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
      child: Padding(
        padding: const EdgeInsets.all(8),
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
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          )
                        : Image.asset(
                            product.imageURL,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ))
                  : Container(
                      width: 60,
                      height: 60,
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
                    product?.name ?? 'Unknown Product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatCurrency(product?.price ?? 0)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Quantity Controls and Delete
            Row(
              children: [
                // Quantity Controls
                Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          _updateQuantity(item.id, item.quantity - 1),
                      icon: const Icon(Icons.remove),
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      onPressed: () =>
                          _updateQuantity(item.id, item.quantity + 1),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                // Delete Button
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(item.id),
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
          ),
        ),
        Text(
          'Rp ${_formatCurrency(value)}',
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? Colors.green : null,
          ),
        ),
      ],
    );
  }
}
