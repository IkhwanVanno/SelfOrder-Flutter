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
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.MAIN,
      page: () => const MainNavigation(),
      bindings: [
        MainBinding(),
      ],
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginPage(),
    ),
    GetPage(
      name: AppRoutes.REGISTER,
      page: () => const RegisterPage(),
    ),
    GetPage(
      name: AppRoutes.FORGOT_PASSWORD,
      page: () => const ForgotPasswordPage(),
    ),
  ];
}

// Binding untuk Main Navigation - Load semua controller yang dibutuhkan
class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SiteConfigController>(() => SiteConfigController());
    Get.lazyPut<AuthController>(() => AuthController());
    Get.lazyPut<ProductController>(() => ProductController());
    Get.lazyPut<CartController>(() => CartController());
    Get.lazyPut<OrderController>(() => OrderController());
  }
}