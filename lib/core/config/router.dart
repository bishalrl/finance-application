class AppRouter {
  // Auth
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String setupPin = '/setup-pin';
  static const String verifyPin = '/verify-pin';
  static const String appLock = '/app-lock';
  
  // Main
  static const String home = '/home';
  
  // Documents
  static const String documents = '/documents';
  static const String documentDetail = '/documents/:id';
  static const String addDocument = '/documents/add';
  
  // Notes
  static const String notes = '/notes';
  static const String noteEditor = '/notes/editor';
  static const String noteDetail = '/notes/:id';
  
  // Ideas
  static const String ideas = '/ideas';
  static const String projects = '/projects';
  static const String ideaDetail = '/ideas/:id';

  // Planner (moments: event, bill, milestone)
  static const String planner = '/planner';
  static const String plannerCalendar = '/planner/calendar';
  static const String addMoment = '/planner/add';
  static const String momentDetail = '/planner/moment/:id';

  // Reminders
  static const String reminders = '/reminders';
  static const String addReminder = '/reminders/add';
  
  // Finance
  static const String finance = '/finance';
  static const String transactions = '/finance/transactions';
  
  // Vault
  static const String vault = '/vault';
  static const String vaultUnlock = '/vault/unlock';
  
  // Search
  static const String search = '/search';
  
  // Settings
  static const String settings = '/settings';
  static const String security = '/settings/security';
  static const String subscription = '/settings/subscription';
}
