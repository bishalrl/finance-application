import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/dependency_injection.dart' as di;
import '../../../../core/config/router.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    
    // Trigger navigation check
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<SplashBloc>().add(CheckAuthStatus());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizes
    final logoSize = screenWidth * 0.3;
    final iconSize = logoSize * 0.5;
    final titleFontSize = screenHeight * 0.04;
    final subtitleFontSize = screenHeight * 0.02;
    final verticalSpacing = screenHeight * 0.04;
    final largeVerticalSpacing = screenHeight * 0.08;
    final indicatorSize = screenWidth * 0.1;

    return BlocListener<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state is NavigateToOnboarding) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.of(context).pushReplacementNamed(AppRouter.onboarding);
              }
            });
          } else if (state is NavigateToPinSetup) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.of(context).pushReplacementNamed(AppRouter.setupPin);
              }
            });
          } else if (state is NavigateToHome) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.of(context).pushReplacementNamed(AppRouter.home);
              }
            });
          } else if (state is NavigateToPinVerify) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                Navigator.of(context).pushReplacementNamed(AppRouter.verifyPin);
              }
            });
          }
        },
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
            ),
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo/Icon
                      Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: iconSize,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                      SizedBox(height: verticalSpacing),
                      // App Name
                      Text(
                        'Artha',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              fontSize: titleFontSize,
                            ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Your Personal OS',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              letterSpacing: 1,
                              fontSize: subtitleFontSize,
                            ),
                      ),
                      SizedBox(height: largeVerticalSpacing),
                      // Loading Indicator
                      SizedBox(
                        width: indicatorSize,
                        height: indicatorSize,
                        child: const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      
    );
  }
}
