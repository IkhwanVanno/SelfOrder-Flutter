import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SessionManager {
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserData = 'userData';
  static const String _keySessionCookie = 'sessionCookie';

  static SharedPreferences? _prefs;
  static String? _sessionCookie;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _sessionCookie = _prefs?.getString(_keySessionCookie);
  }

  static Future<void> saveSession(
    Map<String, dynamic> userData,
    String? cookie,
  ) async {
    await _prefs?.setBool(_keyIsLoggedIn, true);
    await _prefs?.setString(_keyUserData, jsonEncode(userData));
    if (cookie != null) {
      await _prefs?.setString(_keySessionCookie, cookie);
      _sessionCookie = cookie;
    }
  }

  static Future<void> clearSession() async {
    await _prefs?.clear();
    _sessionCookie = null;
  }

  static bool get isLoggedIn {
    return _prefs?.getBool(_keyIsLoggedIn) ?? false;
  }

  static Map<String, dynamic>? get currentUser {
    final userDataString = _prefs?.getString(_keyUserData);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  static String? get sessionCookie => _sessionCookie;

  static Map<String, String> getHeaders() {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_sessionCookie != null) {
      headers['Cookie'] = _sessionCookie!;
    }

    return headers;
  }

  static void updateSessionFromResponse(http.Response response) {
    final setCookieHeader = response.headers['set-cookie'];
    if (setCookieHeader != null) {
      _sessionCookie = setCookieHeader.split(';')[0];
      _prefs?.setString(_keySessionCookie, _sessionCookie!);
    }
  }
}
