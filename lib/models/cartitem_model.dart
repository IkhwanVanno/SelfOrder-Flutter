class CartItem {
  final int id;
  final int quantity;
  final int memberId;
  final int productId;

  CartItem({
    required this.id,
    required this.quantity,
    required this.memberId,
    required this.productId,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['ID'],
      quantity: json['Kuantitas'],
      memberId: json['Member']?['ID'] ?? 0,
      productId: json['Produk']?['ID'] ?? 0,
    );
  }
}
