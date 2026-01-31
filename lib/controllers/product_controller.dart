import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:selforder/models/product_model.dart';
import 'package:selforder/models/category_model.dart';
import 'package:selforder/services/api_service.dart';
import 'package:toastification/toastification.dart';

const _pageSize = 6; // Sesuai dengan limit di API

class ProductController extends GetxController {
  final _categories = <CategoryProduct>[].obs;
  final _selectedCategoryId = Rx<int?>(null);
  final _selectedFilter = Rx<String?>(null);
  final _guestCartQuantities = <int, int>{}.obs;
  final _productCache = <int, Product>{}.obs;

  // Pagination controller
  final PagingController<int, Product> pagingController = PagingController(
    firstPageKey: 1,
  );

  List<CategoryProduct> get categories => _categories;
  int? get selectedCategoryId => _selectedCategoryId.value;
  String? get selectedFilter => _selectedFilter.value;
  Map<int, int> get guestCartQuantities => _guestCartQuantities;

  set selectedFilter(String? value) {
    _selectedFilter.value = value;
    resetPagination();
  }

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    setupPagingController();
  }

  void setupPagingController() {
    pagingController.addPageRequestListener((pageKey) {
      _fetchProductPage(pageKey);
    });
  }

  Future<void> loadCategories() async {
    try {
      final categories = await ApiService.fetchCategories();
      _categories.value = categories;
    } catch (e) {
      print('Failed to load categories: $e');
      toastification.show(
        title: const Text('Error'),
        description: const Text('Gagal memuat kategori produk'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
      );
    }
  }

  Future<void> loadProducts() async {
    resetPagination();
  }

  Future<void> _fetchProductPage(int pageKey) async {
    try {
      final newProducts = await ApiService.fetchProducts(
        categoryId: _selectedCategoryId.value,
        filter: _selectedFilter.value,
        page: pageKey,
        limit: _pageSize,
      );

      for (final product in newProducts) {
        _productCache[product.id] = product;
      }

      if (isClosed) return;
      final isLastPage = newProducts.length < _pageSize;

      if (isLastPage) {
        pagingController.appendLastPage(newProducts);
      } else {
        final nextPageKey = pageKey + 1;
        pagingController.appendPage(newProducts, nextPageKey);
      }
    } catch (error) {
      if (!isClosed) {
        pagingController.error = error;
      }

      toastification.show(
        title: const Text('Error'),
        description: const Text('Gagal memuat produk'),
        type: ToastificationType.error,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: Duration(seconds: 2),
      );
    }
  }

  void selectCategory(int? categoryId) {
    _selectedCategoryId.value = categoryId;
    resetPagination();
  }

  void resetPagination() {
    pagingController.refresh();
  }

  Product? getProductById(int productId) {
    if (_productCache.containsKey(productId)) {
      return _productCache[productId];
    }

    try {
      final allProducts = pagingController.itemList ?? [];
      final product = allProducts.firstWhere((p) => p.id == productId);
      _productCache[productId] = product;
      return product;
    } catch (e) {
      print('Product $productId not found in cache or pagingController');
      return null;
    }
  }

  Future<Product?> fetchAndCacheProduct(int productId) async {
    try {
      if (_productCache.containsKey(productId)) {
        return _productCache[productId];
      }
      final product = await ApiService.fetchProductById(productId);
      if (product != null) {
        _productCache[productId] = product;
      }

      return product;
    } catch (e) {
      print('Failed to fetch product $productId: $e');
      return null;
    }
  }

  Future<void> preloadProductsByIds(List<int> productIds) async {
    try {
      final missingIds = productIds
          .where((id) => !_productCache.containsKey(id))
          .toList();

      if (missingIds.isEmpty) {
        print('All products already in cache');
        return;
      }

      print('Pre-loading ${missingIds.length} missing products...');

      for (final productId in missingIds) {
        await fetchAndCacheProduct(productId);
      }

      print('Pre-loading complete');
    } catch (e) {
      print('Failed to preload products: $e');
    }
  }
  
  void clearProductCache() {
    _productCache.clear();
  }

  // Guest cart management
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

  Future<void> refresh() async {
    loadCategories();
    resetPagination();
  }

  @override
  void onClose() {
    pagingController.dispose();
    super.onClose();
  }
}
