import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/classes/data/repositories/class_repository.dart';
import 'package:jayasha_childrens_academy/features/classes/data/models/school_class.dart';
import 'package:jayasha_childrens_academy/features/fees/domain/repositories/fee_repository.dart';
import 'package:jayasha_childrens_academy/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:jayasha_childrens_academy/features/fees/data/models/fee_structure.dart';

class FeeStructurePage extends StatefulWidget {
  final VoidCallback onBack;

  const FeeStructurePage({super.key, required this.onBack});

  @override
  State<FeeStructurePage> createState() => _FeeStructurePageState();
}

class _FeeStructurePageState extends State<FeeStructurePage> {
  SchoolClass? selectedClass;
  List<FeeComponent> _components = [];
  List<FeeStructure> _allFeeStructures = [];
  bool _isLoading = false;
  final List<String> _allMonths = [
    'April', 'May', 'June', 'July', 'August', 'September',
    'October', 'November', 'December', 'January', 'February', 'March'
  ];

  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeeStructures();
    });
  }

  Future<void> _loadFeeStructures({bool showLoader = true}) async {
    if (showLoader) setState(() => _isLoading = true);
    try {
      final feeRepo = Provider.of<FeeRepository>(context, listen: false);
      final classRepo = Provider.of<ClassRepository>(context, listen: false);
      final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);

      // 1. Get current session
      final session = await dashboardRepo.getCurrentSession();
      if (session != null) {
        // 2. Fetch classes if empty
        if (classRepo.classes.isEmpty) {
          await classRepo.fetchClasses(session.id!);
        }
      }

      // 3. Load fee structures
      final structures = await feeRepo.getFeeStructures();
      setState(() {
        _allFeeStructures = structures.map((json) => FeeStructure.fromJson(json)).toList();

        // Auto-select first class if none selected
        if (selectedClass == null && classRepo.classes.isNotEmpty) {
          selectedClass = classRepo.classes.first;
        }

        if (selectedClass != null) {
          _initializeComponents(selectedClass);
        }
      });
    } catch (e) {
      debugPrint('Error loading fee structures: $e');
    } finally {
      if (showLoader) setState(() => _isLoading = false);
    }
  }

  void _initializeComponents(SchoolClass? currentClass) {
    if (currentClass == null) return;

    // Clear existing controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();

    // Check standalone FeeStructure collection first (Source of Truth)
    final existingStructure = _allFeeStructures.where((s) => s.classId == currentClass.id).firstOrNull;

    if (existingStructure != null && existingStructure.components.isNotEmpty) {
      _components = existingStructure.components.map((c) => c.copyWith()).toList();
    } else if (currentClass.feeStructure.isNotEmpty) {
      // Fallback to embedded structure if collection is empty
      _components = currentClass.feeStructure.map((c) => c.copyWith()).toList();
    } else {
      // Default empty structure
      _components = [
        FeeComponent(name: 'Monthly Tuition Fee', amount: 0, frequency: 'monthly', applicableMonths: List.from(_allMonths)),
        FeeComponent(name: 'Annual Admission Fee', amount: 0, frequency: 'annually', applicableMonths: []),
        FeeComponent(name: 'Examination Fee', amount: 0, frequency: 'annually', applicableMonths: []),
      ];
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classRepo = Provider.of<ClassRepository>(context);
    final feeRepo = Provider.of<FeeRepository>(context, listen: false);
    final dashboardRepo = Provider.of<DashboardRepository>(context, listen: false);

    final classes = classRepo.classes;
    if (selectedClass == null && classes.isNotEmpty) {
      selectedClass = classes.first;
      _initializeComponents(selectedClass);
    }

    return Padding(
      padding: const EdgeInsets.all(30),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                                  _initializeComponents(c);
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
                          'Adjust the fee components for this class below. Monthly fees can be configured for specific months.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 32),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _components.length,
                            itemBuilder: (context, index) {
                              final component = _components[index];
                              return _buildComponentEditor(component, index);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
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
                                    'components': _components.map((c) => c.toJson()).toList(),
                                  }
                                ];

                                final success = await feeRepo.saveFeeStructure(feeData);
                                if (success) {
                                  await classRepo.updateFeeStructure(selectedClass!.id!, _components);
                                  await _loadFeeStructures(showLoader: false);

                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Fee structure for ${selectedClass!.name} updated successfully!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
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
                                setState(() {
                                  _initializeComponents(selectedClass);
                                });
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

  Widget _buildComponentEditor(FeeComponent component, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    component.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      _components[index] = component.copyWith(
                        amount: double.tryParse(value) ?? 0,
                      );
                    },
                    controller: _controllers.putIfAbsent(
                      index,
                      () => TextEditingController(text: component.amount.toString().replaceAll('.0', ''))
                        ..selection = TextSelection.fromPosition(
                          TextPosition(offset: component.amount.toString().replaceAll('.0', '').length),
                        ),
                    ),
                  ),
                ),
              ],
            ),
            if (component.frequency == 'monthly') ...[
              const SizedBox(height: 20),
              const Text('Applicable Months:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: _allMonths.map((month) {
                  final isSelected = component.applicableMonths.contains(month);
                  return FilterChip(
                    label: Text(month),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        final newMonths = List<String>.from(component.applicableMonths);
                        if (selected) {
                          newMonths.add(month);
                        } else {
                          newMonths.remove(month);
                        }
                        _components[index] = component.copyWith(applicableMonths: newMonths);
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
