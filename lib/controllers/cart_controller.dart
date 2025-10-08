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

  List<CartItem> get cartItems => _cartItems;
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  PaymentMethod? get selectedPaymentMethod => _selectedPaymentMethod.value;
  bool get isLoading => _isLoading.value;
  bool get isLoadingPayment => _isLoadingPayment.value;

  int get totalItems => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  AuthController get _authController => Get.find<AuthController>();
  ProductController get _productController => Get.find<ProductController>();

  Future<void> loadCartItems() async {
    if (!_authController.isLoggedIn) {
      _cartItems.clear();
      return;
    }

    _isLoading.value = true;
    try {
      final items = await ApiService.fetchCartItems();
      _cartItems.value = items;

      // Load payment methods jika cart tidak kosong
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
      await ApiService.addToCart(productId, quantity);

      // Update local cart
      final existingIndex = _cartItems.indexWhere(
        (item) => item.productId == productId,
      );
      if (existingIndex >= 0) {
        // Update existing item
        final item = _cartItems[existingIndex];
        _cartItems[existingIndex] = CartItem(
          id: item.id,
          quantity: item.quantity + quantity,
          productId: item.productId,
        );
      } else {
        // Add new item (ID akan di-update saat load ulang, tapi untuk UI sudah cukup)
        _cartItems.add(
          CartItem(
            id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
            quantity: quantity,
            productId: productId,
          ),
        );
      }

      // Load payment methods jika belum ada
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
      );
    } catch (e) {
      print('Add to cart error: $e');
      Get.snackbar(
        'Error',
        'Gagal menambahkan ke keranjang',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
      );
    }
  }

  Future<void> updateQuantity(int cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeFromCart(cartItemId);
      return;
    }

    try {
      await ApiService.updateCartItem(cartItemId, newQuantity);

      // Update local
      final index = _cartItems.indexWhere((item) => item.id == cartItemId);
      if (index >= 0) {
        final item = _cartItems[index];
        _cartItems[index] = CartItem(
          id: item.id,
          quantity: newQuantity,
          productId: item.productId,
        );
      }
    } catch (e) {
      print('Update cart error: $e');
      Get.snackbar(
        'Error',
        'Gagal memperbarui keranjang',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
      );
    }
  }

  Future<void> removeFromCart(int cartItemId) async {
    try {
      await ApiService.removeFromCart(cartItemId);

      // Remove from local
      _cartItems.removeWhere((item) => item.id == cartItemId);

      Get.snackbar(
        'Berhasil',
        'Item dihapus dari keranjang',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.green,
        colorText: AppColors.white,
      );
    } catch (e) {
      print('Remove from cart error: $e');
      Get.snackbar(
        'Error',
        'Gagal menghapus item',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
      );
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
