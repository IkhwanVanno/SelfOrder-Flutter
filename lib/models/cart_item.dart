class CartItem {
  final int? id;
  final int productId;
  final String name;
  final String image;
  final int price;
  int quantity;

  CartItem({
    this.id,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      productId: json['productId'] ?? json['ProdukID'] ?? 0,
      name: json['name'] ?? json['ProductName'] ?? '',
      image: json['image'] ?? json['ProductImage'] ?? '',
      price: json['price'] ?? json['Price'] ?? 0,
      quantity: json['quantity'] ?? json['Quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
    };
  }

  Map<String, dynamic> toApiJson() {
    return {
      'ProdukID': productId,
      'ProductName': name,
      'ProductImage': image,
      'Price': price,
      'Quantity': quantity,
    };
  }

  int get totalPrice => price * quantity;

  CartItem copyWith({
    int? id,
    int? productId,
    String? name,
    String? image,
    int? price,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }
}
