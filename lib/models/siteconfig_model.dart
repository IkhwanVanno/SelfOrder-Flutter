class SiteConfig {
  final String title;
  final String tagline;
  final String email;
  final String phone;
  final String address;
  final String companyName;
  final String credit;
  final String imageURL;
  final double biayaReservasi;

  SiteConfig({
    required this.title,
    required this.tagline,
    required this.email,
    required this.phone,
    required this.address,
    required this.companyName,
    required this.credit,
    required this.imageURL,
    this.biayaReservasi = 0,
  });

  factory SiteConfig.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic value) {
      if (value == null) return 0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (e) {
          return 0;
        }
      }
      return 0;
    }

    return SiteConfig(
      title: json['title'] ?? '',
      tagline: json['tagline'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      companyName: json['companyname'] ?? '',
      credit: json['credit'] ?? '',
      imageURL: json['logo_url'] ?? '',
      biayaReservasi: _toDouble(json['biayareservasi']),
    );
  }

  String get formattedBiayaReservasi {
    return 'Rp ${biayaReservasi.toStringAsFixed(0)}/jam';
  }
}
