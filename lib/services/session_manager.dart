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
      // Cari cookie PHPSESSID di dalam Set-Cookie
      final sessionMatch = RegExp(r'PHPSESSID=([^;]+)').firstMatch(cookie);
      if (sessionMatch != null) {
        final sessionId = 'PHPSESSID=${sessionMatch.group(1)}';
        await _prefs?.setString(_keySessionCookie, sessionId);
        _sessionCookie = sessionId;
      }
    }

    print(
      'Session saved - isLoggedIn: true, cookie: ${_sessionCookie != null}',
    );
  }

  static Future<void> updateUserData(Map<String, dynamic> userData) async {
    await _prefs?.setString(_keyUserData, jsonEncode(userData));
    print('User data updated');
  }

  static Future<void> clearSession() async {
    await _prefs?.setBool(_keyIsLoggedIn, false);
    await _prefs?.remove(_keyUserData);
    await _prefs?.remove(_keySessionCookie);
    _sessionCookie = null;
    print('Session cleared');
  }

  static bool get isLoggedIn {
    bool loggedIn = _prefs?.getBool(_keyIsLoggedIn) ?? false;
    print('Checking isLoggedIn: $loggedIn');
    return loggedIn;
  }

  static Map<String, dynamic>? get currentUser {
    final userDataString = _prefs?.getString(_keyUserData);
    if (userDataString != null) {
      try {
        return jsonDecode(userDataString);
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
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
      String sessionId = setCookieHeader.split(';')[0];
      _sessionCookie = sessionId;
      _prefs?.setString(_keySessionCookie, sessionId);
      print('Session cookie updated from response: $sessionId');
    }
  }
}
