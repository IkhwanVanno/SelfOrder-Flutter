class SiteConfig {
  final String title;
  final String tagline;
  final String email;
  final String phone;
  final String address;
  final String companyName;
  final String credit;
  final String imageURL;

  SiteConfig({
    required this.title,
    required this.tagline,
    required this.email,
    required this.phone,
    required this.address,
    required this.companyName,
    required this.credit,
    required this.imageURL,
  });

  factory SiteConfig.fromJson(Map<String, dynamic> json) {
    return SiteConfig(
      title: json['title'] ?? '',
      tagline: json['tagline'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      companyName: json['companyname'] ?? '',
      credit: json['credit'] ?? '',
      imageURL: json['logo_url'] ?? '',
    );
  }
}
