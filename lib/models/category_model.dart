class CategoryItem {
  final int id;
  final String name;
  final String imageURL;

  CategoryItem({required this.id, required this.name, required this.imageURL});

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['ID'],
      name: json['Nama'],
      imageURL: json['Image']?['URL'] ?? '',
    );
  }
}
