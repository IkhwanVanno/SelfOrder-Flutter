class CategoryProduct {
  final int id;
  final String name;
  final String imageURL;

  CategoryProduct({
    required this.id,
    required this.name,
    required this.imageURL,
  });

  factory CategoryProduct.fromJson(Map<String, dynamic> json) {
    return CategoryProduct(
      id: json['ID'],
      name: json['Nama'],
      imageURL: json['Image']?['URL'] ?? '',
    );
  }
}
