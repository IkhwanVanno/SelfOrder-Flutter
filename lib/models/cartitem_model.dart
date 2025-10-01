class CartItem {
  final int id;
  final int quantity;
  final int productId;

  CartItem({required this.id, required this.quantity, required this.productId});

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      quantity: json['kuantitas'],
      productId: json['produk_id'],
    );
  }
}
