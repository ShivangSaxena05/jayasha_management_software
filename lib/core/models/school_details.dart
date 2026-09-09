class SchoolDetails {
  final String id;
  final String schoolName;
  final String address;
  final String phone;
  final String email;
  final String affiliationLine;
  final String logoUrl;
  final String principalSignatureLabel;

  SchoolDetails({
    required this.id,
    required this.schoolName,
    required this.address,
    required this.phone,
    required this.email,
    required this.affiliationLine,
    required this.logoUrl,
    required this.principalSignatureLabel,
  });

  factory SchoolDetails.fromJson(Map<String, dynamic> json) {
    return SchoolDetails(
      id: json['_id'] ?? '',
      schoolName: json['schoolName'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      affiliationLine: json['affiliationLine'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
      principalSignatureLabel: json['principalSignatureLabel'] ?? 'Principal Signature',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schoolName': schoolName,
      'address': address,
      'phone': phone,
      'email': email,
      'affiliationLine': affiliationLine,
      'logoUrl': logoUrl,
      'principalSignatureLabel': principalSignatureLabel,
    };
  }

  SchoolDetails copyWith({
    String? id,
    String? schoolName,
    String? address,
    String? phone,
    String? email,
    String? affiliationLine,
    String? logoUrl,
    String? principalSignatureLabel,
  }) {
    return SchoolDetails(
      id: id ?? this.id,
      schoolName: schoolName ?? this.schoolName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      affiliationLine: affiliationLine ?? this.affiliationLine,
      logoUrl: logoUrl ?? this.logoUrl,
      principalSignatureLabel: principalSignatureLabel ?? this.principalSignatureLabel,
    );
  }
}
