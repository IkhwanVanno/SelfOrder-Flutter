import 'package:selforder/models/order_model.dart';
import 'package:selforder/models/product_model.dart';

class OrderItem {
  final int id;
  final int kuantitas;
  final int hargaSatuan;
  final Order? order;
  final Product? produk;

  OrderItem({
    required this.id,
    required this.kuantitas,
    required this.hargaSatuan,
    this.order,
    this.produk,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['ID'],
      kuantitas: json['Kuantitas'],
      hargaSatuan: json['HargaSatuan'],
      order: json['Order'] != null ? Order.fromJson(json['Order']) : null,
      produk: json['Produk'] != null ? Product.fromJson(json['Produk']) : null,
    );
  }
}
