import 'package:intl/intl.dart';

enum PaymentStatus { pending, completed, expired, failed, unknown }

extension PaymentStatusExtension on PaymentStatus {
  static PaymentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
      case 'success':
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
        return 'Menunggu Pembayaran';
      case PaymentStatus.completed:
        return 'Berhasil';
      case PaymentStatus.expired:
        return 'Kadaluarsa';
      case PaymentStatus.failed:
        return 'Gagal';
      case PaymentStatus.unknown:
        return 'Tidak Diketahui';
    }
  }
}

class PaymentReservation {
  final int id;
  final String reference;
  final double totalHarga;
  final PaymentStatus status;
  final String metodePembayaran;
  final String paymentUrl;
  final DateTime? expiryTime;

  PaymentReservation({
    required this.id,
    required this.reference,
    required this.totalHarga,
    required this.status,
    required this.metodePembayaran,
    required this.paymentUrl,
    this.expiryTime,
  });

  factory PaymentReservation.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return 0.0;
        }
      }
      return 0.0;
    }

    return PaymentReservation(
      id: json['id'] ?? 0,
      reference: (json['reference'] ?? '').toString(),
      totalHarga: _toDouble(json['total_harga']),
      status: PaymentStatusExtension.fromString(json['status'] ?? ''),
      metodePembayaran: (json['metode_pembayaran'] ?? '').toString(),
      paymentUrl: (json['paymenturl'] ?? json['payment_url'] ?? '').toString(),
      expiryTime: json['expiry_time'] != null
          ? DateTime.tryParse(json['expiry_time'])
          : null,
    );
  }

  String get formattedTotal {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(totalHarga);
  }

  String get formattedExpiryTime {
    if (expiryTime == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(expiryTime!);
  }

  bool get isExpired {
    if (expiryTime == null) return false;
    return DateTime.now().isAfter(expiryTime!);
  }

  bool get isPending {
    return status == PaymentStatus.pending && !isExpired;
  }

  bool get isCompleted {
    return status == PaymentStatus.completed;
  }
}
