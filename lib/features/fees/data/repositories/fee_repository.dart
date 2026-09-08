import 'package:flutter/foundation.dart';
import '../../../../core/models/student.dart';
import '../../../../core/models/fee_payment.dart';

class FeeRepository extends ChangeNotifier {
  // Mock data for now, will be replaced with real persistence later
  final List<Student> _students = [
    Student(
      id: '1',
      admissionNumber: 'ADM001',
      rollNumber: '101',
      name: 'Aryan Sharma',
      dob: '2013-05-15',
      gender: 'Male',
      classId: 'c1',
      className: 'Class 5',
      fatherName: 'Deepak Sharma',
      motherName: 'Meena Sharma',
      guardianPhone: '9876543210',
      address: '123, Street Name, City',
      admissionDate: '2023-04-01',
      status: 'active',
      academicSessionId: 's1',
      pendingAmount: 2500,
    ),
    Student(
      id: '2',
      admissionNumber: 'ADM002',
      rollNumber: '102',
      name: 'Sneha Gupta',
      dob: '2016-08-20',
      gender: 'Female',
      classId: 'c2',
      className: 'Class 2',
      fatherName: 'Amit Gupta',
      motherName: 'Suman Gupta',
      guardianPhone: '9876543211',
      address: '456, Street Name, City',
      admissionDate: '2023-04-01',
      status: 'active',
      academicSessionId: 's1',
      pendingAmount: 0,
    ),
    Student(
      id: '3',
      admissionNumber: 'ADM003',
      rollNumber: '103',
      name: 'Rahul Verma',
      dob: '2010-02-10',
      gender: 'Male',
      classId: 'c3',
      className: 'Class 8',
      fatherName: 'Sanjay Verma',
      motherName: 'Anita Verma',
      guardianPhone: '9876543212',
      address: '789, Street Name, City',
      admissionDate: '2023-04-01',
      status: 'active',
      academicSessionId: 's1',
      pendingAmount: 4200,
    ),
    Student(
      id: '4',
      admissionNumber: 'ADM004',
      rollNumber: '104',
      name: 'Priya Singh',
      dob: '2013-11-25',
      gender: 'Female',
      classId: 'c1',
      className: 'Class 5',
      fatherName: 'Rajesh Singh',
      motherName: 'Kiran Singh',
      guardianPhone: '9876543213',
      address: '101, Street Name, City',
      admissionDate: '2023-04-01',
      status: 'active',
      academicSessionId: 's1',
      pendingAmount: 1800,
    ),
  ];

  final List<FeePayment> _payments = [];

  List<Student> get students => List.unmodifiable(_students);
  List<FeePayment> get payments => List.unmodifiable(_payments);

  Student? findStudentByRoll(String roll) {
    try {
      return _students.firstWhere((s) => s.rollNumber == roll);
    } catch (e) {
      return null;
    }
  }

  void addPayment(FeePayment payment) {
    _payments.add(payment);

    // Update student pending amount
    final index = _students.indexWhere((s) => s.id == payment.studentId);
    if (index != -1) {
      final student = _students[index];
      double newPending = student.pendingAmount - payment.amount;
      String newStatus = newPending <= 0 ? 'Paid' : 'Pending';

      _students[index] = student.copyWith(
        pendingAmount: newPending < 0 ? 0 : newPending,
        status: newStatus,
      );
    }

    notifyListeners();
  }

  void addStudent(Student student) {
    _students.add(student);
    notifyListeners();
  }

  List<FeePayment> getStudentPayments(String studentId) {
    return _payments.where((p) => p.studentId == studentId).toList();
  }
}
