import 'package:selforder/models/product_model.dart';

class OrderItem {
  final int id;
  final int kuantitas;
  final double hargaSatuan;
  final Map<String, dynamic>? orderData;
  final Product? produk;

  OrderItem({
    required this.id,
    required this.kuantitas,
    required this.hargaSatuan,
    this.orderData,
    this.produk,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['ID'] ?? 0,
      kuantitas: json['Kuantitas'] ?? 0,
      hargaSatuan: (json['HargaSatuan'] ?? 0).toDouble(),
      orderData: json['Order'],
      produk: json['Produk'] != null ? Product.fromJson(json['Produk']) : null,
    );
  }

  String get displayText {
    if (produk != null) {
      return '${produk!.name} ${kuantitas}x';
    }
    return '${kuantitas}x Item #$id';
  }
}
