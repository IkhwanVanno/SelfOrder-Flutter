class Product {
  final int id;
  final String name;
  final String description;
  final int price;
  final bool available;
  final String imageURL;
  final int? categoryId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.available,
    required this.imageURL,
    this.categoryId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['ID'],
      name: json['Nama'],
      description: json['Deskripsi'] ?? '',
      price: json['Harga'],
      available: json['Status'] == 'Aktif',
      imageURL: json['Image']?['URL'] ?? '',
      categoryId: json['Kategori']?['ID'],
    );
  }
}
