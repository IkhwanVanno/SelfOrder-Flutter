import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:selforder/config/app_config.dart';
import 'package:selforder/services/api_service.dart';

class DuitkuPaymentMethod {
  final String paymentMethod;
  final String paymentName;
  final int totalFee;

  DuitkuPaymentMethod({
    required this.paymentMethod,
    required this.paymentName,
    required this.totalFee,
  });

  factory DuitkuPaymentMethod.fromJson(Map<String, dynamic> json) {
    return DuitkuPaymentMethod(
      paymentMethod: json['paymentMethod'] ?? '',
      paymentName: json['paymentName'] ?? '',
      totalFee: int.tryParse(json['totalFee']?.toString() ?? '0') ?? 0,
    );
  }
}

class DuitkuTransactionResponse {
  final String? merchantCode;
  final String? reference;
  final String? paymentUrl;
  final String? vaNumber;
  final int? amount;
  final String? statusCode;
  final String? statusMessage;

  DuitkuTransactionResponse({
    this.merchantCode,
    this.reference,
    this.paymentUrl,
    this.vaNumber,
    this.amount,
    this.statusCode,
    this.statusMessage,
  });

  factory DuitkuTransactionResponse.fromJson(Map<String, dynamic> json) {
    return DuitkuTransactionResponse(
      merchantCode: json['merchantCode'],
      reference: json['reference'],
      paymentUrl: json['paymentUrl'],
      vaNumber: json['vaNumber'],
      amount: int.tryParse(json['amount']?.toString() ?? '0'),
      statusCode: json['statusCode'],
      statusMessage: json['statusMessage'],
    );
  }

  bool get isSuccess => statusCode == '00';
}

class DuitkuService {
  static final DuitkuService _instance = DuitkuService._internal();
  factory DuitkuService() => _instance;
  DuitkuService._internal();

  final http.Client _client = http.Client();

  String get merchantCode => ApiConfig.duitkuMerchantCode;
  String get apiKey => ApiConfig.duitkuApiKey;
  String get baseUrl => ApiConfig.duitkuBaseUrl;
  String get paymentMethodUrl => ApiConfig.duitkuPaymentMethodUrl;

