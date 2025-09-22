import 'package:flutter/material.dart';

class CartItem {
  final int productId;
  final String name;
  final String image;
  final int price;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
  });
}

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

  // Dummy cart items
  List<CartItem> _cartItems = [
    CartItem(
      productId: 1,
      name: "Cappuccino",
      image: "images/cappuccino.jpg",
      price: 25000,
      quantity: 2,
    ),
    CartItem(
      productId: 2,
      name: "Croissant",
      image: "images/croissant.jpg",
      price: 22000,
      quantity: 1,
    ),
    CartItem(
      productId: 3,
      name: "Cheesecake",
      image: "images/cheesecake.jpg",
      price: 40000,
      quantity: 1,
    ),
  ];

  @override
  void dispose() {
    _tableNumberController.dispose();
    super.dispose();
  }

  void _updateQuantity(int productId, int newQuantity) {
    setState(() {
      final index = _cartItems.indexWhere(
        (item) => item.productId == productId,
      );
      if (index != -1) {
        if (newQuantity <= 0) {
          _cartItems.removeAt(index);
          _showSuccessSnackBar('Item removed from cart');
        } else {
          _cartItems[index].quantity = newQuantity;
        }
      }
    });
  }

  void _removeItem(int productId) {
    setState(() {
      _cartItems.removeWhere((item) => item.productId == productId);
    });
    _showSuccessSnackBar('Item removed from cart');
  }

  Future<void> _processOrder() async {
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

    setState(() {
      _isProcessingOrder = true;
    });

    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isProcessingOrder = false;
    });

    // Show success dialog
    _showOrderSuccessDialog();
  }

  void _showOrderSuccessDialog() {
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
            Text(
              'Order ID: #${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
            ),
            Text('Table: ${_tableNumberController.text}'),
            Text('Payment Method: $_selectedPaymentMethod'),
            Text('Total: Rp ${_formatCurrency(cartSummary['total'] ?? 0)}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _clearCart();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _tableNumberController.clear();
    });
    _showSuccessSnackBar('Cart cleared');
  }

  Map<String, int> _getCartSummary() {
    final subtotal = _cartItems.fold<int>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );

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
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    final cartSummary = _getCartSummary();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Cart Items List
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return _buildCartItemCard(item);
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
                _buildSummaryRow('Total Belanja', cartSummary['subtotal'] ?? 0),
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
    );
  }

  Widget _buildCartItemCard(CartItem item) {
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
              child: Image.asset(
                item.image,
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
              ),
            ),
            const SizedBox(width: 12),
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${_formatCurrency(item.price)}',
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
                          _updateQuantity(item.productId, item.quantity - 1),
                      icon: const Icon(Icons.remove),
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      onPressed: () =>
                          _updateQuantity(item.productId, item.quantity + 1),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                // Delete Button
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(item.productId),
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
