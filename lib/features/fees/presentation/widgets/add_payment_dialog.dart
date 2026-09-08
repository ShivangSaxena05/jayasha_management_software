import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/core/models/fee_payment.dart';
import 'package:jayasha_childrens_academy/features/fees/domain/repositories/fee_repository.dart';
import 'package:jayasha_childrens_academy/features/students/domain/repositories/student_repository.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:jayasha_childrens_academy/features/exams/data/repositories/exam_repository.dart';
import 'package:jayasha_childrens_academy/core/models/academic_session.dart';
import 'package:jayasha_childrens_academy/core/utils/pdf_generator.dart';
import 'package:collection/collection.dart';

void showAddPaymentDialog(BuildContext context, {
  StudentAdmission? prefilledStudent,
  String? prefilledCategory,
  VoidCallback? onSuccess
}) async {
  final feeRepo = Provider.of<FeeRepository>(context, listen: false);
  final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);
  final examRepo = Provider.of<ExamRepository>(context, listen: false);
  final studentRepo = Provider.of<StudentRepository>(context, listen: false);

  AcademicSession? currentSession;
  List<dynamic> feeStructures = [];
  List<dynamic> exams = [];

  try {
    currentSession = await dashboardRepo.getCurrentSession();
    if (currentSession != null) {
      feeStructures = await feeRepo.getFeeStructures();
      final examResponse = await examRepo.getExams(currentSession.id!);
      if (examResponse['success'] == true) {
        exams = examResponse['data'] ?? [];
      }
    }
  } catch (e) {
    debugPrint('Error preparing payment dialog: $e');
  }

  if (currentSession == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active academic session found'), backgroundColor: Colors.red),
      );
    }
    return;
  }

  final TextEditingController admNoController = TextEditingController(text: prefilledStudent?.admissionNumber);
  final TextEditingController amountController = TextEditingController();
  StudentAdmission? foundStudent = prefilledStudent;
  PaymentMode selectedMode = PaymentMode.cash;
  bool _isInitialLoad = true;

  FeeCategory selectedCategory = FeeCategory.monthly;
  if (prefilledCategory != null) {
    if (prefilledCategory.toLowerCase().contains('admission')) {
      selectedCategory = FeeCategory.admission;
    } else if (prefilledCategory.toLowerCase().contains('exam')) {
      selectedCategory = FeeCategory.exam;
    } else if (prefilledCategory.toLowerCase().contains('annual')) {
      selectedCategory = FeeCategory.annual;
    }
  }

  bool isFullPayment = true;
  bool isAdvanceMode = false;
  List<String> selectedMonths = [];
  List<String> alreadyPaidMonths = [];
  List<String> applicableMonths = [];
  List<FeeCategory> pendingCategories = [];
  String? selectedExamId;

  final List<String> months = [
    'April', 'May', 'June', 'July', 'August', 'September',
    'October', 'November', 'December', 'January', 'February', 'March'
  ];

  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        // Fetch student fee status when student is found/changed
        Future<void> fetchStudentFeeInfo(String studentId) async {
          try {
            final status = await feeRepo.getStudentFeeStatus(studentId);
            final payments = await feeRepo.getStudentPayments(studentId);

            // Extract already paid months for monthly category
            final paid = payments
              .where((p) => p.category == FeeCategory.monthly)
              .expand((p) => p.paidMonths)
              .toList();

            // Extract applicable months from structure
            List<String> applicable = [];
            final classStructure = feeStructures.firstWhereOrNull(
              (s) => s['class'] != null && (s['class']['_id'] == foundStudent!.currentClassId || s['class'] == foundStudent!.currentClassId),
            );
            if (classStructure != null && classStructure['components'] != null) {
              final monthlyComp = (classStructure['components'] as List).where((c) =>
                c['name'].toString().toLowerCase().contains('monthly') ||
                c['name'].toString().toLowerCase().contains('tuition')).firstOrNull;
              if (monthlyComp != null && monthlyComp['applicableMonths'] != null) {
                applicable = List<String>.from(monthlyComp['applicableMonths']);
              }
            }

            // Determine pending categories (simple version based on total paid vs expected)
            List<FeeCategory> pending = [];
            if (classStructure != null && classStructure['components'] != null) {
              final components = classStructure['components'] as List;
              final elapsedMonthsList = _getElapsedMonths(currentSession!.startDate);

              for (var comp in components) {
                String name = comp['name'].toString().toLowerCase();
                FeeCategory cat = FeeCategory.other;
                if (name.contains('monthly')) cat = FeeCategory.monthly;
                else if (name.contains('admission')) cat = FeeCategory.admission;
                else if (name.contains('exam')) cat = FeeCategory.exam;
                else if (name.contains('annual')) cat = FeeCategory.annual;

                double expected = 0;
                if (cat == FeeCategory.monthly) {
                  final dueMonths = List<String>.from(comp['applicableMonths'] ?? [])
                      .where((m) => elapsedMonthsList.contains(m)).toList();
                  expected = (double.tryParse(comp['amount'].toString()) ?? 0) * dueMonths.length;
                } else {
                  expected = double.tryParse(comp['amount'].toString()) ?? 0;
                }

                double paidForCat = payments
                    .where((p) => p.category == cat)
                    .fold(0.0, (sum, p) => sum + p.amount);

                if (paidForCat < expected) {
                  pending.add(cat);
                }
              }
            }

            setDialogState(() {
              alreadyPaidMonths = paid;
              applicableMonths = applicable;
              pendingCategories = pending;
              // If current category is not pending, switch to first pending one
              if (pending.isNotEmpty && !pending.contains(selectedCategory)) {
                selectedCategory = pending.first;
              }
            });
          } catch (e) {
            debugPrint('Error fetching student fee info: $e');
          }
        }

        // Initial fetch if student prefilled
        if (foundStudent != null && applicableMonths.isEmpty && _isInitialLoad) {
          _isInitialLoad = false;
          fetchStudentFeeInfo(foundStudent!.id!);
        }

        // Helper to get base amount from structure
        double getBaseAmount(FeeCategory category) {
          if (foundStudent == null) return 0.0;
          final classStructure = feeStructures.firstWhereOrNull(
            (s) => s['class'] != null && (s['class']['_id'] == foundStudent!.currentClassId || s['class'] == foundStudent!.currentClassId),
          );

          if (classStructure != null && classStructure['components'] != null) {
            final components = classStructure['components'] as List;
            dynamic component;

            switch (category) {
              case FeeCategory.monthly:
                component = components.where((c) =>
                  c['name'].toString().toLowerCase().contains('monthly') ||
                  c['name'].toString().toLowerCase().contains('tuition')).firstOrNull;
                break;
              case FeeCategory.admission:
                component = components.where((c) =>
                  c['name'].toString().toLowerCase().contains('admission')).firstOrNull;
                break;
              case FeeCategory.exam:
                component = components.where((c) =>
                  c['name'].toString().toLowerCase().contains('exam')).firstOrNull;
                break;
              case FeeCategory.annual:
                component = components.where((c) =>
                  c['name'].toString().toLowerCase().contains('annual')).firstOrNull;
                break;
              default:
                break;
            }

            if (component != null) {
              double unitAmount = double.tryParse(component['amount'].toString()) ?? 0.0;
              if (category == FeeCategory.monthly) {
                return unitAmount * (selectedMonths.isEmpty ? 1 : selectedMonths.length);
              }
              return unitAmount;
            }
          }
          return 0.0;
        }

        void updateAmount() {
          if (isFullPayment) {
            amountController.text = getBaseAmount(selectedCategory).toString();
          }
        }

        // Initial amount update if student is prefilled
        if (foundStudent != null && amountController.text.isEmpty && isFullPayment) {
          updateAmount();
        }

        final totalFee = getBaseAmount(selectedCategory);
        final enteredAmount = double.tryParse(amountController.text) ?? 0.0;
        final dueAmount = totalFee - enteredAmount;

        return AlertDialog(
          title: const Text('Add Fee Payment'),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: admNoController,
                    decoration: InputDecoration(
                      labelText: 'Admission Number',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () async {
                          try {
                            final results = await studentRepo.getStudents(admissionNumber: admNoController.text);
                            if (results.isNotEmpty) {
                              setDialogState(() {
                                foundStudent = results.first;
                                updateAmount();
                              });
                              await fetchStudentFeeInfo(foundStudent!.id!);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Student not found')),
                                );
                              }
                            }
                          } catch (e) {
                            debugPrint('Error searching student: $e');
                          }
                        },
                      ),
                    ),
                    onSubmitted: (val) async {
                      try {
                        final results = await studentRepo.getStudents(admissionNumber: val);
                        if (results.isNotEmpty) {
                          setDialogState(() {
                            foundStudent = results.first;
                            updateAmount();
                          });
                          await fetchStudentFeeInfo(foundStudent!.id!);
                        }
                      } catch (e) {
                        debugPrint('Error searching student on submit: $e');
                      }
                    },
                  ),
                  if (foundStudent != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          _buildDialogInfoRow('Student', foundStudent!.name, isBold: true),
                          _buildDialogInfoRow('Class', '${foundStudent!.className ?? 'N/A'} ${foundStudent!.section ?? ''}'),
                          _buildDialogInfoRow('Father', foundStudent!.fatherName),
                          _buildDialogInfoRow('Roll No', foundStudent!.rollNumber ?? 'N/A'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<FeeCategory>(
                      value: selectedCategory,
                      items: FeeCategory.values.map((e) {
                        final isPending = pendingCategories.contains(e);
                        return DropdownMenuItem(
                          value: e,
                          child: Text(
                            '${e.name.toUpperCase()}${isPending ? " (PENDING)" : ""}',
                            style: TextStyle(
                              color: isPending ? Colors.red.shade700 : null,
                              fontWeight: isPending ? FontWeight.bold : null,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedCategory = val;
                            updateAmount();
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    if (selectedCategory == FeeCategory.monthly) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Select Months', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Row(
                            children: [
                              const Text('Advance', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Transform.scale(
                                scale: 0.7,
                                child: Switch(
                                  value: isAdvanceMode,
                                  onChanged: (val) {
                                    setDialogState(() {
                                      isAdvanceMode = val;
                                      // If turning off advance, remove future months from selection
                                      if (!isAdvanceMode) {
                                        final elapsed = _getElapsedMonths(currentSession!.startDate);
                                        selectedMonths.removeWhere((m) => !elapsed.contains(m));
                                        updateAmount();
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: months.map((m) {
                          final isSelected = selectedMonths.contains(m);
                          final isAlreadyPaid = alreadyPaidMonths.contains(m);
                          final isApplicable = applicableMonths.contains(m);
                          final elapsedMonths = _getElapsedMonths(currentSession!.startDate);
                          final isElapsed = elapsedMonths.contains(m);

                          // Logic: Enabled if applicable AND (is past month OR advance mode is ON) AND not already paid
                          final bool isEnabled = isApplicable && (isElapsed || isAdvanceMode) && !isAlreadyPaid;

                          return FilterChip(
                            label: Text(m, style: TextStyle(
                              fontSize: 12,
                              color: isAlreadyPaid ? Colors.green.shade700 : (isEnabled ? null : Colors.grey.shade400)
                            )),
                            selected: isSelected || isAlreadyPaid,
                            onSelected: isEnabled ? (selected) {
                              setDialogState(() {
                                if (selected) {
                                  selectedMonths.add(m);
                                } else {
                                  selectedMonths.remove(m);
                                }
                                updateAmount();
                              });
                            } : null,
                            selectedColor: isAlreadyPaid ? Colors.green.withOpacity(0.1) : AppColors.primary.withOpacity(0.2),
                            checkmarkColor: isAlreadyPaid ? Colors.green : AppColors.primary,
                            avatar: isAlreadyPaid ? const Icon(Icons.check, size: 14, color: Colors.green) : null,
                            padding: EdgeInsets.zero,
                            shape: isAlreadyPaid ? const StadiumBorder(side: BorderSide(color: Colors.green, width: 0.5)) : null,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (selectedCategory == FeeCategory.exam) ...[
                      DropdownButtonFormField<String>(
                        value: selectedExamId,
                        hint: const Text('Select Exam'),
                        items: exams.map((e) => DropdownMenuItem(value: e['_id'].toString(), child: Text(e['name']))).toList(),
                        onChanged: (val) => setDialogState(() => selectedExamId = val),
                        decoration: const InputDecoration(labelText: 'Exam', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text('Payment Option', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Full'),
                            value: true,
                            groupValue: isFullPayment,
                            onChanged: (val) => setDialogState(() {
                              isFullPayment = val!;
                              updateAmount();
                            }),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Partial'),
                            value: false,
                            groupValue: isFullPayment,
                            onChanged: (val) => setDialogState(() => isFullPayment = val!),
                          ),
                        ),
                      ],
                    ),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      readOnly: isFullPayment,
                      decoration: InputDecoration(
                        labelText: isFullPayment ? 'Amount (Calculated)' : 'Enter Amount to Pay',
                        border: const OutlineInputBorder(),
                        filled: isFullPayment,
                        fillColor: isFullPayment ? Colors.grey.shade100 : null,
                        suffixIcon: isFullPayment ? const Icon(Icons.lock_outline, size: 20) : null,
                      ),
                      onChanged: (val) => setDialogState(() {}),
                    ),
                    if (!isFullPayment) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Expected: ₹$totalFee', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text('Difference: ₹${dueAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: dueAmount > 0 ? Colors.orange : (dueAmount < 0 ? Colors.blue : Colors.green)
                            )
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    DropdownButtonFormField<PaymentMode>(
                      value: selectedMode,
                      items: PaymentMode.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name.toUpperCase()))).toList(),
                      onChanged: (val) => setDialogState(() => selectedMode = val!),
                      decoration: const InputDecoration(labelText: 'Mode', border: OutlineInputBorder()),
                    ),
                  ]
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            if (foundStudent != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                onPressed: () async {
                  try {
                    final amount = double.tryParse(amountController.text) ?? 0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
                      return;
                    }
                    if (selectedCategory == FeeCategory.monthly && selectedMonths.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one month')));
                      return;
                    }

                    String remarks = isFullPayment ? 'Full Payment' : 'Partial Payment';
                    if (selectedCategory == FeeCategory.monthly) {
                      remarks += ' - Months: ${selectedMonths.join(', ')}';
                    }

                    final payment = FeePayment(
                      studentId: foundStudent!.id!,
                      academicSessionId: currentSession!.id!,
                      amount: amount,
                      date: DateTime.now(),
                      mode: selectedMode,
                      category: selectedCategory,
                      paidMonths: selectedMonths,
                      remarks: remarks,
                    );

                    final success = await feeRepo.recordPayment(payment);
                    if (success && context.mounted) {
                      Provider.of<DashboardRepository>(context, listen: false).getDashboardStats();
                      Navigator.pop(context);
                      if (onSuccess != null) onSuccess();

                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Payment Successful'),
                          content: Text('₹$amount recorded for ${foundStudent!.name}.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                            ElevatedButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                await PdfGenerator.downloadFeeReceipt(
                                  student: foundStudent!,
                                  payment: payment,
                                  sessionName: currentSession!.sessionName,
                                );
                              },
                              child: const Text('Download Receipt'),
                            ),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Error recording payment: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to record payment: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
                child: const Text('Submit'),
              )
          ],
        );
      },
    ),
  );
}

Widget _buildDialogInfoRow(String label, String value, {bool isBold = false, Color? valueColor}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        Text(value, style: TextStyle(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          color: valueColor ?? AppColors.textPrimary,
        )),
      ],
    ),
  );
}

List<String> _getElapsedMonths(String sessionStartDate) {
  try {
    final start = DateTime.parse(sessionStartDate);
    final end = DateTime.now();
    final List<String> elapsed = [];
    final monthNames = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];

    DateTime current = DateTime(start.year, start.month, 1);
    DateTime stop = DateTime(end.year, end.month, 1);

    int count = 0;
    while (!current.isAfter(stop) && count < 12) {
      elapsed.add(monthNames[current.month - 1]);
      current = DateTime(current.year, current.month + 1, 1);
      count++;
    }
    return elapsed;
  } catch (e) {
    debugPrint('Error calculating elapsed months: $e');
    return [];
  }
}
