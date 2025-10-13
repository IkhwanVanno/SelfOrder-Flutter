class CartItem {
  final int id;
  final int quantity;
  final int productId;

  CartItem({required this.id, required this.quantity, required this.productId});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] ?? 0,
      quantity: json['kuantitas'] ?? 0,
      productId: json['produk_id'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'kuantitas': quantity, 'produk_id': productId};
  }

  // Helper method untuk membuat copy dengan perubahan
  CartItem copyWith({int? id, int? quantity, int? productId}) {
    return CartItem(
      id: id ?? this.id,
      quantity: quantity ?? this.quantity,
      productId: productId ?? this.productId,
    );
  }
}
