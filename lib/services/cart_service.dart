import 'dart:convert';
import 'package:selforder/models/cart_item.dart';
import 'package:selforder/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';



class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final ApiService _apiService = ApiService();
  List<CartItem> _cartItems = [];
  final String _cartKey = 'cart_items';

  List<CartItem> get cartItems => List.unmodifiable(_cartItems);
  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  int get totalAmount => _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  bool get isEmpty => _cartItems.isEmpty;
  bool get isNotEmpty => _cartItems.isNotEmpty;

  // Load cart from local storage
  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString(_cartKey);
      
      if (cartData != null) {
        final List<dynamic> cartList = json.decode(cartData);
        _cartItems = cartList.map((item) => CartItem.fromJson(item)).toList();
      }
    } catch (e) {
      print('Error loading cart: $e');
      _cartItems = [];
    }
  }

  // Save cart to local storage
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = json.encode(_cartItems.map((item) => item.toJson()).toList());
      await prefs.setString(_cartKey, cartData);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  // Add item to cart
  Future<ApiResponse<bool>> addToCart({
    required int productId,
    required String name,
    required String image,
    required int price,
    int quantity = 1,
  }) async {
    try {
      // Check if item already exists in cart
      final existingIndex = _cartItems.indexWhere((item) => item.productId == productId);
      
      if (existingIndex != -1) {
        // Update quantity
        _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(
          quantity: _cartItems[existingIndex].quantity + quantity,
        );
      } else {
        // Add new item
        _cartItems.add(CartItem(
          productId: productId,
          name: name,
          image: image,
          price: price,
          quantity: quantity,
        ));
      }

      await _saveCart();

      // Sync with server if authenticated
      if (_apiService.isAuthenticated) {
        await _syncCartWithServer();
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error('Failed to add item to cart: $e');
    }
  }

  // Update item quantity
  Future<ApiResponse<bool>> updateQuantity({
    required int productId,
    required int quantity,
  }) async {
    try {
      if (quantity <= 0) {
        return removeFromCart(productId);
      }

      final existingIndex = _cartItems.indexWhere((item) => item.productId == productId);
      
      if (existingIndex == -1) {
        return ApiResponse.error('Item not found in cart');
      }

      _cartItems[existingIndex] = _cartItems[existingIndex].copyWith(quantity: quantity);
      await _saveCart();

      // Sync with server if authenticated
      if (_apiService.isAuthenticated) {
        await _syncCartWithServer();
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error('Failed to update quantity: $e');
    }
  }

  // Remove item from cart
  Future<ApiResponse<bool>> removeFromCart(int productId) async {
    try {
      _cartItems.removeWhere((item) => item.productId == productId);
      await _saveCart();

      // Sync with server if authenticated
      if (_apiService.isAuthenticated) {
        await _syncCartWithServer();
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error('Failed to remove item from cart: $e');
    }
  }

  // Clear cart
  Future<ApiResponse<bool>> clearCart() async {
    try {
      _cartItems.clear();
      await _saveCart();

      // Clear server cart if authenticated
      if (_apiService.isAuthenticated) {
        await _clearServerCart();
      }

      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error('Failed to clear cart: $e');
    }
  }

  // Get item quantity
  int getItemQuantity(int productId) {
    final item = _cartItems.firstWhere(
      (item) => item.productId == productId,
      orElse: () => CartItem(
        productId: productId,
        name: '',
        image: '',
        price: 0,
        quantity: 0,
      ),
    );
    return item.quantity;
  }

  // Check if item is in cart
  bool isInCart(int productId) {
    return _cartItems.any((item) => item.productId == productId);
  }

  // Sync cart with server
  Future<void> _syncCartWithServer() async {
    try {
      // First, clear server cart
      await _clearServerCart();

      // Then, add all local items to server
      for (final item in _cartItems) {
        await _apiService.addToCart(
          productId: item.productId,
          quantity: item.quantity,
        );
      }
    } catch (e) {
      print('Error syncing cart with server: $e');
    }
  }

  // Clear server cart
  Future<void> _clearServerCart() async {
    try {
      final response = await _apiService.getCartItems();
      if (response.success && response.data != null) {
        for (final serverItem in response.data!) {
          if (serverItem['ID'] != null) {
            await _apiService.removeFromCart(serverItem['ID']);
          }
        }
      }
    } catch (e) {
      print('Error clearing server cart: $e');
    }
  }

  // Load cart from server
  Future<ApiResponse<bool>> loadCartFromServer() async {
    try {
      if (!_apiService.isAuthenticated) {
        return ApiResponse.error('User not authenticated');
      }

      final response = await _apiService.getCartItems();
      if (response.success && response.data != null) {
        _cartItems.clear();
        
        for (final serverItem in response.data!) {
          // Map server cart item to local cart item
          _cartItems.add(CartItem(
            id: serverItem['ID'],
            productId: serverItem['ProdukID'] ?? 0,
            name: serverItem['ProductName'] ?? serverItem['Produk']?['Name'] ?? 'Unknown',
            image: serverItem['ProductImage'] ?? serverItem['Produk']?['Image'] ?? '',
            price: serverItem['Price'] ?? serverItem['Produk']?['Price'] ?? 0,
            quantity: serverItem['Quantity'] ?? 0,
          ));
        }

        await _saveCart();
        return ApiResponse.success(true);
      }

      return response.error != null 
          ? ApiResponse.error(response.error!)
          : ApiResponse.error('Failed to load cart from server');
    } catch (e) {
      return ApiResponse.error('Failed to load cart from server: $e');
    }
  }

  // Create order from cart
  Future<ApiResponse<Map<String, dynamic>>> createOrder({
    required int tableNumber,
    required String paymentMethod,
  }) async {
    try {
      if (_cartItems.isEmpty) {
        return ApiResponse.error('Cart is empty');
      }

      if (!_apiService.isAuthenticated) {
        return ApiResponse.error('User not authenticated');
      }

      final orderItems = _cartItems.map((item) => item.toApiJson()).toList();

      final response = await _apiService.createOrder(
        tableNumber: tableNumber,
        paymentMethod: paymentMethod,
        items: orderItems,
      );

      if (response.success) {
        // Clear cart after successful order
        await clearCart();
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to create order: $e');
    }
  }

  // Get cart summary
  Map<String, dynamic> getCartSummary() {
    const int adminFee = 3000;
    final subtotal = totalAmount;
    final total = subtotal + adminFee;

    return {
      'itemCount': itemCount,
      'subtotal': subtotal,
      'adminFee': adminFee,
      'total': total,
      'items': _cartItems.map((item) => item.toJson()).toList(),
    };
  }

  // Validate cart before checkout
  ApiResponse<bool> validateCart() {
    if (_cartItems.isEmpty) {
      return ApiResponse.error('Cart is empty');
    }

    // Check for invalid quantities
    for (final item in _cartItems) {
      if (item.quantity <= 0) {
        return ApiResponse.error('Invalid quantity for ${item.name}');
      }
      if (item.price <= 0) {
        return ApiResponse.error('Invalid price for ${item.name}');
      }
    }

    return ApiResponse.success(true);
  }

  // Merge carts when user logs in
  Future<ApiResponse<bool>> mergeCartsOnLogin() async {
    try {
      if (!_apiService.isAuthenticated) {
        return ApiResponse.error('User not authenticated');
      }

      // Load server cart
      final serverResponse = await _apiService.getCartItems();
      if (serverResponse.success && serverResponse.data != null) {
        final serverItems = <CartItem>[];
        
        for (final serverItem in serverResponse.data!) {
          serverItems.add(CartItem(
            id: serverItem['ID'],
            productId: serverItem['ProdukID'] ?? 0,
            name: serverItem['ProductName'] ?? 'Unknown',
            image: serverItem['ProductImage'] ?? '',
            price: serverItem['Price'] ?? 0,
            quantity: serverItem['Quantity'] ?? 0,
          ));
        }

        // Merge local cart with server cart
        for (final localItem in List<CartItem>.from(_cartItems)) {
          final serverItemIndex = serverItems.indexWhere(
            (serverItem) => serverItem.productId == localItem.productId,
          );

          if (serverItemIndex != -1) {
            // Item exists in both - combine quantities
            final combinedQuantity = localItem.quantity + serverItems[serverItemIndex].quantity;
            serverItems[serverItemIndex] = serverItems[serverItemIndex].copyWith(
              quantity: combinedQuantity,
            );
          } else {
            // Item only in local cart - add to server items
            serverItems.add(localItem);
          }
        }

        // Update local cart and sync to server
        _cartItems = serverItems;
        await _saveCart();
        await _syncCartWithServer();

        return ApiResponse.success(true);
      }

      // If server cart is empty, just sync local cart to server
      await _syncCartWithServer();
      return ApiResponse.success(true);
    } catch (e) {
      return ApiResponse.error('Failed to merge carts: $e');
    }
  }
}