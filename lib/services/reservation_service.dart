import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:selforder/config/app_config.dart';
import 'package:selforder/models/reservation_model.dart';
import 'package:selforder/models/reservation_payment_method_model.dart';
import 'package:selforder/services/session_manager.dart';

class ReservationService {
  static final String _baseUrl = AppConfig.baseUrl;

  static void _handleResponse(http.Response response) {
    SessionManager.updateSessionFromResponse(response);

    if (response.statusCode == 401) {
      throw Exception('Session expired');
    }
  }

  // Get all user reservations
  static Future<List<Reservation>> fetchReservations() async {
    if (!SessionManager.isLoggedIn) {
      return [];
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/reservations'),
      headers: SessionManager.getHeaders(),
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true && jsonData['data'] != null) {
        final List data = jsonData['data'];
        return data.map((e) => Reservation.fromJson(e)).toList();
      }
      return [];
    } else {
      throw Exception('Failed to load reservations');
    }
  }

  // Get single reservation detail
  static Future<Reservation?> fetchReservationDetail(int id) async {
    if (!SessionManager.isLoggedIn) {
      return null;
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/reservations/$id'),
      headers: SessionManager.getHeaders(),
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true && jsonData['data'] != null) {
        return Reservation.fromJson(jsonData['data']);
      }
      return null;
    } else {
      throw Exception('Failed to load reservation detail');
    }
  }

  // Create new reservation
  static Future<Map<String, dynamic>> createReservation({
    required String namaReservasi,
    required int jumlahKursi,
    required String waktuMulai,
    required String waktuSelesai,
    String? catatan,
  }) async {
    if (!SessionManager.isLoggedIn) {
      throw Exception('Please login to create reservation');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/reservations'),
      headers: SessionManager.getHeaders(),
      body: jsonEncode({
        'nama_reservasi': namaReservasi,
        'jumlah_kursi': jumlahKursi,
        'waktu_mulai': waktuMulai,
        'waktu_selesai': waktuSelesai,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
      }),
    );

    _handleResponse(response);

    final jsonData = jsonDecode(response.body);

    if (response.statusCode == 201) {
      if (jsonData['success'] == true && jsonData['data'] != null) {
        return {
          'success': true,
          'message': jsonData['message'] ?? 'Reservation created successfully',
          'data': Reservation.fromJson(jsonData['data']),
        };
      }
    }

    return {
      'success': false,
      'message': jsonData['error'] ?? 'Failed to create reservation',
    };
  }

  // Cancel reservation
  static Future<Map<String, dynamic>> cancelReservation(int id) async {
    if (!SessionManager.isLoggedIn) {
      throw Exception('Please login to cancel reservation');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/reservations/$id/cancel'),
      headers: SessionManager.getHeaders(),
    );

    _handleResponse(response);

    final jsonData = jsonDecode(response.body);

    if (response.statusCode == 200 && jsonData['success'] == true) {
      return {
        'success': true,
        'message': jsonData['message'] ?? 'Reservation cancelled successfully',
      };
    }

    return {
      'success': false,
      'message': jsonData['error'] ?? 'Failed to cancel reservation',
    };
  }

  // Get payment methods for reservation
  static Future<List<ReservationPaymentMethod>> fetchPaymentMethods(
    int amount,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/reservationpaymentmethods'),
      headers: SessionManager.getHeaders(),
      body: jsonEncode({'amount': amount}),
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true && jsonData['data'] != null) {
        final List data = jsonData['data'];
        return data.map((e) => ReservationPaymentMethod.fromJson(e)).toList();
      }
      return [];
    } else {
      throw Exception('Failed to load payment methods');
    }
  }

  // Process reservation payment
  static Future<Map<String, dynamic>> processPayment({
    required int reservationId,
    required String paymentMethod,
  }) async {
    if (!SessionManager.isLoggedIn) {
      throw Exception('Please login to process payment');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/reservations/$reservationId/payment'),
      headers: SessionManager.getHeaders(),
      body: jsonEncode({'payment_method': paymentMethod}),
    );

    _handleResponse(response);

    final jsonData = jsonDecode(response.body);

    if (response.statusCode == 200 && jsonData['success'] == true) {
      return {
        'success': true,
        'message': jsonData['message'] ?? 'Payment created successfully',
        'data': jsonData['data'],
      };
    }

    return {
      'success': false,
      'message': jsonData['error'] ?? 'Failed to process payment',
    };
  }

  // Download reservation receipt PDF
  static Future<Uint8List?> downloadReservationPDF(int id) async {
    if (!SessionManager.isLoggedIn) {
      return null;
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/reservations/$id/pdf'),
      headers: SessionManager.getHeaders(),
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['success'] == true && jsonData['data'] != null) {
        final pdfBase64 = jsonData['data']['pdf_base64'];
        if (pdfBase64 != null) {
          return base64Decode(pdfBase64);
        }
      }
    }
    return null;
  }

  // Send reservation receipt via email
  static Future<bool> sendReservationEmail(int id) async {
    if (!SessionManager.isLoggedIn) {
      return false;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/reservations/$id/send-email'),
      headers: SessionManager.getHeaders(),
    );

    _handleResponse(response);

    return response.statusCode == 200;
  }
}
