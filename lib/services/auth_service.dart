import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:selforder/config/app_config.dart';
import 'package:selforder/models/member_model.dart';
import 'session_manager.dart';

class AuthService {
  static Member? _currentUser;

  static List<Function()> _authStateListeners = [];
  static Member? get currentUser => _currentUser;
  static bool get isLoggedIn =>
      SessionManager.isLoggedIn && _currentUser != null;

  static void addAuthStateListener(Function() listener) {
    if (!_authStateListeners.contains(listener)) {
      _authStateListeners.add(listener);
    }
  }

  static void removeAuthStateListener(Function() listener) {
    _authStateListeners.remove(listener);
  }

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
          await fetchCurrentMember();
          _notifyAllAuthStateListeners();
        } catch (e) {
          print('Session invalid, logging out: $e');
          await logout();
        }
      }
    }
  }

  static Future<bool> loginWithGoogle() async {
    try {
      // METHOD 1: Using Web Client ID (requires proper OAuth configuration)
      // final GoogleSignIn googleSignIn = GoogleSignIn(
      //   scopes: ['email', 'profile'],
      //   serverClientId: '516512875441-rism1e8vde2hij21k7idv17cdeal3ltd.apps.googleusercontent.com',
      // );
      
      // await googleSignIn.signOut();
      
      // final GoogleSignInAccount? account = await googleSignIn.signIn();
      // if (account == null) {
      //   print('Login Google dibatalkan pengguna.');
      //   return false;
      // }
      
      // final GoogleSignInAuthentication auth = await account.authentication;
      
      // final idToken = auth.idToken;
      // final accessToken = auth.accessToken;
      
      // if (idToken == null && accessToken == null) {
      //   print('ID token dan access token null');
      //   return false;
      // }
      
      // final response = await http.post(
      //   Uri.parse('${AppConfig.baseUrl}/google-login'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Accept': 'application/json',
      //   },
      //   body: jsonEncode({
      //     'id_token': idToken,
      //     'access_token': accessToken,
      //   }),
      // );

      // METHOD 2: Using basic user data (current method - simpler, no Web Client ID needed)
      // COMMENT FROM HERE ↓
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);

      await googleSignIn.signOut();

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        print('Login Google dibatalkan pengguna.');
        return false;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/google-login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': account.email,
          'display_name': account.displayName ?? '',
          'photo_url': account.photoUrl ?? '',
          'id': account.id,
        }),
      );
      // COMMENT UNTIL HERE ↑

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = Member.fromJson(data['user']);

        final cookie = response.headers['set-cookie'];
        await SessionManager.saveSession(data['user'], cookie);

        _notifyAllAuthStateListeners();
        return true;
      } else {
        print('Login Google gagal: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error login Google: $e');
      return false;
    }
  }

  static Future<bool> login(String email, String password) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/login');
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
      final url = Uri.parse('${AppConfig.baseUrl}/register');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'first_name': firstName,
          'surname': lastName,
          'email': email,
          'password': password,
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
      final url = Uri.parse('${AppConfig.baseUrl}/member');
      final response = await http.get(
        url,
        headers: SessionManager.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = Member.fromJson(data['data']);

        await SessionManager.updateUserData(data['data']);
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
      final url = Uri.parse('${AppConfig.baseUrl}/member');
      final body = <String, dynamic>{
        'first_name': firstName,
        'surname': lastName,
        'email': email,
      };

      http.Response response;
      if (password != null && password.isNotEmpty) {
        final passwordResponse = await http.put(
          Uri.parse('${AppConfig.baseUrl}/member/password'),
          headers: SessionManager.getHeaders(),
          body: jsonEncode({'new_password': password}),
        );
        if (passwordResponse.statusCode != 200) {
          return false;
        }
      }

      response = await http.put(
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
        final url = Uri.parse('${AppConfig.baseUrl}/logout');
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

  // Forgot Password
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final url = Uri.parse('${AppConfig.baseUrl}/forgotpassword');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? true,
          'message':
              data['message'] ??
              'Link atur ulang kata sandi telah dikirim ke email Anda.',
        };
      } else {
        // Handle error responses
        try {
          final data = jsonDecode(response.body);
          return {
            'success': false,
            'message':
                data['message'] ??
                'Gagal mengirim email reset password. Silakan coba lagi.',
          };
        } catch (e) {
          return {
            'success': false,
            'message':
                'Gagal mengirim email reset password. Silakan coba lagi.',
          };
        }
      }
    } catch (e) {
      print('Forgot password error: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan koneksi. Silakan coba lagi.',
      };
    }
  }
}