  // Generate datetime in Duitku format: YYYY-MM-DD HH:mm:ss
  String _generateDateTime() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  // Generate signature for payment method inquiry (SHA-256)
  String _generatePaymentMethodSignature({
    required String merchantCode,
    required String amount,
    required String datetime,
    required String apiKey,
  }) {
    final data = '$merchantCode$amount$datetime$apiKey';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate signature for transaction creation
  String _generateTransactionSignature({
    required String merchantCode,
    required String paymentAmount,
    required String merchantOrderId,
    required String apiKey,
  }) {
    final data = '$merchantCode$paymentAmount$merchantOrderId$apiKey';
    final bytes = utf8.encode(data);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  // Get available payment methods
  Future<ApiResponse<List<DuitkuPaymentMethod>>> getPaymentMethods({
    required int amount,
  }) async {
    try {
      final datetime = _generateDateTime();
      final signature = _generatePaymentMethodSignature(
        merchantCode: merchantCode,
        amount: amount.toString(),
        datetime: datetime,
        apiKey: apiKey,
      );

      final requestBody = {
        'merchantcode': merchantCode,
        'amount': amount,
        'datetime': datetime,
        'signature': signature,
      };

      print('Duitku Payment Methods Request: ${json.encode(requestBody)}');
      print('Signature data: $merchantCode$amount$datetime$apiKey');
      print('Generated signature: $signature');

      final response = await _client.post(
        Uri.parse(paymentMethodUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('Duitku Payment Methods Response Status: ${response.statusCode}');
      print('Duitku Payment Methods Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;

        if (responseData['paymentFee'] != null) {
          final paymentFee = responseData['paymentFee'] as List<dynamic>;
          final methods = paymentFee.map((item) {
            return DuitkuPaymentMethod.fromJson(item as Map<String, dynamic>);
          }).toList();

          if (methods.isEmpty) {
            return ApiResponse.error(
              'No payment methods available for this amount',
            );
          }

          return ApiResponse.success(methods);
        } else {
          final errorMessage =
              responseData['Message'] ??
              responseData['message'] ??
              'No payment methods available';
          return ApiResponse.error(errorMessage);
        }
      } else {
        try {
          final responseData =
              json.decode(response.body) as Map<String, dynamic>;
          final errorMessage =
              responseData['Message'] ??
              responseData['message'] ??
              'Failed to get payment methods';
          return ApiResponse.error(
            errorMessage,
            statusCode: response.statusCode,
          );
        } catch (e) {
          return ApiResponse.error(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      print('Error getting payment methods: $e');
      return ApiResponse.error('Request failed: $e');
    }
  }

  // Create payment transaction
  Future<ApiResponse<DuitkuTransactionResponse>> createTransaction({
    required String paymentMethod,
    required int paymentAmount,
    required String customerName,
    required String email,
    required String phoneNumber,
    required String productDetails,
    Map<String, dynamic>? orderData,
  }) async {
    try {
      // Generate unique order ID with current timestamp
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final random = Random().nextInt(9999);
      final merchantOrderId = 'ORDER-$timestamp-$random';

      final signature = _generateTransactionSignature(
        merchantCode: merchantCode,
        paymentAmount: paymentAmount.toString(),
        merchantOrderId: merchantOrderId,
        apiKey: apiKey,
      );

      // Use your API base URL for callbacks
      final callbackUrl = '${ApiConfig.baseUrl}/payment/callback';
      final returnUrl = '${ApiConfig.baseUrl}/payment/return';

      final requestBody = {
        'merchantCode': merchantCode,
        'paymentMethod': paymentMethod,
        'paymentAmount': paymentAmount,
        'merchantOrderId': merchantOrderId,
        'productDetails': productDetails,
        'additionalParam': '',
        'merchantUserInfo': json.encode(orderData ?? {}),
        'customerVaName': customerName,
        'email': email,
        'phoneNumber': phoneNumber,
        'itemDetails': '',
        'customerDetail': '',
        'callbackUrl': callbackUrl,
        'returnUrl': returnUrl,
        'signature': signature,
        'expiryPeriod': 10,
      };

      print('Duitku Transaction Request: ${json.encode(requestBody)}');

      final response = await _client.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('Duitku Transaction Response Status: ${response.statusCode}');
      print('Duitku Transaction Response: ${response.body}');

      final responseData = json.decode(response.body) as Map<String, dynamic>;
      final transactionResponse = DuitkuTransactionResponse.fromJson(
        responseData,
      );

      if (transactionResponse.isSuccess) {
        return ApiResponse.success(transactionResponse);
      } else {
        final errorMessage =
            transactionResponse.statusMessage ??
            responseData['Message'] ??
            'Transaction failed';
        return ApiResponse.error(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      print('Error creating transaction: $e');
      return ApiResponse.error('Transaction failed: $e');
    }
  }

  // Check transaction status
  Future<ApiResponse<Map<String, dynamic>>> checkTransactionStatus({
    required String merchantOrderId,
  }) async {
    try {
      final signature = md5
          .convert(utf8.encode('$merchantCode$merchantOrderId$apiKey'))
          .toString();

      final requestBody = {
        'merchantcode': merchantCode,
        'merchantOrderId': merchantOrderId,
        'signature': signature,
      };

      final response = await _client.post(
        Uri.parse('${baseUrl.replaceAll('/inquiry', '')}/transactionStatus'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      final responseData = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return ApiResponse.success(responseData);
      } else {
        final errorMessage =
            responseData['Message'] ??
            responseData['message'] ??
            'Failed to check status';
        return ApiResponse.error(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Status check failed: $e');
    }
  }
}
