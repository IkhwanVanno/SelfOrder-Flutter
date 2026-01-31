import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:selforder/controllers/order_controller.dart';
import 'package:selforder/models/cartitem_model.dart';
import 'package:selforder/models/order_model.dart';
import 'package:selforder/models/paymentmethod_model.dart';
import 'package:selforder/services/api_service.dart';
import 'package:selforder/controllers/auth_controller.dart';
import 'package:selforder/controllers/product_controller.dart';
import 'package:toastification/toastification.dart';

class CartController extends GetxController {
  final _cartItems = <CartItem>[].obs;
  final _paymentMethods = <PaymentMethod>[].obs;
  final _selectedPaymentMethod = Rx<PaymentMethod?>(null);
  final _isLoading = false.obs;
  final _isLoadingPayment = false.obs;

  // Debounce timer untuk setiap product
  final Map<int, Timer?> _debounceTimers = {};
  final Map<int, int> _pendingQuantities = {};

  List<CartItem> get cartItems => _cartItems;
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod.value;
  bool get isLoading => _isLoading.value;
  bool get isLoadingPayment => _isLoadingPayment.value;

  int get totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  AuthController get _authController => Get.find<AuthController>();
  ProductController get _productController => Get.find<ProductController>();

  @override
  void onClose() {
    _debounceTimers.forEach((key, timer) {
      timer?.cancel();
    });
    _debounceTimers.clear();
    super.onClose();
  }

