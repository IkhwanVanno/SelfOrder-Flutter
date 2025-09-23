// models/payment_model.dart
enum PaymentStatus { pending, completed, expired, failed, unknown }

extension PaymentStatusExtension on PaymentStatus {
  static PaymentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
        return PaymentStatus.completed;
      case 'expired':
        return PaymentStatus.expired;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.expired:
        return 'Expired';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.unknown:
        return 'Pending';
    }
  }
}

class Payment {
  final int id;
  final String reference;
  final double totalHarga;
  final PaymentStatus status;
  final String metodePembayaran;
  final String duitkuTransactionId;
  final String paymentUrl;
  final DateTime expiryTime;
  final DateTime created;
  final DateTime updated;

  Payment({
    required this.id,
    required this.reference,
    required this.totalHarga,
    required this.status,
    required this.metodePembayaran,
    required this.duitkuTransactionId,
    required this.paymentUrl,
    required this.expiryTime,
    required this.created,
    required this.updated,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['ID'],
      reference: (json['Reference'] ?? '').toString(),
      totalHarga: (json['TotalHarga'] ?? 0).toDouble(),
      status: PaymentStatusExtension.fromString(json['Status'] ?? ''),
      metodePembayaran: (json['MetodePembayaran'] ?? '').toString(),
      duitkuTransactionId: (json['DuitkuTransactionID'] ?? '').toString(),
      paymentUrl: (json['PaymentUrl'] ?? '').toString(),
      expiryTime: DateTime.tryParse(json['ExpiryTime'] ?? '') ?? DateTime.now(),
      created: DateTime.tryParse(json['Created'] ?? '') ?? DateTime.now(),
      updated: DateTime.tryParse(json['Updated'] ?? '') ?? DateTime.now(),
    );
  }
}
