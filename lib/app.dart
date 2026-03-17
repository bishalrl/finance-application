import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/config/router.dart';
import 'core/config/dependency_injection.dart' as di;
import 'features/01_splash/presentation/pages/splash_page.dart';
import 'features/02_onboarding/presentation/bloc/onboarding_bloc.dart';
import 'features/02_onboarding/presentation/pages/onboarding_page.dart';
import 'features/03_auth/presentation/pages/setup_pin_page.dart';
import 'features/03_auth/presentation/pages/verify_pin_page.dart';
import 'features/04_home/presentation/pages/home_page.dart';
import 'features/04_home/presentation/bloc/home_bloc.dart';
import 'features/04_home/presentation/bloc/home_event.dart';
import 'features/01_splash/presentation/bloc/splash_bloc.dart';
import 'features/01_splash/presentation/bloc/splash_event.dart';
import 'features/03_auth/presentation/bloc/auth_bloc.dart';
import 'features/10_finance/presentation/bloc/finance_bloc.dart';
import 'features/10_finance/presentation/bloc/finance_event.dart';
import 'features/10_finance/presentation/pages/finance_page.dart';
import 'features/10_finance/presentation/pages/transactions_page.dart';
import 'features/16_settings/presentation/pages/settings_page.dart';
import 'features/17_subscription/presentation/pages/subscription_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SplashBloc>(
          create: (context) => di.sl<SplashBloc>()..add(const CheckAuthStatus()),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>(),
        ),
        BlocProvider<OnboardingBloc>(
          create: (context) => di.sl<OnboardingBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'Artha',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: AppRouter.splash,
        routes: {
          AppRouter.splash: (context) => SplashPage(),
          AppRouter.onboarding: (context) => OnboardingPage(),
          AppRouter.setupPin: (context) => SetupPinPage(),
          AppRouter.verifyPin: (context) => VerifyPinPage(),
          AppRouter.home: (context) => MultiBlocProvider(
                providers: [
                  BlocProvider<HomeBloc>(
                    create: (context) => di.sl<HomeBloc>()..add(const LoadDashboard()),
                  ),
                  BlocProvider<FinanceBloc>(
                    create: (context) => di.sl<FinanceBloc>()..add(const LoadTransactions()),
                  ),
                ],
                child: HomePage(),
              ),
          AppRouter.finance: (context) => BlocProvider(
                create: (context) => di.sl<FinanceBloc>()..add(const LoadTransactions()),
                child: FinancePage(),
              ),
          AppRouter.transactions: (context) => BlocProvider(
                create: (context) => di.sl<FinanceBloc>()..add(const LoadTransactions()),
                child: TransactionsPage(),
              ),
          AppRouter.settings: (context) => SettingsPage(),
          AppRouter.security: (context) => Scaffold(
                appBar: AppBar(title: const Text('Security')),
                body: const Center(child: Text('Security settings')),
              ),
          AppRouter.subscription: (context) => SubscriptionPage(),
        },
      ),
    );
  }
}
