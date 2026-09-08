class Principal {
  final String name;
  final String dob;
  final String gender;
  final String email;
  final String phone;
  final String address;
  final String qualification;
  final String experience;
  final String maritalStatus;
  final String? photoPath;
  final String? aadhaarFrontPath;
  final String? aadhaarBackPath;

  Principal({
    required this.name,
    required this.dob,
    required this.gender,
    required this.email,
    required this.phone,
    required this.address,
    required this.qualification,
    required this.experience,
    required this.maritalStatus,
    this.photoPath,
    this.aadhaarFrontPath,
    this.aadhaarBackPath,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'dob': dob,
      'gender': gender,
      'email': email,
      'phone': phone,
      'address': address,
      'qualification': qualification,
      'experience': experience,
      'maritalStatus': maritalStatus,
      'photoPath': photoPath,
      'aadhaarFrontPath': aadhaarFrontPath,
      'aadhaarBackPath': aadhaarBackPath,
    };
  }

  factory Principal.fromJson(Map<String, dynamic> json) {
    return Principal(
      name: json['name'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      qualification: json['qualification'] ?? '',
      experience: json['experience'] ?? '',
      maritalStatus: json['maritalStatus'] ?? 'Married',
      photoPath: json['photoPath'],
      aadhaarFrontPath: json['aadhaarFrontPath'],
      aadhaarBackPath: json['aadhaarBackPath'],
    );
  }
}
