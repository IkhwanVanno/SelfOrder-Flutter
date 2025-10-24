import 'package:flutter/material.dart';
import 'package:selforder/models/payment_reservation_model.dart';
import 'package:selforder/theme/app_theme.dart';
import 'package:intl/intl.dart';

enum ReservationStatus {
  MenungguPersetujuan,
  Disetujui,
  Ditolak,
  MenungguPembayaran,
  Selesai,
  Dibatalkan,
}

extension ReservationStatusExtension on ReservationStatus {
  static ReservationStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'menunggupersetujuan':
        return ReservationStatus.MenungguPersetujuan;
      case 'disetujui':
        return ReservationStatus.Disetujui;
      case 'ditolak':
        return ReservationStatus.Ditolak;
      case 'menunggupembayaran':
        return ReservationStatus.MenungguPembayaran;
      case 'selesai':
        return ReservationStatus.Selesai;
      case 'dibatalkan':
        return ReservationStatus.Dibatalkan;
      default:
        return ReservationStatus.MenungguPersetujuan;
    }
  }

  String get label {
    switch (this) {
      case ReservationStatus.MenungguPersetujuan:
        return 'Menunggu Persetujuan';
      case ReservationStatus.Disetujui:
        return 'Disetujui';
      case ReservationStatus.Ditolak:
        return 'Ditolak';
      case ReservationStatus.MenungguPembayaran:
        return 'Menunggu Pembayaran';
      case ReservationStatus.Selesai:
        return 'Selesai';
      case ReservationStatus.Dibatalkan:
        return 'Dibatalkan';
    }
  }

  Color get color {
    switch (this) {
      case ReservationStatus.MenungguPersetujuan:
        return AppColors.yellow;
      case ReservationStatus.Disetujui:
        return AppColors.green;
      case ReservationStatus.Ditolak:
        return AppColors.red;
      case ReservationStatus.MenungguPembayaran:
        return AppColors.blue;
      case ReservationStatus.Selesai:
        return AppColors.green;
      case ReservationStatus.Dibatalkan:
        return AppColors.grey;
    }
  }

  IconData get icon {
    switch (this) {
      case ReservationStatus.MenungguPersetujuan:
        return Icons.access_time;
      case ReservationStatus.Disetujui:
        return Icons.check_circle;
      case ReservationStatus.Ditolak:
        return Icons.cancel;
      case ReservationStatus.MenungguPembayaran:
        return Icons.payment;
      case ReservationStatus.Selesai:
        return Icons.check_circle_outline;
      case ReservationStatus.Dibatalkan:
        return Icons.block;
    }
  }
}

class Reservation {
  final int id;
  final String namaReservasi;
  final int jumlahKursi;
  final double totalHarga;
  final DateTime waktuMulai;
  final DateTime waktuSelesai;
  final ReservationStatus status;
  final String catatan;
  final String responsAdmin;
  final DateTime created;
  final PaymentReservation? payment;

  Reservation({
    required this.id,
    required this.namaReservasi,
    required this.jumlahKursi,
    required this.totalHarga,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.status,
    required this.catatan,
    required this.responsAdmin,
    required this.created,
    this.payment,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
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

    return Reservation(
      id: json['id'] ?? 0,
      namaReservasi: (json['nama_reservasi'] ?? '').toString(),
      jumlahKursi: json['jumlah_kursi'] ?? 0,
      totalHarga: _toDouble(json['total_harga']),
      waktuMulai: DateTime.parse(json['waktu_mulai']),
      waktuSelesai: DateTime.parse(json['waktu_selesai']),
      status: ReservationStatusExtension.fromString(json['status'] ?? ''),
      catatan: (json['catatan'] ?? '').toString(),
      responsAdmin: (json['respons_admin'] ?? '').toString(),
      created: DateTime.parse(
        json['created'] ?? DateTime.now().toIso8601String(),
      ),
      payment: json['payment'] != null
          ? PaymentReservation.fromJson(json['payment'])
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

  String get formattedWaktuMulai {
    return DateFormat('dd MMM yyyy, HH:mm').format(waktuMulai);
  }

  String get formattedWaktuSelesai {
    return DateFormat('dd MMM yyyy, HH:mm').format(waktuSelesai);
  }

  String get formattedCreated {
    return DateFormat('dd MMM yyyy, HH:mm').format(created);
  }

  int get durasiJam {
    return waktuSelesai.difference(waktuMulai).inHours;
  }

  bool get canBeCancelled {
    return status == ReservationStatus.MenungguPersetujuan ||
        status == ReservationStatus.Disetujui ||
        status == ReservationStatus.MenungguPembayaran;
  }

  bool get canBePaid {
    return status == ReservationStatus.Disetujui;
  }

  bool get hasPendingPayment {
    return status == ReservationStatus.MenungguPembayaran &&
        payment != null &&
        payment!.paymentUrl.isNotEmpty;
  }

  bool get isCompleted {
    return status == ReservationStatus.Selesai;
  }
}
