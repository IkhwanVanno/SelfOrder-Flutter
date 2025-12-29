class AppVersion {
  final String version;
  final String status;
  final String releaseDate;

  AppVersion({
    required this.version,
    required this.status,
    required this.releaseDate,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version: json['version'] ?? '',
      status: json['status'] ?? '',
      releaseDate: json['release_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'version': version, 'status': status, 'release_date': releaseDate};
  }

  // Helper method untuk compare version
  // Returns: -1 jika currentVersion < serverVersion
  //           0 jika sama
  //           1 jika currentVersion > serverVersion
  static int compareVersions(String currentVersion, String serverVersion) {
    List<int> current = currentVersion.split('.').map(int.parse).toList();
    List<int> server = serverVersion.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (current[i] < server[i]) return -1;
      if (current[i] > server[i]) return 1;
    }
    return 0;
  }
}
