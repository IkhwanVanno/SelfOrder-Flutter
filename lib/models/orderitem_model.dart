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
      id: json['id'] ?? 0,
      kuantitas: json['kuantitas'] ?? 0,
      hargaSatuan: (json['harga_satuan'] ?? 0).toDouble(),
      orderData: null,
      produk: json['produk_nama'] != null
          ? Product(
              id: json['produk_id'] ?? 0,
              name: json['produk_nama'] ?? '',
              description: '',
              price: (json['harga_satuan'] ?? 0).toInt(),
              available: true,
              imageURL: '',
            )
          : null,
    );
  }

  String get displayText {
    if (produk != null) {
      return '${produk!.name} ${kuantitas}x';
    }
    return '${kuantitas}x Item #$id';
  }
}
