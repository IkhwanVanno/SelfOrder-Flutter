import 'package:flutter/material.dart';
import 'package:selforder/models/member_model.dart';
import 'package:selforder/models/payment_model.dart';
import 'package:selforder/theme/app_theme.dart';

enum OrderStatus { menungguPembayaran, dibatalkan, antrean, proses, terkirim }

extension OrderStatusExtension on OrderStatus {
  static OrderStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'menunggupembayaran':
        return OrderStatus.menungguPembayaran;
      case 'dibatalkan':
        return OrderStatus.dibatalkan;
      case 'antrean':
        return OrderStatus.antrean;
      case 'proses':
        return OrderStatus.proses;
      case 'terkirim':
        return OrderStatus.terkirim;
      default:
        return OrderStatus.antrean;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.menungguPembayaran:
        return 'Menunggu Pembayaran';
      case OrderStatus.dibatalkan:
        return 'Dibatalkan';
      case OrderStatus.antrean:
        return 'Antrean';
      case OrderStatus.proses:
        return 'Proses';
      case OrderStatus.terkirim:
        return 'Terkirim';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.menungguPembayaran:
        return AppColors.orange;
      case OrderStatus.dibatalkan:
        return AppColors.red;
      case OrderStatus.antrean:
        return AppColors.grey;
      case OrderStatus.proses:
        return AppColors.blue;
      case OrderStatus.terkirim:
        return AppColors.green;
    }
  }
}

class Order {
  final int id;
  final double totalHarga;
  final double totalHargaBarang;
  final double paymentFee;
  final OrderStatus status;
  final String nomorInvoice;
  final String nomorMeja;
  final DateTime created;
  final Member? member;
  final Payment? payment;

  Order({
    required this.id,
    required this.totalHarga,
    required this.totalHargaBarang,
    required this.paymentFee,
    required this.status,
    required this.nomorInvoice,
    required this.nomorMeja,
    required this.created,
    this.member,
    this.payment,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['ID'],
      totalHarga: (json['TotalHarga'] ?? 0).toDouble(),
      totalHargaBarang: (json['TotalHargaBarang'] ?? 0).toDouble(),
      paymentFee: (json['PaymentFee'] ?? 0).toDouble(),
      status: OrderStatusExtension.fromString(
        (json['Status'] ?? '').toString(),
      ),
      nomorInvoice: (json['NomorInvoice'] ?? '').toString(),
      nomorMeja: (json['NomorMeja'] ?? '').toString(),
      created: DateTime.tryParse(json['Created'] ?? '') ?? DateTime.now(),
      member: json['Member'] != null ? Member.fromJson(json['Member']) : null,
      payment: json['Payment'] != null
          ? Payment.fromJson(json['Payment'])
          : null,
    );
  }
}
