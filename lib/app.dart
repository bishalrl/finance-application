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
import 'features/05_documents/presentation/bloc/document_bloc.dart';
import 'features/05_documents/presentation/bloc/document_event.dart';
import 'features/05_documents/presentation/pages/documents_list_page.dart';
import 'features/05_documents/presentation/pages/add_document_page.dart';
import 'features/06_notes/presentation/bloc/note_bloc.dart';
import 'features/06_notes/presentation/bloc/note_event.dart';
import 'features/06_notes/presentation/pages/notes_list_page.dart';
import 'features/06_notes/presentation/pages/note_editor_page.dart';
import 'features/07_ideas/presentation/bloc/idea_bloc.dart';
import 'features/07_ideas/presentation/bloc/idea_event.dart';
import 'features/07_ideas/presentation/pages/ideas_inbox_page.dart';
import 'features/08_reminders/presentation/bloc/reminder_bloc.dart';
import 'features/08_reminders/presentation/bloc/reminder_event.dart';
import 'features/08_reminders/presentation/pages/reminders_page.dart';
import 'features/08_reminders/presentation/pages/add_reminder_page.dart';
import 'features/10_finance/presentation/bloc/finance_bloc.dart';
import 'features/10_finance/presentation/bloc/finance_event.dart';
import 'features/10_finance/presentation/pages/finance_page.dart';
import 'features/10_finance/presentation/pages/transactions_page.dart';
import 'features/11_vault/presentation/pages/vault_page.dart';
import 'features/13_search/presentation/pages/search_page.dart';
import 'features/16_settings/presentation/pages/settings_page.dart';
import 'features/17_subscription/presentation/pages/subscription_page.dart';
import 'features/18_planner/presentation/bloc/planner_bloc.dart';
import 'features/18_planner/presentation/bloc/planner_event.dart';
import 'features/18_planner/presentation/pages/planner_today_page.dart';
import 'features/18_planner/presentation/pages/planner_calendar_page.dart';
import 'features/18_planner/presentation/pages/add_moment_page.dart';
import 'features/18_planner/presentation/pages/moment_detail_page.dart';
import 'features/07_ideas/presentation/pages/projects_page.dart';
import 'features/07_ideas/presentation/bloc/project_bloc.dart';
import 'features/07_ideas/presentation/bloc/project_event.dart';

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
        BlocProvider<DocumentBloc>(
          create: (context) => di.sl<DocumentBloc>()..add(const LoadDocuments()),
        ),
      ],
      child: MaterialApp(
        title: 'Life Vault',
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
          AppRouter.home: (context) => BlocProvider(
                create: (context) => di.sl<HomeBloc>()..add(const LoadDashboard()),
                child: HomePage(),
              ),
          // Add placeholder routes for other pages
          AppRouter.documents: (context) => DocumentsListPage(),
          AppRouter.addDocument: (context) => AddDocumentPage(),
          AppRouter.notes: (context) => BlocProvider(
                create: (context) => di.sl<NoteBloc>()..add(const LoadNotes()),
                child: NotesListPage(),
              ),
          AppRouter.noteEditor: (context) => NoteEditorPage(),
          AppRouter.ideas: (context) => BlocProvider(
                create: (context) => di.sl<IdeaBloc>()..add(const LoadIdeas()),
                child: IdeasInboxPage(),
              ),
          AppRouter.planner: (context) => BlocProvider(
                create: (context) => di.sl<PlannerBloc>()..add(const LoadTodayMoments()),
                child: PlannerTodayPage(),
              ),
          AppRouter.plannerCalendar: (context) => BlocProvider(
                create: (context) => di.sl<PlannerBloc>(),
                child: PlannerCalendarPage(),
              ),
          AppRouter.addMoment: (context) => BlocProvider(
                create: (context) => di.sl<PlannerBloc>(),
                child: AddMomentPage(),
              ),
          AppRouter.projects: (context) => BlocProvider(
                create: (context) => di.sl<ProjectBloc>()..add(const LoadProjects()),
                child: ProjectsPage(),
              ),
          AppRouter.reminders: (context) => BlocProvider(
                create: (context) => di.sl<ReminderBloc>()..add(const LoadReminders()),
                child: RemindersPage(),
              ),
          AppRouter.addReminder: (context) => BlocProvider(
                create: (context) => di.sl<ReminderBloc>(),
                child: AddReminderPage(),
              ),
          AppRouter.finance: (context) => BlocProvider(
                create: (context) => di.sl<FinanceBloc>()..add(const LoadTransactions()),
                child: FinancePage(),
              ),
          AppRouter.transactions: (context) => BlocProvider(
                create: (context) => di.sl<FinanceBloc>()..add(const LoadTransactions()),
                child: TransactionsPage(),
              ),
          AppRouter.vault: (context) => VaultPage(),
          AppRouter.vaultUnlock: (context) => Scaffold(
                appBar: AppBar(title: const Text('Unlock Vault')),
                body: const Center(child: Text('Vault unlock')),
              ),
          AppRouter.search: (context) => SearchPage(),
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
