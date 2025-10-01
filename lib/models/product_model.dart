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
      id: json['id'], 
      name: json['nama'], 
      description: json['deskripsi'] ?? '', 
      price: json['harga'], 
      available: json['status'] == 'Aktif', 
      imageURL: json['image_url'] ?? '', 
      categoryId: json['kategori_id'], 
    );
  }
}
