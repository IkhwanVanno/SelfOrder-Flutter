import 'package:flutter/material.dart';
import 'package:selforder/models/cart_item.dart';
import 'package:selforder/services/api_service.dart';
import 'package:selforder/services/cart_service.dart';
import 'package:selforder/services/duitku_service.dart';
import 'package:selforder/widgets/summary_row.dart';
import 'package:url_launcher/url_launcher.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();
  final DuitkuService _duitkuService = DuitkuService();
  final ApiService _apiService = ApiService();

  final TextEditingController _tableNumberController = TextEditingController();
  DuitkuPaymentMethod? _selectedPaymentMethod;
  List<DuitkuPaymentMethod> _duitkuPaymentMethods = [];
  bool _isLoadingPaymentMethods = false;
  bool _isProcessingOrder = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentMethods() async {
    if (_cartService.isEmpty) return;

    setState(() {
      _isLoadingPaymentMethods = true;
    });

    try {
      final cartSummary = _cartService.getCartSummary();
      final totalAmount = cartSummary['total'] as int;

      final response = await _duitkuService.getPaymentMethods(amount: totalAmount);
      
      if (response.success && response.data != null && response.data!.isNotEmpty) {
        setState(() {
          _duitkuPaymentMethods = response.data!;
          _selectedPaymentMethod = _duitkuPaymentMethods.first;
        });
      } else {
        _showErrorSnackBar('Failed to load payment methods: ${response.error}');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading payment methods: $e');
    } finally {
      setState(() {
        _isLoadingPaymentMethods = false;
      });
    }
  }

  Future<void> _updateQuantity(int productId, int newQuantity) async {
    final response = await _cartService.updateQuantity(
      productId: productId,
      quantity: newQuantity,
    );

    if (!response.success) {
      _showErrorSnackBar(response.error ?? 'Failed to update quantity');
    }

    // Reload payment methods if cart total changed
    _loadPaymentMethods();
    setState(() {});
  }

  Future<void> _removeItem(int productId) async {
    final response = await _cartService.removeFromCart(productId);

    if (response.success) {
      _showSuccessSnackBar('Item removed from cart');
      // Reload payment methods if cart total changed
      _loadPaymentMethods();
    } else {
      _showErrorSnackBar(response.error ?? 'Failed to remove item');
    }

    setState(() {});
  }

  Future<void> _processOrder() async {
    // Validate form
    if (_tableNumberController.text.isEmpty) {
      _showErrorSnackBar('Please enter table number');
      return;
    }

    if (_cartService.isEmpty) {
      _showErrorSnackBar('Cart is empty');
      return;
    }

    if (!_apiService.isAuthenticated) {
      _showErrorSnackBar('Please login to place order');
      return;
    }

    if (_selectedPaymentMethod == null) {
      _showErrorSnackBar('Please select payment method');
      return;
    }

    setState(() {
      _isProcessingOrder = true;
    });

    try {
      final tableNumber = int.tryParse(_tableNumberController.text);
      if (tableNumber == null || tableNumber <= 0) {
        _showErrorSnackBar('Please enter a valid table number');
        setState(() {
          _isProcessingOrder = false;
        });
        return;
      }

      // Create order
      final orderResponse = await _cartService.createOrder(
        tableNumber: tableNumber,
        paymentMethod: _selectedPaymentMethod!.paymentName,
      );

      if (!orderResponse.success) {
        _showErrorSnackBar(orderResponse.error ?? 'Failed to create order');
        setState(() {
          _isProcessingOrder = false;
        });
        return;
      }

      final orderData = orderResponse.data!;

      // Process Duitku payment
      await _processDuitkuPayment(orderData);
    } catch (e) {
      _showErrorSnackBar('Failed to process order: $e');
    } finally {
      setState(() {
        _isProcessingOrder = false;
      });
    }
  }

  Future<void> _processDuitkuPayment(Map<String, dynamic> orderData) async {
    try {
      final currentUser = _apiService.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('User information not available');
        return;
      }

      final cartSummary = _cartService.getCartSummary();
      final totalAmount = cartSummary['total'] as int;

      final transactionResponse = await _duitkuService.createTransaction(
        paymentMethod: _selectedPaymentMethod!.paymentMethod,
        paymentAmount: totalAmount,
        customerName: '${currentUser['FirstName']} ${currentUser['Surname']}',
        email: currentUser['Email'] ?? '',
        phoneNumber: currentUser['Phone'] ?? '08123456789',
        productDetails: 'Order from SelfOrder Cafe',
        orderData: orderData,
      );

      if (transactionResponse.success && transactionResponse.data != null) {
        final transaction = transactionResponse.data!;
        
        if (transaction.paymentUrl != null) {
          // Open payment URL
          final uri = Uri.parse(transaction.paymentUrl!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            _showPaymentSuccessDialog(orderData);
          } else {
            _showErrorSnackBar('Cannot open payment URL');
          }
        } else if (transaction.vaNumber != null) {
          // Show VA number for bank transfer
          _showVANumberDialog(transaction, orderData);
        } else {
          _showPaymentSuccessDialog(orderData);
        }
      } else {
        _showErrorSnackBar(transactionResponse.error ?? 'Payment failed');
      }
    } catch (e) {
      _showErrorSnackBar('Payment processing failed: $e');
    }
  }

  void _showPaymentSuccessDialog(Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Order Created Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your order has been placed and payment is being processed.'),
            const SizedBox(height: 16),
            Text('Order ID: ${orderData['ID']}'),
            Text('Table: ${_tableNumberController.text}'),
            Text('Payment Method: ${_selectedPaymentMethod?.paymentName ?? 'N/A'}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Clear cart and navigate to home or orders page
              _cartService.clearCart();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showVANumberDialog(DuitkuTransactionResponse transaction, Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Virtual Account Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please transfer to the following Virtual Account:'),
            const SizedBox(height: 16),
            Text('Bank: ${_selectedPaymentMethod?.paymentName ?? 'N/A'}'),
            if (transaction.vaNumber != null)
              Text('VA Number: ${transaction.vaNumber}'),
            Text('Amount: Rp ${transaction.amount?.toString() ?? '0'}'),
            const SizedBox(height: 16),
            const Text('Payment will be verified automatically.'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cartService.clearCart();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _cartService.isEmpty
          ? _buildEmptyCart()
          : _buildCartContent(),
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
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some items to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    final cartSummary = _cartService.getCartSummary();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Cart Items List
          Expanded(
            child: ListView.builder(
              itemCount: _cartService.cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartService.cartItems[index];
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
          _buildPaymentMethodDropdown(),

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
                SummaryRow(
                  title: 'Total Belanja',
                  value: cartSummary['subtotal'],
                ),
                const SizedBox(height: 4),
                SummaryRow(
                  title: 'Biaya Admin',
                  value: cartSummary['adminFee'],
                ),
                if (_selectedPaymentMethod != null && _selectedPaymentMethod!.totalFee > 0)
                  Column(
                    children: [
                      const SizedBox(height: 4),
                      SummaryRow(
                        title: 'Biaya Payment',
                        value: _selectedPaymentMethod!.totalFee,
                      ),
                    ],
                  ),
                const Divider(height: 24, thickness: 1),
                SummaryRow(
                  title: 'Total Pembayaran',
                  value: cartSummary['total'] + (_selectedPaymentMethod?.totalFee ?? 0),
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
              onPressed: (_isProcessingOrder || _selectedPaymentMethod == null) 
                  ? null 
                  : _processOrder,
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
              child: Image.network(
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
                    'Rp ${item.price}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
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
                      onPressed: () => _updateQuantity(
                        item.productId,
                        item.quantity - 1,
                      ),
                      icon: const Icon(Icons.remove),
                    ),
                    Text('${item.quantity}'),
                    IconButton(
                      onPressed: () => _updateQuantity(
                        item.productId,
                        item.quantity + 1,
                      ),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                // Delete Button
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () => _removeItem(item.productId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<DuitkuPaymentMethod>(
      decoration: const InputDecoration(
        labelText: 'Metode Pembayaran',
        border: OutlineInputBorder(),
      ),
      isExpanded: true,
      isDense: true,
      initialValue: _selectedPaymentMethod,
      onChanged: _isLoadingPaymentMethods ? null : (value) {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      items: _duitkuPaymentMethods.map((method) {
        return DropdownMenuItem(
          value: method,
          child: Container(
            width: double.infinity,
            child: Text(
              method.paymentName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        );
      }).toList(),
      hint: _isLoadingPaymentMethods 
          ? const Text('Loading payment methods...') 
          : const Text('Select payment method'),
    );
  }
}