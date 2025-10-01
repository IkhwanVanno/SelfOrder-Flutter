import 'package:flutter/material.dart';
import 'package:selforder/models/member_model.dart';
import 'package:selforder/models/payment_model.dart';
import 'package:selforder/models/orderitem_model.dart';
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
  final List<OrderItem> orderItems;

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
    this.orderItems = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<OrderItem> items = [];
    if (json['items'] != null && json['items'] is List) {
      try {
        final List itemsJson = json['items'];
        items = itemsJson.map((item) => OrderItem.fromJson(item)).toList();
      } catch (e) {
        items = [];
      }
    }

    return Order(
      id: json['id'],
      totalHarga: (json['total_harga'] ?? 0).toDouble(),
      totalHargaBarang: (json['total_harga_barang'] ?? 0)
          .toDouble(),
      paymentFee: (json['payment_fee'] ?? 0).toDouble(),
      status: OrderStatusExtension.fromString(
        (json['status'] ?? '').toString(),
      ),
      nomorInvoice: (json['nomor_invoice'] ?? '').toString(),
      nomorMeja: (json['nomor_meja'] ?? '').toString(),
      created: DateTime.tryParse(json['created'] ?? '') ?? DateTime.now(),
      member: null,
      payment: json['payment'] != null
          ? Payment.fromJson(json['payment'])
          : null,
      orderItems: items,
    );
  }
}
