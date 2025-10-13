import 'dart:async';

import 'package:get/get.dart';
import 'package:selforder/controllers/order_controller.dart';
import 'package:selforder/models/cartitem_model.dart';
import 'package:selforder/models/paymentmethod_model.dart';
import 'package:selforder/services/api_service.dart';
import 'package:selforder/controllers/auth_controller.dart';
import 'package:selforder/controllers/product_controller.dart';
import 'package:selforder/theme/app_theme.dart';

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
      Get.snackbar(
        'Info',
        'Silahkan masuk terlebih dahulu',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.orange,
        colorText: AppColors.white,
      );
      return;
    }

    try {
      // Optimistic update
      final existingIndex = _cartItems.indexWhere(
        (item) => item.productId == productId,
      );
      int tempId = DateTime.now().millisecondsSinceEpoch;

      if (existingIndex >= 0) {
        final item = _cartItems[existingIndex];
        final newQuantity = item.quantity + quantity;
        _cartItems[existingIndex] = item.copyWith(quantity: newQuantity);
      } else {
        _cartItems.add(
          CartItem(id: tempId, quantity: quantity, productId: productId),
        );
      }

      // Simpan quantity terbaru untuk debounce
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

          // Ganti item temporary dengan ID server
          final index = _cartItems.indexWhere(
            (item) => item.productId == productId,
          );
          if (index >= 0) {
            _cartItems[index] = serverCartItem;
          }

          if (_paymentMethods.isEmpty) {
            await loadPaymentMethods();
          }

          final product = _productController.getProductById(productId);
          Get.snackbar(
            'Berhasil',
            '${product?.name ?? "Item"} ditambahkan ke keranjang',
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColors.green,
            colorText: AppColors.white,
            duration: const Duration(seconds: 2),
          );
        } catch (e) {
          print('API Error: $e');
          _rollbackCartItem(productId, tempId);
          Get.snackbar(
            'Error',
            'Gagal menambahkan ke keranjang',
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColors.red,
            colorText: AppColors.white,
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
      // 1. Optimistic Update
      final index = _cartItems.indexWhere((item) => item.id == cartItemId);
      if (index < 0) return;

      final item = _cartItems[index];
      final oldQuantity = item.quantity;

      _cartItems[index] = CartItem(
        id: item.id,
        quantity: newQuantity,
        productId: item.productId,
      );

      // 2. Debounce API call
      _debounceApiCall(item.productId, () async {
        try {
          // 3. API Call
          final serverCartItem = await ApiService.updateCartItem(
            cartItemId,
            newQuantity,
          );

          // 4. Update dengan data dari server
          final currentIndex = _cartItems.indexWhere(
            (item) => item.id == cartItemId,
          );

          if (currentIndex >= 0) {
            _cartItems[currentIndex] = serverCartItem;
          }
        } catch (e) {
          print('Update cart error: $e');

          // Rollback ke quantity sebelumnya
          final rollbackIndex = _cartItems.indexWhere(
            (item) => item.id == cartItemId,
          );

          if (rollbackIndex >= 0) {
            _cartItems[rollbackIndex] = CartItem(
              id: item.id,
              quantity: oldQuantity,
              productId: item.productId,
            );
          }

          Get.snackbar(
            'Error',
            'Gagal memperbarui keranjang',
            snackPosition: SnackPosition.TOP,
            backgroundColor: AppColors.red,
            colorText: AppColors.white,
          );
        }
      });
    } catch (e) {
      print('Update quantity error: $e');
    }
  }

  Future<void> removeFromCart(int cartItemId) async {
    try {
      // 1. Simpan item untuk rollback
      final itemIndex = _cartItems.indexWhere((item) => item.id == cartItemId);
      if (itemIndex < 0) return;

      final removedItem = _cartItems[itemIndex];

      // 2. Optimistic Update - Langsung hapus dari UI
      _cartItems.removeAt(itemIndex);

      // 3. API Call
      try {
        await ApiService.removeFromCart(cartItemId);

        Get.snackbar(
          'Berhasil',
          'Item dihapus dari keranjang',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.green,
          colorText: AppColors.white,
          duration: const Duration(seconds: 2),
        );
      } catch (e) {
        print('Remove from cart error: $e');

        // Rollback - Kembalikan item
        _cartItems.insert(itemIndex, removedItem);

        Get.snackbar(
          'Error',
          'Gagal menghapus item',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.red,
          colorText: AppColors.white,
        );
      }
    } catch (e) {
      print('Remove error: $e');
    }
  }

  // Debounce helper method
  void _debounceApiCall(int productId, Function() callback) {
    if (_debounceTimers[productId] != null) {
      _debounceTimers[productId]!.cancel();
    }

    _debounceTimers[productId] = Timer(const Duration(milliseconds: 600), () {
      callback();
      _debounceTimers.remove(productId);
    });
  }

  // Rollback optimistic update
  void _rollbackCartItem(int productId, int tempId) {
    final index = _cartItems.indexWhere((item) => item.productId == productId);

    if (index >= 0) {
      final item = _cartItems[index];

      // Jika ini adalah item baru dengan temp ID, hapus
      if (item.id == tempId) {
        _cartItems.removeAt(index);
      } else {
        // Jika ini adalah update quantity, reload dari server
        loadCartItems();
      }
    }
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
      return sum + ((product?.price ?? 0) * item.quantity);
    });
  }

  int calculatePaymentFee() {
    return _selectedPaymentMethod.value?.totalFee ?? 0;
  }

  int calculateTotal() {
    return calculateSubtotal() + calculatePaymentFee();
  }

  Future<Map<String, dynamic>> createOrder(String tableNumber) async {
    if (!_authController.isLoggedIn) {
      throw Exception('Please login first');
    }

    if (_selectedPaymentMethod.value == null) {
      throw Exception('Please select payment method');
    }

    try {
      final result = await ApiService.createOrderWithPayment(
        tableNumber: tableNumber,
        paymentMethod: _selectedPaymentMethod.value!.paymentMethod,
      );

      // Clear cart after successful order
      await ApiService.clearCart();
      _cartItems.clear();
      _selectedPaymentMethod.value = null;
      _paymentMethods.clear();

      await Get.find<OrderController>().refresh();

      return result;
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

  // Force refresh
  Future<void> refresh() async {
    await loadCartItems();
  }
}
