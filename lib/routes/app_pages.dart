import 'package:get/get.dart';
import 'package:selforder/pages/loginpage.dart';
import 'package:selforder/pages/registerpage.dart';
import 'package:selforder/pages/forgotpasswordpage.dart';
import 'package:selforder/pages/main_navigation.dart';
import 'package:selforder/controllers/auth_controller.dart';
import 'package:selforder/controllers/product_controller.dart';
import 'package:selforder/controllers/cart_controller.dart';
import 'package:selforder/controllers/order_controller.dart';
import 'package:selforder/controllers/siteconfig_controller.dart';
import 'package:selforder/controllers/reservation_controller.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.MAIN,
      page: () => const MainNavigation(),
      bindings: [MainBinding()],
    ),
    GetPage(name: AppRoutes.LOGIN, page: () => const LoginPage()),
    GetPage(name: AppRoutes.REGISTER, page: () => const RegisterPage()),
    GetPage(
      name: AppRoutes.FORGOT_PASSWORD,
      page: () => const ForgotPasswordPage(),
    ),
    GetPage(
      name: '${AppRoutes.MAIN}/reservation',
      page: () => const MainNavigation(initialIndex: 3),
      bindings: [MainBinding()],
    ),
  ];
}

// Binding untuk Main Navigation - Load semua controller yang dibutuhkan
class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SiteConfigController>(SiteConfigController(), permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);
    Get.put<ProductController>(ProductController(), permanent: true);
    Get.put<CartController>(CartController(), permanent: true);
    Get.put<OrderController>(OrderController(), permanent: true);
    Get.put<ReservationController>(ReservationController(), permanent: true);
  }
}