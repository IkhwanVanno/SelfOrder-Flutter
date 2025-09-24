import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:selforder/config/app_config.dart';
import 'package:selforder/models/cartitem_model.dart';
import 'package:selforder/models/category_model.dart';
import 'package:selforder/models/member_model.dart';
import 'package:selforder/models/order_model.dart';
import 'package:selforder/models/payment_model.dart';
import 'package:selforder/models/paymentmethod_model.dart';
import 'package:selforder/models/product_model.dart';
import 'package:selforder/models/siteconfig_model.dart';
import 'session_manager.dart';

class ApiService {
  static final String _baseUrl = AppConfig.baseUrl;
  static void _handleResponse(http.Response response) {
    SessionManager.updateSessionFromResponse(response);

    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
  }

  // SiteConfig
  static Future<SiteConfig> fetchSiteConfig() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/siteconfig'),
      headers: SessionManager.getHeaders(),
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final data = jsonData['data'];
      return SiteConfig.fromJson(data);
    } else {
      throw Exception('Failed to load site config');
    }
  }

  // Member
  static Future<Member> fetchCurrentMember() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/currentMemberr'),
        headers: SessionManager.getHeaders(),
      );

      _handleResponse(response);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final userData = jsonData['user'];
        return Member.fromJson(userData);
      } else {
        throw Exception('Failed to load user (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  // Categories
  static Future<List<CategoryProduct>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/kategoriproduk'),
      headers: SessionManager.getHeaders(),
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List data = jsonData['data'];
      return data.map((e) => CategoryProduct.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  // Products
  static Future<List<Product>> fetchProducts() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/produk'),
      headers: SessionManager.getHeaders(),
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List data = jsonData['data'];
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  // Payment method
  static Future<List<PaymentMethod>> fetchPaymentMethods(int amount) async {
    final url = Uri.parse('$_baseUrl/paymentmethods');

    final headers = {
      'Content-Type': 'application/json',
      ...SessionManager.getHeaders(),
    };

    final body = jsonEncode({'amount': amount});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode != 200) {
      throw Exception('Failed to load payment methods');
    }

    final jsonData = jsonDecode(response.body);

    if (jsonData['success'] == true && jsonData['data'] != null) {
      final List data = jsonData['data'];
      return data.map((e) => PaymentMethod.fromJson(e)).toList();
    } else {
      return [];
    }
  }

  // Cart Operations
  static Future<List<CartItem>> fetchCartItems() async {
    if (!SessionManager.isLoggedIn) {
      return [];
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/cartitem'),
      headers: SessionManager.getHeaders(),
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List data = jsonData['data'];
      return data.map((item) => CartItem.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load cart items');
    }
  }

  static Future<CartItem> addToCart(int productId, int quantity) async {
    if (!SessionManager.isLoggedIn) {
      throw Exception('Please login to add items to cart');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/cartitem'),
      headers: SessionManager.getHeaders(),
      body: jsonEncode({'ProdukID': productId, 'Kuantitas': quantity}),
    );

    _handleResponse(response);

    if (response.statusCode == 201) {
      final jsonData = jsonDecode(response.body);
      return CartItem.fromJson(jsonData['data']);
    } else {
      throw Exception('Failed to add item to cart');
    }
  }

  static Future<CartItem> updateCartItem(int cartItemId, int quantity) async {
    if (!SessionManager.isLoggedIn) {
      throw Exception('Please login to update cart');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/cartitem/$cartItemId'),
      headers: SessionManager.getHeaders(),
      body: jsonEncode({'Kuantitas': quantity}),
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return CartItem.fromJson(jsonData['data']);
    } else {
      throw Exception('Failed to update cart item');
    }
  }

  static Future<void> removeFromCart(int cartItemId) async {
    if (!SessionManager.isLoggedIn) {
      throw Exception('Please login to remove items from cart');
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/cartitem/$cartItemId'),
      headers: SessionManager.getHeaders(),
    );

    _handleResponse(response);

    if (response.statusCode != 200) {
      throw Exception('Failed to remove item from cart');
    }
  }

  static Future<void> clearCart() async {
    if (!SessionManager.isLoggedIn) {
      return;
    }

    final cartItems = await fetchCartItems();
    for (final item in cartItems) {
      await removeFromCart(item.id);
    }
  }

  // Orders
  static Future<List<Order>> fetchOrders() async {
    if (!SessionManager.isLoggedIn) {
      return [];
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/order'),
      headers: SessionManager.getHeaders(),
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List data = jsonData['data'];
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  // UPDATED: Create Order with Duitku Payment
  static Future<Map<String, dynamic>> createOrderWithPayment({
    required String tableNumber,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    if (!SessionManager.isLoggedIn) {
      throw Exception('Please login to create order');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/order'),
      headers: SessionManager.getHeaders(),
      body: jsonEncode({
        'NomorMeja': tableNumber,
        'MetodePembayaran': paymentMethod,
        'Items': items,
      }),
    );

    _handleResponse(response);

    if (response.statusCode == 201) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true) {
        return jsonData;
      } else {
        throw Exception(jsonData['error'] ?? 'Failed to create order');
      }
    } else {
      final jsonData = jsonDecode(response.body);
      throw Exception(jsonData['error'] ?? 'Failed to create order');
    }
  }

  // DEPRECATED: Keep for backward compatibility but mark as deprecated
  @Deprecated('Use createOrderWithPayment instead')
  static Future<Order> createOrder({
    required String tableNumber,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    final result = await createOrderWithPayment(
      tableNumber: tableNumber,
      paymentMethod: paymentMethod,
      items: items,
    );
    return Order.fromJson(result['order']);
  }

  // Payments
  static Future<List<Payment>> fetchPayments() async {
    if (!SessionManager.isLoggedIn) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payment'),
        headers: SessionManager.getHeaders(),
      );

      _handleResponse(response);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List data = jsonData['data'];
        return data.map((e) => Payment.fromJson(e)).toList();
      } else {
        throw Exception('Failed to load payments (${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  static Future<Payment> createPayment({
    required int orderId,
    required String paymentMethod,
    required double amount,
  }) async {
    if (!SessionManager.isLoggedIn) {
      throw Exception('Please login to create payment');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/payment'),
      headers: SessionManager.getHeaders(),
      body: jsonEncode({
        'OrderID': orderId,
        'MetodePembayaran': paymentMethod,
        'TotalHarga': amount,
      }),
    );

    _handleResponse(response);

    if (response.statusCode == 201) {
      final jsonData = jsonDecode(response.body);
      return Payment.fromJson(jsonData['data']);
    } else {
      throw Exception('Failed to create payment');
    }
  }
}
