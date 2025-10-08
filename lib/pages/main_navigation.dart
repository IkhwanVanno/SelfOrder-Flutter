import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:selforder/controllers/auth_controller.dart';
import 'package:selforder/controllers/siteconfig_controller.dart';
import 'package:selforder/pages/homepage.dart';
import 'package:selforder/pages/cartpage.dart';
import 'package:selforder/pages/orderpage.dart';
import 'package:selforder/pages/profilepage.dart';
import 'package:selforder/routes/app_routes.dart';
import 'package:selforder/theme/app_theme.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const CartPage(),
    const OrderPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final siteConfigController = Get.find<SiteConfigController>();

    return Scaffold(
      appBar: AppBar(
        leading: Obx(() {
          final siteConfig = siteConfigController.siteConfig;
          if (siteConfig != null && siteConfig.imageURL.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: siteConfig.imageURL.startsWith('http')
                  ? Image.network(
                      siteConfig.imageURL,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          "assets/images/cafe.png",
                          fit: BoxFit.contain,
                        );
                      },
                    )
                  : Image.asset(
                      siteConfig.imageURL,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          "assets/images/cafe.png",
                          fit: BoxFit.contain,
                        );
                      },
                    ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset(
              "assets/images/cafe.png",
              fit: BoxFit.contain,
            ),
          );
        }),
        title: Obx(() {
          final siteConfig = siteConfigController.siteConfig;
          return Text(
            siteConfig?.title ?? 'Self Order',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          );
        }),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        actions: [
          Obx(() {
            if (authController.isLoggedIn && authController.currentUser != null) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Text(
                    'Hi, ${authController.currentUser!.firstName}',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            } else {
              return TextButton(
                onPressed: () => Get.toNamed(AppRoutes.LOGIN),
                child: const Text(
                  'Masuk',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Rumah'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.white,
        unselectedItemColor: AppColors.secondary,
        backgroundColor: AppColors.primary,
        onTap: _onItemTapped,
      ),
    );
  }
}