class Student {
  final String id;
  final String admissionNumber;
  final String? rollNumber;
  final String name;
  final String dob;
  final String gender;
  final String classId;
  final String? className;
  final String? section;
  final String fatherName;
  final String motherName;
  final String guardianPhone;
  final String address;
  final String admissionDate;
  final String? photoPath;
  final String status;
  final String academicSessionId;
  final double pendingAmount;

  Student({
    required this.id,
    required this.admissionNumber,
    this.rollNumber,
    required this.name,
    required this.dob,
    required this.gender,
    required this.classId,
    this.className,
    this.section,
    required this.fatherName,
    required this.motherName,
    required this.guardianPhone,
    required this.address,
    required this.admissionDate,
    this.photoPath,
    required this.status,
    required this.academicSessionId,
    this.pendingAmount = 0.0,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['_id'] ?? json['id'] ?? '',
      admissionNumber: json['admissionNumber'] ?? '',
      rollNumber: json['rollNumber'],
      name: json['name'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      classId: json['currentClass'] is Map
          ? json['currentClass']['_id']
          : (json['currentClass'] ?? ''),
      className: json['currentClass'] is Map
          ? json['currentClass']['name']
          : json['className'],
      section: json['section'],
      fatherName: json['fatherName'] ?? '',
      motherName: json['motherName'] ?? '',
      guardianPhone: json['guardianPhone'] ?? json['contact'] ?? '',
      address: json['address'] ?? '',
      admissionDate: json['admissionDate'] ?? '',
      photoPath: json['photoPath'],
      status: json['status'] ?? 'active',
      academicSessionId: json['academicSession'] is Map
          ? json['academicSession']['_id']
          : (json['academicSession'] ?? ''),
      pendingAmount: double.tryParse(json['pendingAmount']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'admissionNumber': admissionNumber,
      'rollNumber': rollNumber,
      'name': name,
      'dob': dob,
      'gender': gender,
      'currentClass': classId,
      'section': section,
      'fatherName': fatherName,
      'motherName': motherName,
      'guardianPhone': guardianPhone,
      'address': address,
      'admissionDate': admissionDate,
      'photoPath': photoPath,
      'status': status,
      'academicSession': academicSessionId,
      'pendingAmount': pendingAmount,
    };
  }

  Student copyWith({
    String? id,
    String? admissionNumber,
    String? rollNumber,
    String? name,
    String? dob,
    String? gender,
    String? classId,
    String? className,
    String? section,
    String? fatherName,
    String? motherName,
    String? guardianPhone,
    String? address,
    String? admissionDate,
    String? photoPath,
    String? status,
    String? academicSessionId,
    double? pendingAmount,
  }) {
    return Student(
      id: id ?? this.id,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      rollNumber: rollNumber ?? this.rollNumber,
      name: name ?? this.name,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      classId: classId ?? this.classId,
      className: className ?? this.className,
      section: section ?? this.section,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      address: address ?? this.address,
      admissionDate: admissionDate ?? this.admissionDate,
      photoPath: photoPath ?? this.photoPath,
      status: status ?? this.status,
      academicSessionId: academicSessionId ?? this.academicSessionId,
      pendingAmount: pendingAmount ?? this.pendingAmount,
    );
  }
}
