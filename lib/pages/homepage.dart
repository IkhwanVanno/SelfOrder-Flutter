import 'package:flutter/material.dart';
import 'package:selforder/services/api_service.dart';
import 'package:selforder/services/auth_service.dart';
import 'package:selforder/models/product_model.dart';

class _CategoryItem {
  final String image;
  final String label;
  final int? categoryId;

  const _CategoryItem({
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
  List<_CategoryItem> _categories = [];
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  int? _selectedCategoryId;
  Map<int, int> _cartQuantities = {};
  Map<int, int> _guestCartQuantities = {};
  bool _isLoading = false;

  // Auth listener function
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
    // Remove the auth listener when disposing
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
          const _CategoryItem(
            image: "images/cafe.png",
            label: "All",
            categoryId: null,
          ),
          ...categoriesFromApi.map(
            (c) => _CategoryItem(
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
      _showErrorSnackBar("Failed to load data from server");
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
      print('Error loading cart quantities: $e');
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
      _showSuccessSnackBar('${product.name} added to cart (guest mode)');
      return;
    }

    try {
      await ApiService.addToCart(product.id, 1);
      await _loadCartQuantities();
      _showSuccessSnackBar('${product.name} added to cart');
    } catch (e) {
      _showErrorSnackBar('Failed to add to cart: ${e.toString()}');
    }
  }

  void _updateCartQuantity(Product product, int newQuantity) async {
    if (!AuthService.isLoggedIn) {
      setState(() {
        if (newQuantity <= 0) {
          _guestCartQuantities.remove(product.id);
          _showSuccessSnackBar(
            '${product.name} removed from cart (guest mode)',
          );
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
          orElse: () => throw Exception('Cart item not found'),
        );
        await ApiService.removeFromCart(cartItem.id);
        _showSuccessSnackBar('${product.name} removed from cart');
      } else if (currentCartQuantity == 0) {
        await ApiService.addToCart(product.id, newQuantity);
      } else {
        final cartItems = await ApiService.fetchCartItems();
        final cartItem = cartItems.firstWhere(
          (item) => item.productId == product.id,
          orElse: () => throw Exception('Cart item not found'),
        );
        await ApiService.updateCartItem(cartItem.id, newQuantity);
      }

      await _loadCartQuantities();
    } catch (e) {
      _showErrorSnackBar('Failed to update cart: ${e.toString()}');
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
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
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
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(top: 8),
                color: Colors.orange[100],
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'You are in guest mode. Login to sync your cart across devices.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/login').then((_) {
                            // No need to manually call setState here anymore
                            // The auth listener will handle it automatically
                          }),
                      child: const Text(
                        'Login',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            _buildCategoriesSection(),
            const SizedBox(height: 12),
            _buildProductsSection(crossAxisCount),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  color: isSelected ? Colors.blue.withAlpha(25) : null,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected ? Border.all(color: Colors.blue) : null,
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
                              return Image.asset("images/cafe.png", height: 30);
                            },
                          )
                        : Image.asset(
                            category.image,
                            height: 30,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset("images/cafe.png", height: 30);
                            },
                          ),
                    const SizedBox(height: 4),
                    Text(
                      category.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.blue : null,
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
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _selectedCategoryId == null
                ? 'No products available'
                : 'No products in this category',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
                          color: Colors.grey[300],
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
                                color: Colors.grey[300],
                                child: const Icon(Icons.broken_image, size: 50),
                              );
                            },
                          )
                        : Container(
                            height: 150,
                            width: double.infinity,
                            color: Colors.grey[300],
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
                    color: product.available
                        ? Colors.green[700]
                        : Colors.red[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.available ? "Available" : "Out of Stock",
                    style: const TextStyle(
                      color: Colors.white,
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
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cartQuantity.toString(),
                      style: const TextStyle(
                        color: Colors.white,
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
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
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
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text(
            'Not Available',
            style: TextStyle(
              color: Colors.grey,
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
            border: Border.all(color: Colors.amber, width: 1.5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: Text(
              'Add to Cart',
              style: TextStyle(
                color: Colors.amber,
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
        color: Colors.amber,
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
            color: Colors.white,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              cartQuantity.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () => onUpdateQuantity(cartQuantity + 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: Colors.white,
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
