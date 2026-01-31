import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../../core/config/router.dart';
import '../bloc/onboarding_bloc.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();

  final List<OnboardingItem> _pages = [
    OnboardingItem(
      icon: Icons.lock_outline,
      title: 'Secure Your Life',
      description: 'Store all your important documents, notes, and memories in one secure place with military-grade encryption.',
      color: const Color(0xFF6366F1),
    ),
    OnboardingItem(
      icon: Icons.auto_awesome,
      title: 'Smart Organization',
      description: 'Organize your ideas, track finances, set reminders, and manage your life with powerful tools.',
      color: const Color(0xFF8B5CF6),
    ),
    OnboardingItem(
      icon: Icons.sync,
      title: 'Sync & Backup',
      description: 'Your data is automatically backed up and synced across devices. Never lose your important information.',
      color: const Color(0xFF06B6D4),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage(int currentPage, int totalPages) {
    if (currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.read<OnboardingBloc>().add(OnboardingGetStarted());
    }
  }

  void _skip() {
    context.read<OnboardingBloc>().add(OnboardingGetStarted());
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingNavigateToPinSetup) {
          Navigator.of(context).pushReplacementNamed(AppRouter.setupPin);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Skip Button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    context.read<OnboardingBloc>().add(OnboardingPageChanged(index));
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _OnboardingContent(item: _pages[index]);
                  },
                ),
              ),
              
              // Page Indicator
              BlocBuilder<OnboardingBloc, OnboardingState>(
                builder: (context, state) {
                  int currentPage = 0;
                  if (state is OnboardingInitial) {
                    currentPage = state.currentPage;
                  }
                  return SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: WormEffect(
                      activeDotColor: Theme.of(context).colorScheme.primary,
                      dotColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      dotHeight: screenWidth * 0.02,
                      dotWidth: screenWidth * 0.02,
                      spacing: screenWidth * 0.02,
                    ),
                  );
                },
              ),
              
              SizedBox(height: screenHeight * 0.04),
              
              // Next/Get Started Button
              BlocBuilder<OnboardingBloc, OnboardingState>(
                builder: (context, state) {
                  int currentPage = 0;
                  if (state is OnboardingInitial) {
                    currentPage = state.currentPage;
                  }
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: screenHeight * 0.02),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _nextPage(currentPage, _pages.length),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                        ),
                        child: Text(
                          currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                          style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: screenHeight * 0.04),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  final OnboardingItem item;

  const _OnboardingContent({required this.item});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final iconContainerSize = screenWidth * 0.3;
    final iconSize = iconContainerSize * 0.5;
    final titleFontSize = screenWidth * 0.06;
    final descriptionFontSize = screenWidth * 0.04;
    final verticalSpacing = screenHeight * 0.03;
    final largeVerticalSpacing = screenHeight * 0.06;

    return Padding(
      padding: EdgeInsets.all(screenWidth * 0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              size: iconSize,
              color: item.color,
            ),
          ),
          SizedBox(height: largeVerticalSpacing),
          
          // Title
          Text(
            item.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: verticalSpacing),
          
          // Description
          Text(
            item.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                  fontSize: descriptionFontSize,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
