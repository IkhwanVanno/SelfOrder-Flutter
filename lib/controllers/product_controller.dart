import 'package:get/get.dart';
import 'package:selforder/models/product_model.dart';
import 'package:selforder/models/category_model.dart';
import 'package:selforder/services/api_service.dart';
import 'package:selforder/theme/app_theme.dart';

class ProductController extends GetxController {
  final _products = <Product>[].obs;
  final _categories = <CategoryProduct>[].obs;
  final _filteredProducts = <Product>[].obs;
  final _selectedCategoryId = Rx<int?>(null);
  final _isLoading = false.obs;
  final _guestCartQuantities = <int, int>{}.obs;

  List<Product> get products => _products;
  List<CategoryProduct> get categories => _categories;
  List<Product> get filteredProducts => _filteredProducts;
  int? get selectedCategoryId => _selectedCategoryId.value;
  bool get isLoading => _isLoading.value;
  Map<int, int> get guestCartQuantities => _guestCartQuantities;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  Future<void> loadProducts() async {
    if (_products.isNotEmpty) return; // Jangan load ulang jika sudah ada

    _isLoading.value = true;
    try {
      final categories = await ApiService.fetchCategories();
      final products = await ApiService.fetchProducts();

      _categories.value = categories;
      _products.value = products;
      _filterProducts();
    } catch (e) {
      print('Failed to load products: $e');
      Get.snackbar(
        'Error',
        'Gagal memuat produk',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.red,
        colorText: AppColors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void selectCategory(int? categoryId) {
    _selectedCategoryId.value = categoryId;
    _filterProducts();
  }

  void _filterProducts() {
    if (_selectedCategoryId.value == null) {
      _filteredProducts.value = _products;
    } else {
      _filteredProducts.value = _products
          .where((product) => product.categoryId == _selectedCategoryId.value)
          .toList();
    }
  }

  Product? getProductById(int productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Guest cart management (untuk user yang belum login)
  void updateGuestCart(int productId, int quantity) {
    if (quantity <= 0) {
      _guestCartQuantities.remove(productId);
    } else {
      _guestCartQuantities[productId] = quantity;
    }
  }

  int getGuestCartQuantity(int productId) {
    return _guestCartQuantities[productId] ?? 0;
  }

  void clearGuestCart() {
    _guestCartQuantities.clear();
  }

  // Force refresh (hanya dipanggil saat pull-to-refresh)
  Future<void> refresh() async {
    _products.clear();
    await loadProducts();
  }
}
