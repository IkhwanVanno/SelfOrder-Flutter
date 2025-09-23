class Group {
  final int id;
  final String title;
  final String code;

  Group({required this.id, required this.title, required this.code});

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['ID'],
      title: json['Title'] ?? '',
      code: json['Code'] ?? '',
    );
  }
}

class Member {
  final int id;
  final String firstName;
  final String surname;
  final String email;
  final String? tempIDHash;
  final DateTime? tempIDExpired;
  final List<Group> groups;

  Member({
    required this.id,
    required this.firstName,
    required this.surname,
    required this.email,
    this.tempIDHash,
    this.tempIDExpired,
    required this.groups,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['ID'],
      firstName: json['FirstName'] ?? '',
      surname: json['Surname'] ?? '',
      email: json['Email'] ?? '',
      tempIDHash: json['TempIDHash'],
      tempIDExpired: json['TempIDExpired'] != null
          ? DateTime.tryParse(json['TempIDExpired'])
          : null,
      groups:
          (json['Groups'] as List<dynamic>?)
              ?.map((g) => Group.fromJson(g))
              .toList() ??
          [],
    );
  }

  String get fullName => '$firstName $surname';
}
