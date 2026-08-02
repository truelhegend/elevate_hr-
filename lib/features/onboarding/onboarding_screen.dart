import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/app_strings.dart';
import '../../core/data/providers.dart';
import '../../shared/widgets/primary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      icon: Icons.event_available_rounded,
      title: AppStrings.onboarding1Title,
      description: AppStrings.onboarding1Desc,
      color: AppColors.primary,
    ),
    _OnboardingData(
      icon: Icons.insights_rounded,
      title: AppStrings.onboarding2Title,
      description: AppStrings.onboarding2Desc,
      color: AppColors.accent,
    ),
    _OnboardingData(
      icon: Icons.psychology_rounded,
      title: AppStrings.onboarding3Title,
      description: AppStrings.onboarding3Desc,
      color: AppColors.primaryDark,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final storage = ref.read(localStorageProvider);
    await storage.setOnboardingComplete();
    if (mounted) {
      context.go('/login');
    }
  }

  Future<void> _nextPage() async {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      await _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: Text(
                  AppStrings.skip,
                  style: GoogleFonts.inter(
                    fontSize: AppSizes.s14,
                    color: AppColors.grey500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.p32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: page.color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            page.icon,
                            size: 80,
                            color: page.color,
                          ),
                        )
                            .animate(
                              key: ValueKey(_currentPage == index),
                            )
                            .fadeIn(duration: 500.ms)
                            .scale(
                              begin: const Offset(0.8, 0.8),
                              duration: 500.ms,
                              curve: Curves.easeOutBack,
                            ),
                        const SizedBox(height: 48),
                        Text(
                          page.title,
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.s28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimaryLight,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate(
                              key: ValueKey('title_$index'),
                            )
                            .fadeIn(delay: 200.ms, duration: 500.ms)
                            .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 500.ms),
                        const SizedBox(height: 16),
                        Text(
                          page.description,
                          style: GoogleFonts.inter(
                            fontSize: AppSizes.s16,
                            color: AppColors.grey500,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        )
                            .animate(
                              key: ValueKey('desc_$index'),
                            )
                            .fadeIn(delay: 400.ms, duration: 500.ms)
                            .slideY(begin: 0.2, end: 0, delay: 400.ms, duration: 500.ms),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.p32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 32 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : AppColors.grey300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: PrimaryButton(
                      text: _currentPage == _pages.length - 1
                          ? AppStrings.getStarted
                          : AppStrings.next,
                      onPressed: _nextPage,
                      backgroundColor: _pages[_currentPage].color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
