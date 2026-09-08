class BankDetails {
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? branchName;

  BankDetails({
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.branchName,
  });

  Map<String, dynamic> toJson() => {
        'bankName': bankName,
        'accountNumber': accountNumber,
        'ifscCode': ifscCode,
        'branchName': branchName,
      };

  factory BankDetails.fromJson(Map<String, dynamic> json) => BankDetails(
        bankName: json['bankName'],
        accountNumber: json['accountNumber'],
        ifscCode: json['ifscCode'],
        branchName: json['branchName'],
      );
}

class LeaveInfo {
  final int totalAnnualLeaves;
  final int consumedLeaves;

  LeaveInfo({
    this.totalAnnualLeaves = 12,
    this.consumedLeaves = 0,
  });

  Map<String, dynamic> toJson() => {
        'totalAnnualLeaves': totalAnnualLeaves,
        'consumedLeaves': consumedLeaves,
      };

  factory LeaveInfo.fromJson(Map<String, dynamic> json) => LeaveInfo(
        totalAnnualLeaves: json['totalAnnualLeaves'] ?? 12,
        consumedLeaves: json['consumedLeaves'] ?? 0,
      );
}

class EmergencyContact {
  final String? name;
  final String? phone;
  final String? relation;

  EmergencyContact({
    this.name,
    this.phone,
    this.relation,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'relation': relation,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
        name: json['name'],
        phone: json['phone'],
        relation: json['relation'],
      );
}

class Teacher {
  final String? id;
  final String name;
  final String gender;
  final String email;
  final String phone;
  final List<String> subjects;
  final String dob;
  final String? photoPath;
  final String? aadhaarFrontPath;
  final String? aadhaarBackPath;
  final String maritalStatus;
  final String address;
  final String dateOfJoining;
  final String department;
  final String qualification;
  final String experience;
  final String status; // active/inactive
  final List<String> classesTeaching;
  final List<String> sections;
  final bool isClassTeacher;
  final String? classTeacherOfClass;
  final String? classTeacherOfSection;
  final double baseSalary;
  final BankDetails? bankDetails;
  final LeaveInfo? leaves;
  final EmergencyContact? emergencyContact;

  Teacher({
    this.id,
    required this.name,
    required this.gender,
    required this.email,
    required this.phone,
    required this.subjects,
    required this.dob,
    this.photoPath,
    this.aadhaarFrontPath,
    this.aadhaarBackPath,
    required this.maritalStatus,
    required this.address,
    required this.dateOfJoining,
    required this.department,
    required this.qualification,
    required this.experience,
    required this.status,
    required this.classesTeaching,
    required this.sections,
    required this.isClassTeacher,
    this.classTeacherOfClass,
    this.classTeacherOfSection,
    this.baseSalary = 0,
    this.bankDetails,
    this.leaves,
    this.emergencyContact,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'gender': gender,
      'email': email,
      'phone': phone,
      'subjects': subjects,
      'dob': dob,
      'photoPath': photoPath,
      'aadhaarFrontPath': aadhaarFrontPath,
      'aadhaarBackPath': aadhaarBackPath,
      'maritalStatus': maritalStatus,
      'address': address,
      'dateOfJoining': dateOfJoining,
      'department': department,
      'qualification': qualification,
      'experience': experience,
      'status': status,
      'classesTeaching': classesTeaching,
      'sections': sections,
      'isClassTeacher': isClassTeacher,
      'classTeacherOfClass': classTeacherOfClass,
      'classTeacherOfSection': classTeacherOfSection,
      'baseSalary': baseSalary,
      'bankDetails': bankDetails?.toJson(),
      'leaves': leaves?.toJson(),
      'emergencyContact': emergencyContact?.toJson(),
    };
  }

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'] ?? json['_id'],
      name: json['name'],
      gender: json['gender'] ?? '',
      email: json['email'],
      phone: json['phone'],
      subjects: List<String>.from(json['subjects'] ?? []),
      dob: json['dob'] ?? '',
      photoPath: json['photoPath'],
      aadhaarFrontPath: json['aadhaarFrontPath'],
      aadhaarBackPath: json['aadhaarBackPath'],
      maritalStatus: json['maritalStatus'] ?? '',
      address: json['address'] ?? '',
      dateOfJoining: json['dateOfJoining'] ?? '',
      department: json['department'] ?? '',
      qualification: json['qualification'] ?? '',
      experience: json['experience'] ?? '',
      status: json['status'] ?? 'active',
      classesTeaching: List<String>.from(json['classesTeaching'] ?? []),
      sections: List<String>.from(json['sections'] ?? []),
      isClassTeacher: json['isClassTeacher'] ?? false,
      classTeacherOfClass: json['classTeacherOfClass'],
      classTeacherOfSection: json['classTeacherOfSection'],
      baseSalary: double.tryParse(json['baseSalary']?.toString() ?? '0') ?? 0.0,
      bankDetails: json['bankDetails'] != null ? BankDetails.fromJson(json['bankDetails']) : null,
      leaves: json['leaves'] != null ? LeaveInfo.fromJson(json['leaves']) : null,
      emergencyContact: json['emergencyContact'] != null ? EmergencyContact.fromJson(json['emergencyContact']) : null,
    );
  }
}
