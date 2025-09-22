import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }

  void _loadDummyData() {
    // Dummy categories
    _categories = [
      const _CategoryItem(
        image: "images/cafe.png",
        label: "All",
        categoryId: null,
      ),
      const _CategoryItem(
        image: "images/coffee.png",
        label: "Coffee",
        categoryId: 1,
      ),
      const _CategoryItem(image: "images/tea.png", label: "Tea", categoryId: 2),
      const _CategoryItem(
        image: "images/snack.png",
        label: "Snacks",
        categoryId: 3,
      ),
      const _CategoryItem(
        image: "images/dessert.png",
        label: "Desserts",
        categoryId: 4,
      ),
    ];

    // Dummy products
    _products = [
      Product(
        id: 1,
        name: "Espresso",
        price: 15000,
        image: "images/espresso.jpg",
        categoryId: 1,
      ),
      Product(
        id: 2,
        name: "Cappuccino",
        price: 25000,
        image: "images/cappuccino.jpg",
        categoryId: 1,
      ),
      Product(
        id: 3,
        name: "Latte",
        price: 28000,
        image: "images/latte.jpg",
        categoryId: 1,
      ),
      Product(
        id: 4,
        name: "Americano",
        price: 18000,
        image: "images/americano.jpg",
        categoryId: 1,
      ),
      Product(
        id: 5,
        name: "Mocha",
        price: 32000,
        image: "images/mocha.jpg",
        categoryId: 1,
      ),
      Product(
        id: 6,
        name: "Green Tea",
        price: 12000,
        image: "images/green_tea.jpg",
        categoryId: 2,
      ),
      Product(
        id: 7,
        name: "Earl Grey",
        price: 15000,
        image: "images/earl_grey.jpg",
        categoryId: 2,
      ),
      Product(
        id: 8,
        name: "Jasmine Tea",
        price: 13000,
        image: "images/jasmine.jpg",
        categoryId: 2,
      ),
      Product(
        id: 9,
        name: "Croissant",
        price: 22000,
        image: "images/croissant.jpg",
        categoryId: 3,
      ),
      Product(
        id: 10,
        name: "Sandwich",
        price: 35000,
        image: "images/sandwich.jpg",
        categoryId: 3,
      ),
      Product(
        id: 11,
        name: "Muffin",
        price: 18000,
        image: "images/muffin.jpg",
        categoryId: 3,
      ),
      Product(
        id: 12,
        name: "Cheesecake",
        price: 40000,
        image: "images/cheesecake.jpg",
        categoryId: 4,
      ),
      Product(
        id: 13,
        name: "Tiramisu",
        price: 45000,
        image: "images/tiramisu.jpg",
        categoryId: 4,
      ),
      Product(
        id: 14,
        name: "Chocolate Cake",
        price: 38000,
        image: "images/chocolate_cake.jpg",
        categoryId: 4,
      ),
      Product(
        id: 15,
        name: "Ice Cream",
        price: 20000,
        image: "images/ice_cream.jpg",
        categoryId: 4,
        available: false,
      ),
    ];

    _filterProducts();
    setState(() {});
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

  void _addToCart(Product product) {
    setState(() {
      _cartQuantities[product.id] = (_cartQuantities[product.id] ?? 0) + 1;
    });

    _showSuccessSnackBar('${product.name} added to cart');
  }

  void _updateCartQuantity(Product product, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _cartQuantities.remove(product.id);
        _showSuccessSnackBar('${product.name} removed from cart');
      } else {
        _cartQuantities[product.id] = newQuantity;
      }
    });
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
        onRefresh: () async {
          await Future.delayed(const Duration(seconds: 1));
          _loadDummyData();
        },
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
                    Image.asset(
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
                    cartQuantity:
                        _cartQuantities[_filteredProducts[index].id] ?? 0,
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
          TextButton(onPressed: _loadDummyData, child: const Text('Refresh')),
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
              Image.asset(
                product.image,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
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
