class StudentAdmission {
  final String? id;
  final String admissionNumber;
  final String? rollNumber;
  final String name;
  final String dob;
  final String gender;
  final String currentClassId;
  final String? className;
  final String? section;
  final String fatherName;
  final String motherName;
  final String guardianPhone;
  final String address;
  final String admissionDate;
  final String? photoPath;
  final String academicSessionId;

  StudentAdmission({
    this.id,
    required this.admissionNumber,
    this.rollNumber,
    required this.name,
    required this.dob,
    required this.gender,
    required this.currentClassId,
    this.className,
    this.section,
    required this.fatherName,
    required this.motherName,
    required this.guardianPhone,
    required this.address,
    required this.admissionDate,
    this.photoPath,
    required this.academicSessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'admissionNumber': admissionNumber,
      'rollNumber': rollNumber,
      'name': name,
      'dob': dob,
      'gender': gender,
      'currentClass': currentClassId, // Refactored to match backend field 'currentClass'
      'section': section,
      'fatherName': fatherName,
      'motherName': motherName,
      'guardianPhone': guardianPhone,
      'address': address,
      'admissionDate': admissionDate,
      'photoPath': photoPath,
      'academicSession': academicSessionId, // Refactored to match backend field 'academicSession'
    };
  }

  factory StudentAdmission.fromJson(Map<String, dynamic> json) {
    return StudentAdmission(
      id: json['_id'],
      admissionNumber: json['admissionNumber'],
      rollNumber: json['rollNumber'],
      name: json['name'],
      dob: json['dob'],
      gender: json['gender'],
      currentClassId: json['currentClass'] is Map ? json['currentClass']['_id'] : (json['currentClass'] ?? ''),
      className: json['currentClass'] is Map ? json['currentClass']['name'] : null,
      section: json['section'],
      fatherName: json['fatherName'],
      motherName: json['motherName'],
      guardianPhone: json['guardianPhone'] ?? json['phone'] ?? '',
      address: json['address'],
      admissionDate: json['admissionDate'],
      photoPath: json['photoPath'],
      academicSessionId: json['academicSession'] is Map ? json['academicSession']['_id'] : (json['academicSession'] ?? ''),
    );
  }

  StudentAdmission copyWith({
    String? id,
    String? admissionNumber,
    String? rollNumber,
    String? name,
    String? dob,
    String? gender,
    String? currentClassId,
    String? className,
    String? section,
    String? fatherName,
    String? motherName,
    String? guardianPhone,
    String? address,
    String? admissionDate,
    String? photoPath,
    String? academicSessionId,
  }) {
    return StudentAdmission(
      id: id ?? this.id,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      rollNumber: rollNumber ?? this.rollNumber,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      currentClassId: currentClassId ?? this.currentClassId,
      className: className ?? this.className,
      section: section ?? this.section,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      address: address ?? this.address,
      admissionDate: admissionDate ?? this.admissionDate,
      photoPath: photoPath ?? this.photoPath,
      academicSessionId: academicSessionId ?? this.academicSessionId,
    );
  }
}
