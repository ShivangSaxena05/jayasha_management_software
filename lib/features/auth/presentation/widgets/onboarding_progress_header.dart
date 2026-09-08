import 'package:flutter/material.dart';
import 'package:jayasha_childrens_academy/core/theme/app_colors.dart';

class OnboardingStep {
  final String title;
  final IconData icon;

  const OnboardingStep({required this.title, required this.icon});
}

class OnboardingProgressHeader extends StatelessWidget {
  final int currentStep;
  final List<OnboardingStep> steps = const [
    OnboardingStep(title: 'Principal', icon: Icons.person_outline),
    OnboardingStep(title: 'Academic', icon: Icons.calendar_month_outlined),
    OnboardingStep(title: 'Teachers', icon: Icons.people_outline),
    OnboardingStep(title: 'Fees', icon: Icons.account_balance_wallet_outlined),
    OnboardingStep(title: 'Security', icon: Icons.lock_outline),
  ];

  const OnboardingProgressHeader({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length, (index) {
              return Expanded(
                child: Row(
                  children: [
                    // Dot and Icon
                    Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: index <= currentStep ? AppColors.primary : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: index <= currentStep ? AppColors.primary : Colors.grey.shade300,
                              width: 2,
                            ),
                            boxShadow: index == currentStep
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ]
                                : null,
                          ),
                          child: Icon(
                            steps[index].icon,
                            color: index <= currentStep ? Colors.white : Colors.grey.shade400,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          steps[index].title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: index <= currentStep ? FontWeight.bold : FontWeight.normal,
                            color: index <= currentStep ? AppColors.primary : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    // Connector line
                    if (index < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 24),
                          color: index < currentStep ? AppColors.primary : Colors.grey.shade200,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
