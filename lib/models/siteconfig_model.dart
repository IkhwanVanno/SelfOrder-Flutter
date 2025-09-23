class SiteConfig {
  final int id;
  final String email;
  final String phone;
  final String address;
  final String companyName;
  final String credit;
  final String title;
  final String imageURL;

  SiteConfig({
    required this.id,
    required this.email,
    required this.phone,
    required this.address,
    required this.companyName,
    required this.credit,
    required this.title,
    required this.imageURL,
  });

  factory SiteConfig.fromJson(Map<String, dynamic> json) {
    return SiteConfig(
      id: json['ID'],
      email: json['Email'],
      phone: json['Phone'],
      address: json['Address'],
      companyName: json['CompanyName'],
      credit: json['Credit'],
      title: json['Title'],
      imageURL: json['Image']?['URL'] ?? '',
    );
  }
}
