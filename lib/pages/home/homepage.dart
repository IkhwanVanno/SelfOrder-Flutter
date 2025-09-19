import 'package:flutter/material.dart';
import 'package:selforder/services/api_service.dart';
import 'package:selforder/services/cart_service.dart';

void main() {
  runApp(
    const MaterialApp(home: HomePage(), debugShowCheckedModeBanner: false),
  );
}

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

class Product {
  final int id;
  final String name;
  final int price;
  final String image;
  final bool available;
  final int? categoryId;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.available = true,
    this.categoryId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['ID'] ?? 0,
      name: json['Nama'] ?? '',
      price: json['Harga'] ?? 0,
      image: json['Image']?['URL'] ?? '',
      available: json['Status']?.toString().toLowerCase() == 'aktif',
      categoryId: json['Kategori']?['ID'],
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  final CartService _cartService = CartService();

  List<_CategoryItem> _categories = [];
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  int? _selectedCategoryId;
  bool _isLoadingProducts = true;
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    _cartService.loadCart();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadCategories(), _loadProducts()]);
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoadingCategories = true;
    });

    try {
      // Add default "All" category
      _categories = [
        const _CategoryItem(
          image: "images/cafe.png",
          label: "All",
          categoryId: null,
        ),
      ];

      final response = await _apiService.getCategories();

      if (response.success && response.data != null) {
        for (final categoryData in response.data!) {
          _categories.add(
            _CategoryItem(
              image: categoryData['Image']?['URL'] ?? "images/cookie.png",
              label: categoryData['Nama'] ?? 'Unknown',
              categoryId: categoryData['ID'],
            ),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load categories: $e');
    } finally {
      setState(() {
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final response = await _apiService.getProducts(
        categoryId: _selectedCategoryId,
        limit: 50,
      );

      if (response.success && response.data != null) {
        _products = response.data!
            .map((productData) => Product.fromJson(productData))
            .toList();
        _filterProducts();
      } else {
        _showErrorSnackBar('Failed to load products: ${response.error}');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load products: $e');
    } finally {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  void _filterProducts() {
    if (_selectedCategoryId == null) {
      _filteredProducts = _products;
    } else {
      _filteredProducts = _products
          .where((product) => product.categoryId == _selectedCategoryId)
          .toList();
    }
  }

  void _selectCategory(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _filterProducts();
    });
  }

  Future<void> _addToCart(Product product) async {
    final response = await _cartService.addToCart(
      productId: product.id,
      name: product.name,
      image: product.image,
      price: product.price,
      quantity: 1,
    );

    if (response.success) {
      _showSuccessSnackBar('${product.name} added to cart');
      setState(() {}); // Refresh to update cart quantities
    } else {
      _showErrorSnackBar(response.error ?? 'Failed to add to cart');
    }
  }

  Future<void> _updateCartQuantity(Product product, int newQuantity) async {
    if (newQuantity <= 0) {
      final response = await _cartService.removeFromCart(product.id);
      if (response.success) {
        _showSuccessSnackBar('${product.name} removed from cart');
      } else {
        _showErrorSnackBar(response.error ?? 'Failed to remove from cart');
      }
    } else {
      final response = await _cartService.updateQuantity(
        productId: product.id,
        quantity: newQuantity,
      );
      if (!response.success) {
        _showErrorSnackBar(response.error ?? 'Failed to update quantity');
      }
    }
    setState(() {});
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (screenWidth > 600) crossAxisCount = 3;
    if (screenWidth > 900) crossAxisCount = 4;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            // Categories Section
            _buildCategoriesSection(),

            const SizedBox(height: 12),

            // Products Section
            _buildProductsSection(crossAxisCount),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SizedBox(
        height: 80,
        child: _isLoadingCategories
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
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
                        border: isSelected
                            ? Border.all(color: Colors.blue)
                            : null,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.network(
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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: _isLoadingProducts
            ? const Center(child: CircularProgressIndicator())
            : _filteredProducts.isEmpty
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
                    cartQuantity: _cartService.getItemQuantity(
                      _filteredProducts[index].id,
                    ),
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
          TextButton(onPressed: _loadProducts, child: const Text('Refresh')),
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
              Image.network(
                product.image,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 170,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 170,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
              ),
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
                    product.available ? "Tersedia" : "Habis",
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
            'Tidak Tersedia',
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
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
