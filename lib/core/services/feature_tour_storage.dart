import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user has completed the first-time feature tour.
class FeatureTourStorage {
  static const String _keyCompleted = 'artha_feature_tour_completed';
  static const String _keyFinanceImportTutorial =
      'artha_finance_import_tutorial_seen';

  final SharedPreferences _prefs;

  FeatureTourStorage(this._prefs);

  Future<bool> hasCompletedTour() async {
    return _prefs.getBool(_keyCompleted) ?? false;
  }

  Future<void> setTourCompleted() async {
    await _prefs.setBool(_keyCompleted, true);
  }

  Future<bool> hasSeenFinanceImportTutorial() async {
    return _prefs.getBool(_keyFinanceImportTutorial) ?? false;
  }

  Future<void> setFinanceImportTutorialSeen() async {
    await _prefs.setBool(_keyFinanceImportTutorial, true);
  }
}
