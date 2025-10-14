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

    return OrderItem(
      id: json['id'] ?? 0,
      kuantitas: json['kuantitas'] ?? 0,
      hargaSatuan: _toDouble(json['harga_satuan']),
      orderData: null,
      produk: json['produk_nama'] != null
          ? Product(
              id: json['produk_id'] ?? 0,
              name: json['produk_nama'] ?? '',
              description: '',
              price: (json['harga_satuan'] != null
                  ? int.parse(json['harga_satuan'].toString())
                  : 0),
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
