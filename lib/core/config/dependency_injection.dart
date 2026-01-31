import 'package:get_it/get_it.dart';
import '../security/encryption_service.dart';
import '../security/key_manager.dart';
import '../security/secure_storage_service.dart';
import '../security/biometric_service.dart';
import '../database/hive_service.dart';
import '../database/database_helper.dart';
import '../../features/03_auth/data/datasources/auth_local_datasource.dart';
import '../../features/03_auth/data/repositories/auth_repository_impl.dart';
import '../../features/03_auth/domain/repositories/auth_repository.dart';
import '../../features/03_auth/domain/usecases/setup_pin.dart';
import '../../features/03_auth/domain/usecases/verify_pin.dart';
import '../../features/03_auth/domain/usecases/setup_biometric.dart';
import '../../features/03_auth/domain/usecases/lock_app.dart';
import '../../features/05_documents/data/datasources/document_local_datasource.dart';
import '../../features/05_documents/data/datasources/file_storage_datasource.dart';
import '../../features/05_documents/data/repositories/document_repository_impl.dart';
import '../../features/05_documents/domain/repositories/document_repository.dart';
import '../../features/05_documents/domain/usecases/add_document.dart' hide CheckFeaturesAccess;
import '../../features/05_documents/domain/usecases/get_all_documents.dart';
import '../../features/05_documents/domain/usecases/delete_document.dart';
import '../../features/05_documents/domain/usecases/search_documents.dart';
import '../../features/05_documents/presentation/bloc/document_bloc.dart';
import '../../features/06_notes/data/datasources/note_local_datasource.dart';
import '../../features/06_notes/presentation/bloc/note_bloc.dart';
import '../../features/06_notes/data/repositories/note_repository_impl.dart';
import '../../features/06_notes/domain/repositories/note_repository.dart';
import '../../features/06_notes/domain/usecases/create_note.dart';
import '../../features/06_notes/domain/usecases/get_all_notes.dart';
import '../../features/06_notes/domain/usecases/get_note_by_id.dart';
import '../../features/06_notes/domain/usecases/update_note.dart';
import '../../features/06_notes/domain/usecases/search_notes.dart';
import '../../features/06_notes/domain/usecases/delete_note.dart';
import '../../features/08_reminders/data/datasources/reminder_local_datasource.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/08_reminders/data/datasources/notification_datasource.dart';
import '../../features/08_reminders/data/repositories/reminder_repository_impl.dart';
import '../../features/08_reminders/domain/repositories/reminder_repository.dart';
import '../../features/08_reminders/domain/usecases/create_reminder.dart';
import '../../features/08_reminders/domain/usecases/get_all_reminders.dart';
import '../../features/08_reminders/domain/usecases/mark_as_complete.dart';
import '../../features/08_reminders/domain/usecases/delete_reminder.dart';
import '../../features/08_reminders/presentation/bloc/reminder_bloc.dart';
import '../../features/07_ideas/data/datasources/idea_local_datasource.dart';
import '../../features/07_ideas/data/repositories/idea_repository_impl.dart';
import '../../features/07_ideas/domain/repositories/idea_repository.dart';
import '../../features/07_ideas/domain/usecases/get_ideas_inbox.dart';
import '../../features/07_ideas/domain/usecases/create_idea.dart';
import '../../features/07_ideas/domain/usecases/like_idea.dart';
import '../../features/07_ideas/domain/usecases/get_all_projects.dart';
import '../../features/07_ideas/domain/usecases/get_project_by_id.dart';
import '../../features/07_ideas/domain/usecases/create_project.dart';
import '../../features/07_ideas/domain/usecases/update_project.dart';
import '../../features/07_ideas/domain/usecases/like_project.dart';
import '../../features/07_ideas/domain/usecases/set_project_review.dart';
import '../../features/07_ideas/presentation/bloc/idea_bloc.dart';
import '../../features/07_ideas/presentation/bloc/project_bloc.dart';
import '../../features/04_home/data/repositories/home_repository_impl.dart';
import '../../features/04_home/domain/repositories/home_repository.dart';
import '../../features/04_home/domain/usecases/get_dashboard_stats.dart';
import '../../features/04_home/domain/usecases/get_recent_items.dart';
import '../../features/04_home/domain/usecases/get_upcoming_reminders.dart' as home_usecases;
import '../../features/04_home/presentation/bloc/home_bloc.dart';
import '../../features/10_finance/data/datasources/finance_local_datasource.dart';
import '../../features/10_finance/data/datasources/sms_parser_datasource.dart';
import '../../features/10_finance/data/repositories/finance_repository_impl.dart';
import '../../features/10_finance/domain/repositories/finance_repository.dart';
import '../../features/10_finance/domain/usecases/get_all_transactions.dart';
import '../../features/10_finance/domain/usecases/parse_sms_transactions.dart';
import '../../features/10_finance/domain/usecases/get_monthly_summary.dart';
import '../../features/10_finance/domain/usecases/categorize_transaction.dart';
import '../../features/10_finance/presentation/bloc/finance_bloc.dart';
import '../../features/17_subscription/data/datasources/subscription_local_datasource.dart';
import '../../features/17_subscription/data/repositories/subscription_repository_impl.dart';
import '../../features/17_subscription/domain/repositories/subscription_repository.dart';
import '../../features/17_subscription/domain/usecases/check_features_access.dart';
import '../../features/17_subscription/domain/usecases/get_subscription_status.dart';
import '../../features/18_planner/data/datasources/planner_local_datasource.dart';
import '../../features/18_planner/data/repositories/planner_repository_impl.dart';
import '../../features/18_planner/domain/repositories/planner_repository.dart';
import '../../features/18_planner/domain/usecases/get_today_moments.dart';
import '../../features/18_planner/domain/usecases/get_moments_for_day.dart';
import '../../features/18_planner/domain/usecases/get_moments_in_range.dart';
import '../../features/18_planner/domain/usecases/create_moment.dart';
import '../../features/18_planner/domain/usecases/update_moment.dart';
import '../../features/18_planner/domain/usecases/acknowledge_moment.dart';
import '../../features/18_planner/domain/usecases/delete_moment.dart';
import '../../features/18_planner/domain/usecases/snooze_moment.dart';
import '../../features/18_planner/presentation/bloc/planner_bloc.dart';
import '../../features/01_splash/presentation/bloc/splash_bloc.dart';
import '../../features/02_onboarding/presentation/bloc/onboarding_bloc.dart';
import '../../features/03_auth/presentation/bloc/auth_bloc.dart';


