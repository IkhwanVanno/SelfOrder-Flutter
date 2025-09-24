import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:selforder/config/app_config.dart';
import 'package:selforder/models/member_model.dart';
import 'session_manager.dart';

class AuthService {
  static Member? _currentUser;

  // Changed to List to support multiple listeners
  static List<Function()> _authStateListeners = [];

  static Member? get currentUser => _currentUser;
  static bool get isLoggedIn =>
      SessionManager.isLoggedIn && _currentUser != null;

  // Add listener method
  static void addAuthStateListener(Function() listener) {
    if (!_authStateListeners.contains(listener)) {
      _authStateListeners.add(listener);
    }
  }

  // Remove listener method
  static void removeAuthStateListener(Function() listener) {
    _authStateListeners.remove(listener);
  }

  // Legacy support for single callback (backward compatibility)
  static set onAuthStateChanged(Function()? callback) {
    if (callback != null) {
      addAuthStateListener(callback);
    }
  }

  static Future<void> init() async {
    await SessionManager.init();

    if (SessionManager.isLoggedIn) {
      final userData = SessionManager.currentUser;
      if (userData != null) {
        try {
          _currentUser = Member.fromJson(userData);
          // Verify session is still valid
          await fetchCurrentMember();
          _notifyAllAuthStateListeners();
        } catch (e) {
          print('Session invalid, logging out: $e');
          await logout();
        }
      }
    }
  }

  static Future<bool> login(String email, String password) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/login');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = Member.fromJson(data['user']);

        final cookie = response.headers['set-cookie'];
        await SessionManager.saveSession(data['user'], cookie);

        _notifyAllAuthStateListeners();
        return true;
      } else {
        print('Login failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  static Future<bool> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/register');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'FirstName': firstName,
          'Surname': lastName,
          'Email': email,
          'Password': password,
        }),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Register error: $e');
      return false;
    }
  }

  static Future<Member?> fetchCurrentMember() async {
    if (!SessionManager.isLoggedIn) return null;

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/currentMemberr');
      final response = await http.get(
        url,
        headers: SessionManager.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = Member.fromJson(data['user']);

        // Update stored user data
        await SessionManager.updateUserData(data['user']);
        _notifyAllAuthStateListeners();
        return _currentUser;
      } else if (response.statusCode == 401) {
        await logout();
        return null;
      } else {
        print('Fetch current member failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Fetch current member error: $e');
      return null;
    }
  }

  static Future<bool> updateProfile(
    String firstName,
    String lastName,
    String email, {
    String? password,
  }) async {
    if (_currentUser == null) return false;

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/member/${_currentUser!.id}');
      final body = <String, dynamic>{
        'FirstName': firstName,
        'Surname': lastName,
        'Email': email,
      };

      if (password != null && password.isNotEmpty) {
        body['Password'] = password;
      }

      final response = await http.put(
        url,
        headers: SessionManager.getHeaders(),
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = Member.fromJson(data['data']);

        await SessionManager.updateUserData(data['data']);
        _notifyAllAuthStateListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }

  static Future<bool> logout() async {
    try {
      if (SessionManager.isLoggedIn) {
        final url = Uri.parse('${ApiConfig.baseUrl}/logout');
        await http.post(url, headers: SessionManager.getHeaders());
      }
    } catch (e) {
      print('Logout API error: $e');
    } finally {
      _currentUser = null;
      await SessionManager.clearSession();
      _notifyAllAuthStateListeners();
    }
    return true;
  }

  static void _notifyAllAuthStateListeners() {
    final listeners = List<Function()>.from(_authStateListeners);
    for (final listener in listeners) {
      try {
        listener();
      } catch (e) {
        print('Error calling auth state listener: $e');
        _authStateListeners.remove(listener);
      }
    }
  }

  // Method to clear all listeners (useful for cleanup)
  static void clearAuthStateListeners() {
    _authStateListeners.clear();
  }
}
