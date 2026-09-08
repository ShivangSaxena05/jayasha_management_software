import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/classes/data/repositories/class_repository.dart';
import 'package:jayasha_childrens_academy/features/classes/data/models/school_class.dart';
import 'package:jayasha_childrens_academy/features/fees/domain/repositories/fee_repository.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';

class FeeStructurePage extends StatefulWidget {
  final VoidCallback onBack;

  const FeeStructurePage({super.key, required this.onBack});

  @override
  State<FeeStructurePage> createState() => _FeeStructurePageState();
}

class _FeeStructurePageState extends State<FeeStructurePage> {
  SchoolClass? selectedClass;
  final Map<String, TextEditingController> _controllers = {
    'Monthly Tuition Fee': TextEditingController(),
    'Annual Admission Fee': TextEditingController(),
    'Examination Fee': TextEditingController(),
  };

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateControllers(SchoolClass? currentClass) {
    if (currentClass == null) return;

    // Default components if none exist
    final components = currentClass.feeStructure;
    _controllers['Monthly Tuition Fee']?.text = (components['Monthly Tuition Fee'] ?? 0.0).toString();
    _controllers['Annual Admission Fee']?.text = (components['Annual Admission Fee'] ?? 0.0).toString();
    _controllers['Examination Fee']?.text = (components['Examination Fee'] ?? 0.0).toString();
  }

  @override
  Widget build(BuildContext context) {
    final classRepo = Provider.of<ClassRepository>(context);
    final feeRepo = Provider.of<FeeRepository>(context, listen: false);
    final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);

    final classes = classRepo.classes;
    if (selectedClass == null && classes.isNotEmpty) {
      selectedClass = classes.first;
      _updateControllers(selectedClass);
    }

    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              ),
              const SizedBox(width: 8),
              const Text(
                'Fee Structure Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Selection Sidebar
                Container(
                  width: 250,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Select Class',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          itemCount: classes.length,
                          itemBuilder: (context, index) {
                            final c = classes[index];
                            final isSelected = selectedClass?.id == c.id;

                            return ListTile(
                              selected: isSelected,
                              selectedTileColor: AppColors.primary.withOpacity(0.1),
                              title: Text(
                                c.name,
                                style: TextStyle(
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  selectedClass = c;
                                  _updateControllers(c);
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 30),
                // Fee Component Editor
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: selectedClass == null
                    ? const Center(child: Text('No classes found. Add classes first.'))
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editing: ${selectedClass!.name}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Adjust the fee components for this class below. Changes will be applied to all students in this class.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 32),
                        ..._controllers.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: SizedBox(
                            width: 400,
                            child: TextField(
                              controller: e.value,
                              decoration: InputDecoration(
                                labelText: e.key,
                                border: const OutlineInputBorder(),
                                prefixText: '₹ ',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        )).toList(),
                        const Spacer(),
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final session = await dashboardRepo.getCurrentSession();
                                if (session == null) return;

                                final List<Map<String, dynamic>> feeData = [
                                  {
                                    'academicSessionId': session.id,
                                    'classId': selectedClass!.id,
                                    'components': _controllers.entries.map((e) => {
                                      'name': e.key,
                                      'amount': double.tryParse(e.value.text) ?? 0.0,
                                      'frequency': e.key.contains('Monthly') ? 'monthly' : 'annually'
                                    }).toList(),
                                  }
                                ];

                                final success = await feeRepo.saveFeeStructure(feeData);
                                if (success) {
                                  // Update local class structure too
                                  final Map<String, double> localFees = {};
                                  _controllers.forEach((key, controller) {
                                    localFees[key] = double.tryParse(controller.text) ?? 0.0;
                                  });
                                  classRepo.updateFeeStructure(selectedClass!.name, localFees);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Fee structure for ${selectedClass!.name} updated successfully!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            TextButton(
                              onPressed: () {
                                _updateControllers(selectedClass);
                                setState(() {});
                              },
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