final sl = GetIt.instance;

Future<void> init() async {
  // Core Services
  sl.registerLazySingleton<EncryptionService>(() => EncryptionService());
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  sl.registerLazySingleton<KeyManager>(
    () => KeyManager(sl<SecureStorageService>()),
  );
  sl.registerLazySingleton<BiometricService>(() => BiometricService());

  // Auth (before any await so early routes always have blocs)
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSource(
      sl<KeyManager>(),
      sl<SecureStorageService>(),
      sl<BiometricService>(),
    ),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthLocalDataSource>()),
  );
  sl.registerLazySingleton(() => SetupPin(sl<AuthRepository>()));
  sl.registerLazySingleton(() => VerifyPin(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SetupBiometric(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LockApp(sl<AuthRepository>()));

  // Auth BLoC / Splash BLoC / Onboarding BLoC (before any await)
  sl.registerFactory(() => AuthBloc(
        setupPin: sl<SetupPin>(),
        verifyPin: sl<VerifyPin>(),
      ));
  sl.registerFactory(() => SplashBloc());
  sl.registerFactory(() => OnboardingBloc());

  // Database
  sl.registerLazySingleton<HiveService>(
    () => HiveService(sl<EncryptionService>(), sl<KeyManager>()),
  );
  sl.registerLazySingleton<DatabaseHelper>(
    () => DatabaseHelper(sl<HiveService>()),
  );

  // Initialize Hive only if master key exists
  if (await sl<KeyManager>().hasMasterKey()) {
    await sl<HiveService>().init();
  }

  // Initialize Notifications
  sl.registerLazySingleton<FlutterLocalNotificationsPlugin>(
    () => FlutterLocalNotificationsPlugin(),
  );
  final notificationDataSource = NotificationDataSource(
    sl<FlutterLocalNotificationsPlugin>(),
  );
  await notificationDataSource.initialize();
  sl.registerLazySingleton<NotificationDataSource>(() => notificationDataSource);

  // Documents
  sl.registerLazySingleton<DocumentLocalDataSource>(
    () => DocumentLocalDataSource(sl<HiveService>(), sl<DatabaseHelper>()),
  );
  sl.registerLazySingleton<FileStorageDataSource>(
    () => FileStorageDataSource(sl<EncryptionService>(), sl<KeyManager>()),
  );
  sl.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(
      localDataSource: sl<DocumentLocalDataSource>(),
      fileStorageDataSource: sl<FileStorageDataSource>(),
    ),
  );
  sl.registerLazySingleton(() => AddDocument(sl<DocumentRepository>(), null));
  sl.registerLazySingleton(() => GetAllDocuments(sl<DocumentRepository>()));
  sl.registerLazySingleton(() => DeleteDocument(sl<DocumentRepository>()));
  sl.registerLazySingleton(() => SearchDocuments(sl<DocumentRepository>()));
  sl.registerFactory(() => DocumentBloc(
        getAllDocuments: sl<GetAllDocuments>(),
        searchDocuments: sl<SearchDocuments>(),
        deleteDocument: sl<DeleteDocument>(),
      ));

  // Notes
  sl.registerLazySingleton<NoteLocalDataSource>(
    () => NoteLocalDataSource(sl<HiveService>()),
  );
  sl.registerLazySingleton<NoteRepository>(
    () => NoteRepositoryImpl(sl<NoteLocalDataSource>()),
  );
  sl.registerLazySingleton(() => CreateNote(sl<NoteRepository>()));
  sl.registerLazySingleton(() => GetAllNotes(sl<NoteRepository>()));
  sl.registerLazySingleton(() => GetNoteById(sl<NoteRepository>()));
  sl.registerLazySingleton(() => UpdateNote(sl<NoteRepository>()));
  sl.registerLazySingleton(() => SearchNotes(sl<NoteRepository>()));
  sl.registerLazySingleton(() => DeleteNote(sl<NoteRepository>()));
  sl.registerFactory(() => NoteBloc(
        getAllNotes: sl<GetAllNotes>(),
        searchNotes: sl<SearchNotes>(),
        deleteNote: sl<DeleteNote>(),
      ));

  // Reminders
  sl.registerLazySingleton<ReminderLocalDataSource>(
    () => ReminderLocalDataSource(sl<HiveService>()),
  );
  sl.registerLazySingleton<ReminderRepository>(
    () => ReminderRepositoryImpl(
      localDataSource: sl<ReminderLocalDataSource>(),
      notificationDataSource: sl<NotificationDataSource>(),
    ),
  );
  sl.registerLazySingleton(() => CreateReminder(sl<ReminderRepository>()));
  sl.registerLazySingleton(() => GetAllReminders(sl<ReminderRepository>()));
  sl.registerLazySingleton(() => MarkAsComplete(sl<ReminderRepository>()));
  sl.registerLazySingleton(() => DeleteReminder(sl<ReminderRepository>()));
  sl.registerFactory(() => ReminderBloc(
        getAllReminders: sl<GetAllReminders>(),
        createReminder: sl<CreateReminder>(),
        markAsComplete: sl<MarkAsComplete>(),
        deleteReminder: sl<DeleteReminder>(),
      ));

  // Ideas
  sl.registerLazySingleton<IdeaLocalDataSource>(
    () => IdeaLocalDataSource(sl<HiveService>()),
  );
  sl.registerLazySingleton<IdeaRepository>(
    () => IdeaRepositoryImpl(sl<IdeaLocalDataSource>()),
  );
  sl.registerLazySingleton(() => GetIdeasInbox(sl<IdeaRepository>()));
  sl.registerLazySingleton(() => CreateIdea(sl<IdeaRepository>()));
  sl.registerLazySingleton(() => LikeIdea(sl<IdeaRepository>()));
  sl.registerFactory(() => IdeaBloc(
        getIdeasInbox: sl<GetIdeasInbox>(),
        createIdea: sl<CreateIdea>(),
        likeIdea: sl<LikeIdea>(),
      ));

  // Projects (Project Handler)
  sl.registerLazySingleton(() => GetAllProjects(sl<IdeaRepository>()));
  sl.registerLazySingleton(() => GetProjectById(sl<IdeaRepository>()));
  sl.registerLazySingleton(() => CreateProject(sl<IdeaRepository>()));
  sl.registerLazySingleton(() => UpdateProject(sl<IdeaRepository>()));
  sl.registerLazySingleton(() => LikeProject(sl<IdeaRepository>()));
  sl.registerLazySingleton(() => SetProjectReview(sl<IdeaRepository>()));
  sl.registerFactory(() => ProjectBloc(
        getAllProjects: sl<GetAllProjects>(),
        getProjectById: sl<GetProjectById>(),
        createProject: sl<CreateProject>(),
        updateProject: sl<UpdateProject>(),
        likeProject: sl<LikeProject>(),
        setProjectReview: sl<SetProjectReview>(),
      ));

  // Home
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      documentRepository: sl<DocumentRepository>(),
      noteRepository: sl<NoteRepository>(),
      ideaRepository: sl<IdeaRepository>(),
      reminderRepository: sl<ReminderRepository>(),
    ),
  );
  sl.registerLazySingleton(() => GetDashboardStats(sl<HomeRepository>()));
  sl.registerLazySingleton(() => GetRecentItems(sl<HomeRepository>()));
  sl.registerLazySingleton(() => home_usecases.GetUpcomingReminders(sl<HomeRepository>()));
  sl.registerFactory(() => HomeBloc(
        getDashboardStats: sl<GetDashboardStats>(),
        getRecentItems: sl<GetRecentItems>(),
        getUpcomingReminders: sl<home_usecases.GetUpcomingReminders>(),
      ));

  // Finance
  sl.registerLazySingleton<FinanceLocalDataSource>(
    () => FinanceLocalDataSource(sl<HiveService>()),
  );
  sl.registerLazySingleton<SmsParserDataSource>(() => SmsParserDataSource());
  sl.registerLazySingleton<FinanceRepository>(
    () => FinanceRepositoryImpl(
      localDataSource: sl<FinanceLocalDataSource>(),
      smsParserDataSource: sl<SmsParserDataSource>(),
    ),
  );
  sl.registerLazySingleton(() => GetAllTransactions(sl<FinanceRepository>()));
  sl.registerLazySingleton(() => ParseSmsTransactions(sl<FinanceRepository>()));
  sl.registerLazySingleton(() => GetMonthlySummary(sl<FinanceRepository>()));
  sl.registerLazySingleton(() => CategorizeTransaction(sl<FinanceRepository>()));
  sl.registerFactory(() => FinanceBloc(
        getAllTransactions: sl<GetAllTransactions>(),
        parseSmsTransactions: sl<ParseSmsTransactions>(),
        getMonthlySummary: sl<GetMonthlySummary>(),
        categorizeTransaction: sl<CategorizeTransaction>(),
      ));

  // Subscription
  sl.registerLazySingleton<SubscriptionLocalDataSource>(
    () => SubscriptionLocalDataSource(sl<HiveService>()),
  );
  sl.registerLazySingleton<SubscriptionRepository>(
    () => SubscriptionRepositoryImpl(sl<SubscriptionLocalDataSource>()),
  );
  sl.registerLazySingleton(() => CheckFeaturesAccess(sl<SubscriptionRepository>()));
  sl.registerLazySingleton(() => GetSubscriptionStatus(sl<SubscriptionRepository>()));

  // Planner (moments: event, bill, milestone)
  sl.registerLazySingleton<PlannerLocalDataSource>(
    () => PlannerLocalDataSource(sl<HiveService>()),
  );
  sl.registerLazySingleton<PlannerRepository>(
    () => PlannerRepositoryImpl(localDataSource: sl<PlannerLocalDataSource>()),
  );
  sl.registerLazySingleton(() => GetTodayMoments(sl<PlannerRepository>()));
  sl.registerLazySingleton(() => GetMomentsForDay(sl<PlannerRepository>()));
  sl.registerLazySingleton(() => GetMomentsInRange(sl<PlannerRepository>()));
  sl.registerLazySingleton(() => CreateMoment(sl<PlannerRepository>()));
  sl.registerLazySingleton(() => UpdateMoment(sl<PlannerRepository>()));
  sl.registerLazySingleton(() => AcknowledgeMoment(sl<PlannerRepository>()));
  sl.registerLazySingleton(() => DeleteMoment(sl<PlannerRepository>()));
  sl.registerLazySingleton(() => SnoozeMoment(sl<PlannerRepository>()));
  sl.registerFactory(() => PlannerBloc(
        getTodayMoments: sl<GetTodayMoments>(),
        getMomentsForDay: sl<GetMomentsForDay>(),
        getMomentsInRange: sl<GetMomentsInRange>(),
        createMoment: sl<CreateMoment>(),
        updateMoment: sl<UpdateMoment>(),
        acknowledgeMoment: sl<AcknowledgeMoment>(),
        deleteMoment: sl<DeleteMoment>(),
        snoozeMoment: sl<SnoozeMoment>(),
      ));
}
