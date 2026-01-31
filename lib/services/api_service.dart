import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:selforder/config/app_config.dart';
import 'package:selforder/models/app_version_model.dart';
import 'package:selforder/models/cartitem_model.dart';
import 'package:selforder/models/category_model.dart';
import 'package:selforder/models/order_model.dart';
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

  // App Version Check
  static Future<AppVersion> checkAppVersion() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/appversion'),
      headers: SessionManager.getHeaders(),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return AppVersion.fromJson(jsonData);
    } else {
      throw Exception('Failed to check app version');
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

  // Categories
  static Future<List<CategoryProduct>> fetchCategories() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/categories'),
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

  // Products dengan pagination support
  static Future<List<Product>> fetchProducts({
    int? categoryId,
    String? filter,
    int page = 1,
    int limit = 6,
  }) async {
    final uri = Uri.parse('$_baseUrl/products').replace(
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (categoryId != null) 'category_id': categoryId.toString(),
        if (filter != null) 'filter': filter,
      },
    );

    final response = await http.get(uri, headers: SessionManager.getHeaders());

    _handleResponse(response);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List data = jsonData['data'];
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  // Fetch single product by ID
  static Future<Product?> fetchProductById(int productId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/products/$productId'),
      headers: SessionManager.getHeaders(),
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true && jsonData['data'] != null) {
        return Product.fromJson(jsonData['data']);
      } else {
        return null;
      }
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load product');
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
      Uri.parse('$_baseUrl/cart'),
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
      Uri.parse('$_baseUrl/cart'),
      headers: SessionManager.getHeaders(),
      body: jsonEncode({'produk_id': productId, 'kuantitas': quantity}),
    );

    _handleResponse(response);

    if (response.statusCode == 201) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true && jsonData['data'] != null) {
        return CartItem.fromJson(jsonData['data']);
      } else {
        throw Exception('Invalid response format');
      }
    } else {
      throw Exception('Failed to add item to cart');
    }
  }

  static Future<CartItem> updateCartItem(int cartItemId, int quantity) async {
    if (!SessionManager.isLoggedIn) {
      throw Exception('Please login to update cart');
    }

    final response = await http.put(
      Uri.parse('$_baseUrl/cart/$cartItemId'),
      headers: SessionManager.getHeaders(),
      body: jsonEncode({'kuantitas': quantity}),
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true && jsonData['data'] != null) {
        return CartItem.fromJson(jsonData['data']);
      } else {
        throw Exception('Invalid response format');
      }
    } else {
      throw Exception('Failed to update cart item');
    }
  }

  static Future<void> removeFromCart(int cartItemId) async {
    if (!SessionManager.isLoggedIn) {
      throw Exception('Please login to remove items from cart');
    }

    final response = await http.delete(
      Uri.parse('$_baseUrl/cart/$cartItemId'),
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
      Uri.parse('$_baseUrl/orders'),
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

  // Create Order with Duitku Payment
  static Future<Order> createOrderWithPayment({
    required String tableNumber,
    required String paymentMethod,
  }) async {
    if (!SessionManager.isLoggedIn) {
      throw Exception('Please login to create order');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/orders'),
      headers: SessionManager.getHeaders(),
      body: jsonEncode({
        'nomor_meja': tableNumber,
        'payment_method': paymentMethod,
      }),
    );

    _handleResponse(response);

    if (response.statusCode == 201) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true && jsonData['data'] != null) {
        return Order.fromJson(jsonData['data']);
      } else {
        throw Exception(jsonData['error'] ?? 'Failed to create order');
      }
    } else {
      final jsonData = jsonDecode(response.body);
      throw Exception(jsonData['error'] ?? 'Failed to create order');
    }
  }

  // Send Invoice to Email
  static Future<bool> sendInvoiceEmail(String orderId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/orders/$orderId/send-email'),
      headers: SessionManager.getHeaders(),
    );
    return response.statusCode == 200;
  }

  // Get Invoice PDF
  static Future<Uint8List> getInvoicePdfBytes(String orderId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/orders/$orderId/pdf'),
      headers: SessionManager.getHeaders(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final pdfBase64 = data['pdf_base64'];

      if (pdfBase64 != null) {
        return base64Decode(pdfBase64);
      } else {
        throw Exception('PDF tidak tersedia');
      }
    } else {
      throw Exception('Gagal mengambil PDF dari server');
    }
  }
}
