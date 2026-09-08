import 'package:flutter/material.dart';
import 'package:jayasha_childrens_academy/core/models/academic_session.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';
import 'package:jayasha_childrens_academy/features/auth/data/repositories/onboarding_repository_impl.dart';
import 'package:jayasha_childrens_academy/features/auth/presentation/pages/onboarding/security_pin_onboarding_page.dart';
import 'package:jayasha_childrens_academy/features/auth/presentation/widgets/onboarding_progress_header.dart';
import 'package:jayasha_childrens_academy/features/dashboard/presentation/pages/dashboard_page.dart';

class FeeStructureOnboardingPage extends StatefulWidget {
  const FeeStructureOnboardingPage({super.key});

  @override
  State<FeeStructureOnboardingPage> createState() => _FeeStructureOnboardingPageState();
}

class _FeeStructureOnboardingPageState extends State<FeeStructureOnboardingPage> {
  final _repository = OnboardingRepositoryImpl();
  bool _isLoading = true;
  List<String> _classes = [];
  final Map<String, Map<String, TextEditingController>> _feeControllers = {};

  @override
  void initState() {
    super.initState();
    _loadAcademicData();
  }

  Future<void> _loadAcademicData() async {
    setState(() => _isLoading = true);
    try {
      final session = await _repository.getAcademicSession();
      if (session != null) {
        setState(() {
          _classes = session.classes.map((c) => c.className).toList();
          for (var className in _classes) {
            _feeControllers[className] = {
              'Monthly Tuition Fee': TextEditingController(text: '0'),
              'Annual Admission Fee': TextEditingController(text: '0'),
              'Examination Fee': TextEditingController(text: '0'),
            };
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading academic data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (var classControllers in _feeControllers.values) {
      for (var controller in classControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  void _finish() async {
    final Map<String, Map<String, double>> feeData = {};
    _feeControllers.forEach((className, controllers) {
      feeData[className] = {
        'Monthly Tuition Fee': double.tryParse(controllers['Monthly Tuition Fee']!.text) ?? 0.0,
        'Annual Admission Fee': double.tryParse(controllers['Annual Admission Fee']!.text) ?? 0.0,
        'Examination Fee': double.tryParse(controllers['Examination Fee']!.text) ?? 0.0,
      };
    });

    final repo = OnboardingRepositoryImpl();
    await repo.saveFeeStructure(feeData);

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SecurityPinOnboardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Left Side - Info
          Expanded(
            flex: 2,
            child: Container(
              color: AppColors.primary,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet, size: 100, color: Colors.white),
                  const SizedBox(height: 24),
                  const Text(
                    "Fee Structure",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Define the fee components for each class to automate billing.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right Side - Form
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(60, 40, 60, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OnboardingProgressHeader(currentStep: 3),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Set Annual Fees",
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: _finish,
                        child: const Text("Skip for now"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "You can always update these values later in settings.",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _classes.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "No classes found. Please set up academic session first.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Go Back"),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _classes.length,
                                itemBuilder: (context, index) {
                                  final className = _classes[index];
                                  final controllers = _feeControllers[className]!;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 24),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: Colors.grey.shade200),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            className,
                                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                                          ),
                                          const SizedBox(height: 20),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildFeeField("Tuition Fee", controllers['Monthly Tuition Fee']!),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: _buildFeeField("Admission Fee", controllers['Annual Admission Fee']!),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: _buildFeeField("Exam Fee", controllers['Examination Fee']!),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Back", style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _finish,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            "Continue to Security Setup",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: "₹ ",
            filled: true,
            fillColor: Colors.grey.shade50,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
      ],
    );
  }
}