  Future<void> loadCartItems() async {
    if (!_authController.isLoggedIn) {
      _cartItems.clear();
      return;
    }

    _isLoading.value = true;
    try {
      final items = await ApiService.fetchCartItems();

      if (items.isNotEmpty) {
        final productIds = items.map((e) => e.productId).toList();
        print('Loading ${productIds.length} products for cart items...');
        await _productController.preloadProductsByIds(productIds);
        print('Products loaded successfully');
      }

      _cartItems.value = items;

      if (_cartItems.isNotEmpty) {
        await loadPaymentMethods();
      }
    } catch (e) {
      print('Failed to load cart: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadPaymentMethods() async {
    final total = calculateTotal();
    if (total <= 0) return;

    _isLoadingPayment.value = true;
    try {
      final methods = await ApiService.fetchPaymentMethods(total);
      _paymentMethods.value = methods;
    } catch (e) {
      print('Failed to load payment methods: $e');
    } finally {
      _isLoadingPayment.value = false;
    }
  }

  Future<void> addToCart(int productId, int quantity) async {
    if (!_authController.isLoggedIn) {
      _productController.updateGuestCart(productId, quantity);
      toastification.show(
        title: const Text('Perhatian'),
        description: const Text('Silakan login untuk menambahkan ke keranjang'),
        type: ToastificationType.warning,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: const Duration(seconds: 2),
      );
      return;
    }

    await _productController.fetchAndCacheProduct(productId);

    try {
      _pendingQuantities[productId] =
          (_pendingQuantities[productId] ?? 0) + quantity;

      // Jalankan debounce
      _debounceApiCall(productId, () async {
        final qtyToSend = _pendingQuantities[productId] ?? quantity;
        _pendingQuantities.remove(productId);

        try {
          final serverCartItem = await ApiService.addToCart(
            productId,
            qtyToSend,
          );

          // Update dengan data dari server
          final currentIndex = _cartItems.indexWhere(
            (item) => item.productId == productId,
          );

          if (currentIndex >= 0) {
            _cartItems[currentIndex] = serverCartItem;
          } else {
            _cartItems.add(serverCartItem);
          }

          // Pastikan produk tetap di cache
          await _productController.fetchAndCacheProduct(productId);

          if (_paymentMethods.isEmpty) {
            await loadPaymentMethods();
          }

          final product = _productController.getProductById(productId);
          toastification.show(
            title: const Text('Berhasil'),
            description: Text(
              '${product?.name ?? 'Produk'} ditambahkan ke keranjang',
            ),
            type: ToastificationType.success,
            style: ToastificationStyle.flatColored,
            autoCloseDuration: const Duration(seconds: 2),
          );
        } catch (e) {
          print('API Error: $e');

          // Reload cart dari server jika gagal
          await loadCartItems();

          toastification.show(
            title: const Text('Error'),
            description: const Text('Gagal menambahkan ke keranjang'),
            type: ToastificationType.error,
            style: ToastificationStyle.flatColored,
            autoCloseDuration: const Duration(seconds: 2),
          );
        }
      });
    } catch (e) {
      print('Add to cart error: $e');
    }
  }

  Future<void> updateQuantity(int cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }

    try {
      final index = _cartItems.indexWhere((item) => item.id == cartItemId);
      if (index < 0) return;

      final item = _cartItems[index];
      final oldQuantity = item.quantity;

      // Pastikan produk ada di cache sebelum update
      await _productController.fetchAndCacheProduct(item.productId);

      // Optimistic update
      _cartItems[index] = item.copyWith(quantity: newQuantity);

      // Debounce API call
      _debounceApiCall(item.productId, () async {
        try {
          final serverCartItem = await ApiService.updateCartItem(
            cartItemId,
            newQuantity,
          );

          final currentIndex = _cartItems.indexWhere(
            (item) => item.id == cartItemId,
          );

          if (currentIndex >= 0) {
            _cartItems[currentIndex] = serverCartItem;
          }

          // Refresh cache produk
          await _productController.fetchAndCacheProduct(item.productId);
        } catch (e) {
          print('Update cart error: $e');

          // Rollback
          final rollbackIndex = _cartItems.indexWhere(
            (item) => item.id == cartItemId,
          );

          if (rollbackIndex >= 0) {
            _cartItems[rollbackIndex] = item.copyWith(quantity: oldQuantity);
          }

          toastification.show(
            title: const Text('Error'),
            description: const Text('Gagal memperbarui jumlah item'),
            type: ToastificationType.error,
            style: ToastificationStyle.flatColored,
            autoCloseDuration: const Duration(seconds: 2),
          );
        }
      });
    } catch (e) {
      print('Update quantity error: $e');
    }
  }

  Future<void> removeFromCart(int cartItemId) async {
    try {
      final itemIndex = _cartItems.indexWhere((item) => item.id == cartItemId);
      if (itemIndex < 0) return;

      final removedItem = _cartItems[itemIndex];
      _cartItems.removeAt(itemIndex);

      try {
        await ApiService.removeFromCart(cartItemId);

        toastification.show(
          title: const Text('Berhasil'),
          description: const Text('Item dihapus dari keranjang'),
          type: ToastificationType.success,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 2),
        );
      } catch (e) {
        print('Remove from cart error: $e');

        // Rollback
        _cartItems.insert(itemIndex, removedItem);

        toastification.show(
          title: const Text('Error'),
          description: const Text('Gagal menghapus item dari keranjang'),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print('Remove error: $e');
    }
  }

  void _debounceApiCall(int productId, Function() callback) {
    if (_debounceTimers[productId] != null) {
      _debounceTimers[productId]!.cancel();
    }

    _debounceTimers[productId] = Timer(const Duration(milliseconds: 600), () {
      callback();
      _debounceTimers.remove(productId);
    });
  }

  void selectPaymentMethod(PaymentMethod? method) {
    _selectedPaymentMethod.value = method;
  }

  int getCartQuantity(int productId) {
    final item = _cartItems.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(id: 0, quantity: 0, productId: productId),
    );
    return item.quantity;
  }

  int calculateSubtotal() {
    return _cartItems.fold(0, (sum, item) {
      final product = _productController.getProductById(item.productId);
      if (product == null) {
        print(
          'WARNING: Product ${item.productId} not found in calculateSubtotal',
        );
        return sum;
      }
      return sum + ((product.price) * item.quantity);
    });
  }

  int calculatePaymentFee() {
    return _selectedPaymentMethod.value?.totalFee ?? 0;
  }

  int calculateTotal() {
    return calculateSubtotal() + calculatePaymentFee();
  }

  Future<Order> createOrder(String tableNumber) async {
    if (!_authController.isLoggedIn) {
      throw Exception('Please login first');
    }

    if (_selectedPaymentMethod.value == null) {
      throw Exception('Please select payment method');
    }

    try {
      final order = await ApiService.createOrderWithPayment(
        tableNumber: tableNumber,
        paymentMethod: _selectedPaymentMethod.value!.paymentMethod,
      );

      _cartItems.clear();
      _selectedPaymentMethod.value = null;
      _paymentMethods.clear();

      await Get.find<OrderController>().refresh();

      return order;
    } catch (e) {
      print('Create order error: $e');
      rethrow;
    }
  }

  void clearCart() {
    _cartItems.clear();
    _paymentMethods.clear();
    _selectedPaymentMethod.value = null;
  }

  // Enhanced refresh
  Future<void> refresh() async {
    print('Refreshing cart...');
    await loadCartItems();
  }
}
