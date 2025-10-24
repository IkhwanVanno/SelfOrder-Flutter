import 'package:get/get.dart';
import 'package:selforder/controllers/reservation_controller.dart';
import 'package:selforder/models/member_model.dart';
import 'package:selforder/services/auth_service.dart';
import 'package:selforder/controllers/product_controller.dart';
import 'package:selforder/controllers/cart_controller.dart';
import 'package:selforder/controllers/order_controller.dart';

class AuthController extends GetxController {
  final _currentUser = Rx<Member?>(null);
  final _isLoggedIn = false.obs;
  final _isLoading = false.obs;

  Member? get currentUser => _currentUser.value;
  bool get isLoggedIn => _isLoggedIn.value;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    _isLoading.value = true;
    try {
      if (AuthService.isLoggedIn) {
        final user = await AuthService.fetchCurrentMember();
        if (user != null) {
          _currentUser.value = user;
          _isLoggedIn.value = true;
          await _loadUserData();
        }
      }
    } catch (e) {
      print('Check login error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading.value = true;
    try {
      final success = await AuthService.login(email, password);
      if (success) {
        final user = await AuthService.fetchCurrentMember();
        _currentUser.value = user;
        _isLoggedIn.value = true;
        await _loadUserData();
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading.value = true;
    try {
      final success = await AuthService.loginWithGoogle();
      if (success) {
        final user = await AuthService.fetchCurrentMember();
        _currentUser.value = user;
        _isLoggedIn.value = true;
        await _loadUserData();
        return true;
      }
      return false;
    } catch (e) {
      print('Google login error: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    _isLoading.value = true;
    try {
      final success = await AuthService.register(
        firstName,
        lastName,
        email,
        password,
      );
      return success;
    } catch (e) {
      print('Register error: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    _isLoading.value = true;
    try {
      final result = await AuthService.forgotPassword(email);
      return result;
    } catch (e) {
      print('Forgot password error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan'};
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> updateProfile(
    String firstName,
    String lastName,
    String email, {
    String? password,
  }) async {
    _isLoading.value = true;
    try {
      final success = await AuthService.updateProfile(
        firstName,
        lastName,
        email,
        password: password,
      );

      if (success) {
        final user = await AuthService.fetchCurrentMember();
        _currentUser.value = user;
      }

      return success;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    _isLoading.value = true;
    try {
      await AuthService.logout();
      _currentUser.value = null;
      _isLoggedIn.value = false;
      _clearUserData();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _loadUserData() async {
    try {
      if (Get.isRegistered<ProductController>()) {
        await Get.find<ProductController>().refresh();
      }

      if (Get.isRegistered<CartController>()) {
        await Get.find<CartController>().loadCartItems();
      }

      if (Get.isRegistered<OrderController>()) {
        await Get.find<OrderController>().loadOrders();
      }

      if (Get.isRegistered<ReservationController>()) {
        await Get.find<ReservationController>().loadReservations();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  void _clearUserData() {
    if (Get.isRegistered<CartController>()) {
      Get.find<CartController>().clearCart();
    }
    if (Get.isRegistered<OrderController>()) {
      Get.find<OrderController>().clearOrders();
    }
  }
}
