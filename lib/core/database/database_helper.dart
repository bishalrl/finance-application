import 'package:hive/hive.dart';
import 'hive_service.dart';

/// Helper class for common database operations
class DatabaseHelper {
  final HiveService _hiveService;

  DatabaseHelper(this._hiveService);

  /// Saves an item to a box
  Future<void> save<T>(String boxName, String key, T value) async {
    final box = _hiveService.getBox(boxName);
    await box.put(key, value);
  }

  /// Retrieves an item from a box
  T? get<T>(String boxName, String key) {
    final box = _hiveService.getBox(boxName);
    return box.get(key) as T?;
  }

  /// Deletes an item from a box
  Future<void> delete(String boxName, String key) async {
    final box = _hiveService.getBox(boxName);
    await box.delete(key);
  }

  /// Gets all items from a box
  Map<dynamic, dynamic> getAll(String boxName) {
    final box = _hiveService.getBox(boxName);
    return box.toMap();
  }

  /// Gets all values from a box as a list
  List<T> getAllValues<T>(String boxName) {
    final box = _hiveService.getBox(boxName);
    return box.values.cast<T>().toList();
  }

  /// Gets all keys from a box
  List<dynamic> getAllKeys(String boxName) {
    final box = _hiveService.getBox(boxName);
    return box.keys.toList();
  }

  /// Checks if a key exists in a box
  bool containsKey(String boxName, String key) {
    final box = _hiveService.getBox(boxName);
    return box.containsKey(key);
  }

  /// Clears a box
  Future<void> clearBox(String boxName) async {
    final box = _hiveService.getBox(boxName);
    await box.clear();
  }

  /// Gets count of items in a box
  int getCount(String boxName) {
    final box = _hiveService.getBox(boxName);
    return box.length;
  }

  /// Watches a key for changes
  Stream<BoxEvent> watchKey(String boxName, String key) {
    final box = _hiveService.getBox(boxName);
    return box.watch(key: key);
  }

  /// Watches entire box for changes
  Stream<BoxEvent> watchBox(String boxName) {
    final box = _hiveService.getBox(boxName);
    return box.watch();
  }
}
