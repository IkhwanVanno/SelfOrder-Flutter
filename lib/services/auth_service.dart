import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:selforder/config/app_config.dart';
import 'package:selforder/models/member_model.dart';
import 'session_manager.dart';

class AuthService {
  static Member? _currentUser;

  static Member? get currentUser => _currentUser;
  static bool get isLoggedIn => SessionManager.isLoggedIn;

  static Future<void> init() async {
    await SessionManager.init();

    if (SessionManager.isLoggedIn) {
      final userData = SessionManager.currentUser;
      if (userData != null) {
        _currentUser = Member.fromJson(userData);

        try {
          await fetchCurrentMember();
        } catch (e) {
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

        return true;
      } else {
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
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/currentMemberr');
      final response = await http.get(
        url,
        headers: SessionManager.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = Member.fromJson(data['user']);

        await SessionManager.saveSession(data['user'], null);
        return _currentUser;
      } else if (response.statusCode == 401) {
        await logout();
        return null;
      }
      return null;
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

        await SessionManager.saveSession(data['data'], null);
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
      final url = Uri.parse('${ApiConfig.baseUrl}/logout');
      await http.post(url, headers: SessionManager.getHeaders());

      _currentUser = null;
      await SessionManager.clearSession();
      return true;
    } catch (e) {
      _currentUser = null;
      await SessionManager.clearSession();
      return true;
    }
  }
}
