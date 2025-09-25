import 'package:flutter/material.dart';
import 'package:selforder/services/api_service.dart';
import 'package:selforder/services/auth_service.dart';
import 'package:selforder/models/product_model.dart';
import 'package:selforder/theme/app_theme.dart';

class _CategoryProduct {
  final String image;
  final String label;
  final int? categoryId;

  const _CategoryProduct({
    required this.image,
    required this.label,
    this.categoryId,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<_CategoryProduct> _categories = [];
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  int? _selectedCategoryId;
  Map<int, int> _cartQuantities = {};
  Map<int, int> _guestCartQuantities = {};
  bool _isLoading = false;

  late Function() _authListener;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    _loadDataFromApi();
    _loadCartQuantities();
  }

  @override
  void dispose() {
    AuthService.removeAuthStateListener(_authListener);
    super.dispose();
  }

  void _setupAuthListener() {
    _authListener = () {
      if (mounted) {
        setState(() {});
        _loadCartQuantities();
      }
    };
    AuthService.addAuthStateListener(_authListener);
  }

  Future<void> _loadDataFromApi() async {
    setState(() => _isLoading = true);

    try {
      final categoriesFromApi = await ApiService.fetchCategories();
      final productsFromApi = await ApiService.fetchProducts();

      setState(() {
        _categories = [
          const _CategoryProduct(
            image: "assets/images/cafe.png",
            label: "All",
            categoryId: null,
          ),
          ...categoriesFromApi.map(
            (c) => _CategoryProduct(
              image: c.imageURL,
              label: c.name,
              categoryId: c.id,
            ),
          ),
        ];
        _products = productsFromApi;
        _filterProducts();
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      _showErrorSnackBar("Gagal memuat data dari server");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCartQuantities() async {
    if (!AuthService.isLoggedIn) {
      return;
    }

    try {
      final cartItems = await ApiService.fetchCartItems();
      final quantities = <int, int>{};

      for (final item in cartItems) {
        quantities[item.productId] = item.quantity;
      }

      setState(() {
        _cartQuantities = quantities;
      });
    } catch (e) {
      print('Gagal memuat kuantitas produk: $e');
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _selectedCategoryId == null
          ? _products
          : _products
                .where((product) => product.categoryId == _selectedCategoryId)
                .toList();
    });
  }

  void _selectCategory(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _filterProducts();
    });
  }

  void _addToCart(Product product) async {
    if (!AuthService.isLoggedIn) {
      setState(() {
        _guestCartQuantities[product.id] =
            (_guestCartQuantities[product.id] ?? 0) + 1;
      });
      _showErrorSnackBar('Silahkan masuk terlebih dahulu');
      return;
    }

    try {
      await ApiService.addToCart(product.id, 1);
      await _loadCartQuantities();
      _showSuccessSnackBar(
        '${product.name} Telah ditambahkan ke dalam keranjang',
      );
    } catch (e) {
      _showErrorSnackBar('Gagal menambahkan ke keranjang: ${e.toString()}');
    }
  }

  void _updateCartQuantity(Product product, int newQuantity) async {
    if (!AuthService.isLoggedIn) {
      setState(() {
        if (newQuantity <= 0) {
          _guestCartQuantities.remove(product.id);
          _showSuccessSnackBar('${product.name} telah dihapus dari keranjang');
        } else {
          _guestCartQuantities[product.id] = newQuantity;
        }
      });
      return;
    }

    try {
      final currentCartQuantity = _cartQuantities[product.id] ?? 0;

      if (newQuantity <= 0) {
        final cartItems = await ApiService.fetchCartItems();
        final cartItem = cartItems.firstWhere(
          (item) => item.productId == product.id,
          orElse: () => throw Exception('Barang keranjang tidak ditemukan'),
        );
        await ApiService.removeFromCart(cartItem.id);
        _showSuccessSnackBar('${product.name} telah dihapus dari keranjang');
      } else if (currentCartQuantity == 0) {
        await ApiService.addToCart(product.id, newQuantity);
      } else {
        final cartItems = await ApiService.fetchCartItems();
        final cartItem = cartItems.firstWhere(
          (item) => item.productId == product.id,
          orElse: () => throw Exception('Barang Keranjang tidak ditemukan'),
        );
        await ApiService.updateCartItem(cartItem.id, newQuantity);
      }

      await _loadCartQuantities();
    } catch (e) {
      _showErrorSnackBar('Gagal update keranjang: ${e.toString()}');
    }
  }

  int _getCartQuantity(int productId) {
    if (AuthService.isLoggedIn) {
      return _cartQuantities[productId] ?? 0;
    } else {
      return _guestCartQuantities[productId] ?? 0;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (screenWidth > 600) crossAxisCount = 3;
    if (screenWidth > 900) crossAxisCount = 4;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadDataFromApi();
          await _loadCartQuantities();
        },
        child: Column(
          children: [
            if (!AuthService.isLoggedIn)
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.secondary,
                child: Row(
                  children: [
                    const Icon(Icons.info, color: AppColors.yellow),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Anda belum masuk, silahkan masuk untuk order pesanan',
                        style: TextStyle(fontSize: 12, color: AppColors.white),
                      ),
                    ),
                  ],
                ),
              ),
            _buildCategoriesSection(),
            _buildProductsSection(crossAxisCount),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Container(
      color: AppColors.secondary.withAlpha(50),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: SizedBox(
          height: 75,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategoryId == category.categoryId;

              return GestureDetector(
                onTap: () => _selectCategory(category.categoryId),
                child: Container(
                  width: 70,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withAlpha(50) : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: AppColors.primary)
                        : null,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      category.image.startsWith('http')
                          ? Image.network(
                              category.image,
                              height: 30,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  "assets/images/cafe.png",
                                  height: 30,
                                );
                              },
                            )
                          : Image.asset(
                              category.image,
                              height: 30,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  "assets/images/cafe.png",
                                  height: 30,
                                );
                              },
                            ),
                      const SizedBox(height: 4),
                      Text(
                        category.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? AppColors.black : null,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProductsSection(int crossAxisCount) {
    if (_isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: _filteredProducts.isEmpty
            ? _buildEmptyProducts()
            : GridView.builder(
                itemCount: _filteredProducts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.65,
                ),
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: _filteredProducts[index],
                    cartQuantity: _getCartQuantity(_filteredProducts[index].id),
                    onAddToCart: () => _addToCart(_filteredProducts[index]),
                    onUpdateQuantity: (quantity) =>
                        _updateCartQuantity(_filteredProducts[index], quantity),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildEmptyProducts() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: AppColors.black),
          const SizedBox(height: 16),
          Text(
            _selectedCategoryId == null
                ? 'Produk tidak ada'
                : 'Produk tidak ada dalam kategori ini',
            style: TextStyle(fontSize: 16, color: AppColors.black),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadDataFromApi, child: const Text('Refresh')),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final int cartQuantity;
  final VoidCallback onAddToCart;
  final ValueChanged<int> onUpdateQuantity;

  const ProductCard({
    super.key,
    required this.product,
    required this.cartQuantity,
    required this.onAddToCart,
    required this.onUpdateQuantity,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.hardEdge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Stack(
            children: [
              product.imageURL.startsWith('http')
                  ? Image.network(
                      product.imageURL,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          width: double.infinity,
                          color: AppColors.grey,
                          child: const Icon(Icons.broken_image, size: 50),
                        );
                      },
                    )
                  : (product.imageURL.isNotEmpty
                        ? Image.asset(
                            product.imageURL,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                width: double.infinity,
                                color: AppColors.grey,
                                child: const Icon(Icons.broken_image, size: 50),
                              );
                            },
                          )
                        : Container(
                            height: 150,
                            width: double.infinity,
                            color: AppColors.grey,
                            child: const Icon(Icons.image, size: 50),
                          )),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: product.available ? AppColors.green : AppColors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.available ? "Tersedia" : "Habis",
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (cartQuantity > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cartQuantity.toString(),
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${_formatCurrency(product.price)}',
                  style: const TextStyle(color: AppColors.black, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: _buildCartControls(),
          ),
        ],
      ),
    );
  }

  Widget _buildCartControls() {
    if (!product.available) {
      return Container(
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.grey,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text(
            'Tidak tersedia',
            style: TextStyle(
              color: AppColors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (cartQuantity == 0) {
      return GestureDetector(
        onTap: onAddToCart,
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 1.5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: Text(
              'Tambahkan ke keranjang',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: () => onUpdateQuantity(cartQuantity - 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: AppColors.white,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              cartQuantity.toString(),
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () => onUpdateQuantity(cartQuantity + 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: AppColors.white,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}
