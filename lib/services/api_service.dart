import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:selforder/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
  });

  factory ApiResponse.success(T data, {int statusCode = 200}) {
    return ApiResponse(
      success: true,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String error, {int statusCode = 500}) {
    return ApiResponse(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  String? _authToken;
  Map<String, dynamic>? _currentUser;

  // Get headers with authentication
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }

  // Generic HTTP request method
  Future<ApiResponse<Map<String, dynamic>>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final uriWithParams = queryParams != null 
          ? uri.replace(queryParameters: queryParams)
          : uri;

      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uriWithParams, headers: _headers);
          break;
        case 'POST':
          response = await _client.post(
            uriWithParams,
            headers: _headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await _client.put(
            uriWithParams,
            headers: _headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await _client.delete(uriWithParams, headers: _headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(responseData, statusCode: response.statusCode);
      } else {
        return ApiResponse.error(
          responseData['error'] ?? 'Request failed',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } on FormatException {
      return ApiResponse.error('Invalid response format');
    } catch (e) {
      return ApiResponse.error('Request failed: $e');
    }
  }

  // Authentication methods
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    final response = await _makeRequest('POST', '/login', body: {
      'email': email,
      'password': password,
    });

    if (response.success && response.data != null) {
      _currentUser = response.data!['user'];
      await _saveAuthData();
    }

    return response;
  }

  Future<ApiResponse<Map<String, dynamic>>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    return await _makeRequest('POST', '/member', body: {
      'FirstName': firstName,
      'Surname': lastName,
      'Email': email,
      'Password': password,
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    final response = await _makeRequest('POST', '/logout');
    
    if (response.success) {
      _authToken = null;
      _currentUser = null;
      await _clearAuthData();
    }
    
    return response;
  }

  Future<ApiResponse<Map<String, dynamic>>> getCurrentUser() async {
    return await _makeRequest('GET', '/currentMemberr');
  }

  Future<ApiResponse<Map<String, dynamic>>> forgotPassword({
    required String email,
  }) async {
    // This would need to be implemented in the SilverStripe API
    return await _makeRequest('POST', '/forgot-password', body: {
      'email': email,
    });
  }

  // User profile methods
  Future<ApiResponse<Map<String, dynamic>>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? password,
  }) async {
    if (_currentUser == null) {
      return ApiResponse.error('User not authenticated');
    }

    final body = <String, dynamic>{};
    if (firstName != null) body['FirstName'] = firstName;
    if (lastName != null) body['Surname'] = lastName;
    if (email != null) body['Email'] = email;
    if (password != null) body['Password'] = password;

    return await _makeRequest('PUT', '/member/${_currentUser!['ID']}', body: body);
  }

  // Products methods
  Future<ApiResponse<List<Map<String, dynamic>>>> getProducts({
    int? categoryId,
    int? limit,
    int? page,
    String? search,
  }) async {
    final queryParams = <String, String>{};
    if (categoryId != null) queryParams['filter_KategoriProdukID'] = categoryId.toString();
    if (limit != null) queryParams['limit'] = limit.toString();
    if (page != null) queryParams['page'] = page.toString();
    if (search != null) queryParams['filter_Name'] = search;

    final response = await _makeRequest('GET', '/produk', queryParams: queryParams);
    
    if (response.success && response.data != null) {
      final data = response.data!['data'] as List<dynamic>;
      return ApiResponse.success(
        data.map((item) => item as Map<String, dynamic>).toList(),
        statusCode: response.statusCode,
      );
    }
    
    return ApiResponse.error(
      response.error ?? 'Failed to fetch products',
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getProduct(int id) async {
    final response = await _makeRequest('GET', '/produk/$id');
    
    if (response.success && response.data != null) {
      return ApiResponse.success(response.data!['data'] as Map<String, dynamic>);
    }
    
    return response;
  }

  // Categories methods
  Future<ApiResponse<List<Map<String, dynamic>>>> getCategories() async {
    final response = await _makeRequest('GET', '/kategoriproduk');
    
    if (response.success && response.data != null) {
      final data = response.data!['data'] as List<dynamic>;
      return ApiResponse.success(
        data.map((item) => item as Map<String, dynamic>).toList(),
        statusCode: response.statusCode,
      );
    }
    
    return ApiResponse.error(
      response.error ?? 'Failed to fetch categories',
      statusCode: response.statusCode,
    );
  }

  // Cart methods
  Future<ApiResponse<List<Map<String, dynamic>>>> getCartItems() async {
    if (_currentUser == null) {
      return ApiResponse.error('User not authenticated');
    }

    final response = await _makeRequest('GET', '/cartitem', queryParams: {
      'filter_MemberID': _currentUser!['ID'].toString(),
    });
    
    if (response.success && response.data != null) {
      final data = response.data!['data'] as List<dynamic>;
      return ApiResponse.success(
        data.map((item) => item as Map<String, dynamic>).toList(),
        statusCode: response.statusCode,
      );
    }
    
    return ApiResponse.error(
      response.error ?? 'Failed to fetch cart items',
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> addToCart({
    required int productId,
    required int quantity,
  }) async {
    if (_currentUser == null) {
      return ApiResponse.error('User not authenticated');
    }

    return await _makeRequest('POST', '/cartitem', body: {
      'MemberID': _currentUser!['ID'],
      'ProdukID': productId,
      'Quantity': quantity,
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> updateCartItem({
    required int cartItemId,
    required int quantity,
  }) async {
    return await _makeRequest('PUT', '/cartitem/$cartItemId', body: {
      'Quantity': quantity,
    });
  }

  Future<ApiResponse<Map<String, dynamic>>> removeFromCart(int cartItemId) async {
    return await _makeRequest('DELETE', '/cartitem/$cartItemId');
  }

  // Orders methods
  Future<ApiResponse<List<Map<String, dynamic>>>> getOrders() async {
    if (_currentUser == null) {
      return ApiResponse.error('User not authenticated');
    }

    final response = await _makeRequest('GET', '/order', queryParams: {
      'filter_MemberID': _currentUser!['ID'].toString(),
    });
    
    if (response.success && response.data != null) {
      final data = response.data!['data'] as List<dynamic>;
      return ApiResponse.success(
        data.map((item) => item as Map<String, dynamic>).toList(),
        statusCode: response.statusCode,
      );
    }
    
    return ApiResponse.error(
      response.error ?? 'Failed to fetch orders',
      statusCode: response.statusCode,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> createOrder({
    required int tableNumber,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    if (_currentUser == null) {
      return ApiResponse.error('User not authenticated');
    }

    // Calculate total
    int totalAmount = 0;
    for (var item in items) {
      totalAmount += (item['price'] as int) * (item['quantity'] as int);
    }

    // Add admin fee
    const int adminFee = 3000;
    totalAmount += adminFee;

    return await _makeRequest('POST', '/order', body: {
      'MemberID': _currentUser!['ID'],
      'TableNumber': tableNumber,
      'PaymentMethod': paymentMethod,
      'TotalAmount': totalAmount,
      'Status': 'Pending',
      'Items': items,
    });
  }

  // Local storage methods
  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_authToken != null) {
      await prefs.setString('auth_token', _authToken!);
    }
    if (_currentUser != null) {
      await prefs.setString('current_user', json.encode(_currentUser!));
    }
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('current_user');
  }

  Future<void> loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    final userString = prefs.getString('current_user');
    if (userString != null) {
      _currentUser = json.decode(userString) as Map<String, dynamic>;
    }
  }

  // Getters
  bool get isAuthenticated => _currentUser != null;
  Map<String, dynamic>? get currentUser => _currentUser;
  String? get authToken => _authToken;
}