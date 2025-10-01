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
  final String paymentUrl;
  final DateTime? expiryTime;

  Payment({
    required this.id,
    required this.reference,
    required this.totalHarga,
    required this.status,
    required this.metodePembayaran,
    required this.paymentUrl,
    this.expiryTime,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? 0,
      reference: (json['reference'] ?? '').toString(),
      totalHarga: (json['total_harga'] ?? 0).toDouble(),
      status: PaymentStatusExtension.fromString(json['status'] ?? ''),
      metodePembayaran: (json['metode_pembayaran'] ?? '').toString(),
      paymentUrl: (json['paymenturl'] ?? json['payment_url'] ?? '').toString(),
      expiryTime: json['expiry_time'] != null
          ? DateTime.tryParse(json['expiry_time'])
          : null,
    );
  }
}
