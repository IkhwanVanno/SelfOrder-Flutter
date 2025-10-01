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
      id: json['id'],
      name: json['nama'],
      imageURL: json['image_url'] ?? '',
    );
  }
}
