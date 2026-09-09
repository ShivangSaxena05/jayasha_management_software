class SchoolSettings {
  final String id;
  final String schoolName;
  final String address;
  final String phone;
  final String email;
  final String website;
  final String affiliationNumber;
  final String schoolCode;
  final String? logoPath;
  final String? bannerPath;
  final String? principalSignaturePath;
  final String themeColor;

  SchoolSettings({
    required this.id,
    required this.schoolName,
    required this.address,
    this.phone = '',
    this.email = '',
    this.website = '',
    this.affiliationNumber = '',
    this.schoolCode = '',
    this.logoPath,
    this.bannerPath,
    this.principalSignaturePath,
    this.themeColor = '#0D47A1',
  });

  factory SchoolSettings.fromJson(Map<String, dynamic> json) {
    return SchoolSettings(
      id: json['_id'] ?? '',
      schoolName: json['schoolName'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      website: json['website'] ?? '',
      affiliationNumber: json['affiliationNumber'] ?? '',
      schoolCode: json['schoolCode'] ?? '',
      logoPath: json['logoPath'],
      bannerPath: json['bannerPath'],
      principalSignaturePath: json['principalSignaturePath'],
      themeColor: json['themeColor'] ?? '#0D47A1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schoolName': schoolName,
      'address': address,
      'phone': phone,
      'email': email,
      'website': website,
      'affiliationNumber': affiliationNumber,
      'schoolCode': schoolCode,
      'logoPath': logoPath,
      'bannerPath': bannerPath,
      'principalSignaturePath': principalSignaturePath,
      'themeColor': themeColor,
    };
  }

  SchoolSettings copyWith({
    String? schoolName,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? affiliationNumber,
    String? schoolCode,
    String? logoPath,
    String? bannerPath,
    String? principalSignaturePath,
    String? themeColor,
  }) {
    return SchoolSettings(
      id: id,
      schoolName: schoolName ?? this.schoolName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      affiliationNumber: affiliationNumber ?? this.affiliationNumber,
      schoolCode: schoolCode ?? this.schoolCode,
      logoPath: logoPath ?? this.logoPath,
      bannerPath: bannerPath ?? this.bannerPath,
      principalSignaturePath: principalSignaturePath ?? this.principalSignaturePath,
      themeColor: themeColor ?? this.themeColor,
    );
  }
}
