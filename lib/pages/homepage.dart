import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:selforder/controllers/auth_controller.dart';
import 'package:selforder/controllers/product_controller.dart';
import 'package:selforder/controllers/cart_controller.dart';
import 'package:selforder/models/product_model.dart';
import 'package:selforder/theme/app_theme.dart';
import 'package:toastification/toastification.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final productController = Get.find<ProductController>();
    final cartController = Get.find<CartController>();

    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (screenWidth > 600) crossAxisCount = 3;
    if (screenWidth > 900) crossAxisCount = 4;

    return Scaffold(
      body: Obx(() {
        return Column(
          children: [
            // Login Warning Banner
            if (!authController.isLoggedIn)
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

            // Categories Section
            _buildCategoriesSection(productController),

            // Filter Bar
            _buildFilterBar(productController),

            // Products with Infinite Scroll Pagination
            Expanded(
              child: _buildPaginatedProducts(
                productController,
                cartController,
                authController,
                crossAxisCount,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildCategoriesSection(ProductController controller) {
    return Container(
      color: AppColors.accent.withAlpha(50),
      child: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: SizedBox(
          height: 75,
          child: Obx(() {
            final allCategories = [
              _CategoryItem(
                image: "assets/images/cafe.png",
                label: "All",
                categoryId: null,
              ),
              ...controller.categories.map(
                (c) => _CategoryItem(
                  image: c.imageURL,
                  label: c.name,
                  categoryId: c.id,
                ),
              ),
            ];

            return ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: allCategories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final category = allCategories[index];

                return Obx(() {
                  final isSelected =
                      controller.selectedCategoryId == category.categoryId;

                  return GestureDetector(
                    onTap: () => controller.selectCategory(category.categoryId),
                    child: Container(
                      width: 70,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withAlpha(50)
                            : null,
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
                });
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFilterBar(ProductController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Urutkan:', style: TextStyle(fontWeight: FontWeight.bold)),
          Obx(() {
            return DropdownButton<String?>(
              value: controller.selectedFilter,
              hint: const Text("Pilih filter"),
              items: const [
                DropdownMenuItem(
                  value: 'harga_terendah',
                  child: Text('Harga Terendah'),
                ),
                DropdownMenuItem(
                  value: 'harga_tertinggi',
                  child: Text('Harga Tertinggi'),
                ),
                DropdownMenuItem(value: 'populer', child: Text('Populer')),
              ],
              onChanged: (value) {
                controller.selectedFilter = value;
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaginatedProducts(
    ProductController productController,
    CartController cartController,
    AuthController authController,
    int crossAxisCount,
  ) {
    return PagedGridView<int, Product>(
      pagingController: productController.pagingController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.65,
      ),
      padding: const EdgeInsets.all(12),
      builderDelegate: PagedChildBuilderDelegate<Product>(
        itemBuilder: (context, product, index) {
          return Obx(() {
            final cartQuantity = authController.isLoggedIn
                ? cartController.getCartQuantity(product.id)
                : productController.getGuestCartQuantity(product.id);

            return _ProductCard(
              product: product,
              cartQuantity: cartQuantity,
              isLoggedIn: authController.isLoggedIn,
              onAddToCart: () async {
                if (authController.isLoggedIn) {
                  await cartController.addToCart(product.id, 1);
                } else {
                  productController.updateGuestCart(
                    product.id,
                    cartQuantity + 1,
                  );
                  toastification.show(
                    type: ToastificationType.info,
                    style: ToastificationStyle.flatColored,
                    title: Text('Info'),
                    description: Text(
                      'Masuk untuk menyimpan keranjang Anda secara permanen.',
                    ),
                    autoCloseDuration: const Duration(seconds: 2),
                    alignment: Alignment.topCenter,
                  );
                }
              },
              onUpdateQuantity: (quantity) async {
                if (authController.isLoggedIn) {
                  if (quantity <= 0) {
                    final item = cartController.cartItems.firstWhere(
                      (item) => item.productId == product.id,
                    );
                    await cartController.removeFromCart(item.id);
                  } else {
                    final item = cartController.cartItems.firstWhere(
                      (item) => item.productId == product.id,
                    );
                    await cartController.updateQuantity(item.id, quantity);
                  }
                } else {
                  productController.updateGuestCart(product.id, quantity);
                }
              },
            );
          });
        },
        noItemsFoundIndicatorBuilder: (context) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 80,
                  color: AppColors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  productController.selectedCategoryId == null
                      ? 'Produk tidak ada'
                      : 'Produk tidak ada dalam kategori ini',
                  style: TextStyle(fontSize: 16, color: AppColors.grey),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => productController.refresh(),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          );
        },
        firstPageErrorIndicatorBuilder: (context) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 80, color: AppColors.red),
                const SizedBox(height: 16),
                const Text('Gagal memuat produk'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => productController.pagingController.refresh(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        },
        newPageErrorIndicatorBuilder: (context) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: AppColors.red),
                const SizedBox(height: 8),
                const Text('Gagal memuat halaman berikutnya'),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => productController.pagingController
                      .retryLastFailedRequest(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
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

class _ProductCard extends StatelessWidget {
  final Product product;
  final int cartQuantity;
  final bool isLoggedIn;
  final VoidCallback onAddToCart;
  final ValueChanged<int> onUpdateQuantity;

  const _ProductCard({
    required this.product,
    required this.cartQuantity,
    required this.isLoggedIn,
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
          border: Border.all(color: AppColors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text(
            'Tidak tersedia',
            style: TextStyle(
              color: AppColors.white,
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
