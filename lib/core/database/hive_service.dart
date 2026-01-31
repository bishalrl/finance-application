import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../security/encryption_service.dart';
import '../security/key_manager.dart';

/// Service for managing Hive database with encryption
class HiveService {
  final EncryptionService _encryptionService;
  final KeyManager _keyManager;
  bool _isInitialized = false;

  // Box names
  static const String documentsBox = 'documents';
  static const String notesBox = 'notes';
  static const String ideasBox = 'ideas';
  static const String projectsBox = 'projects';
  static const String remindersBox = 'reminders';
  static const String transactionsBox = 'transactions';
  static const String vaultBox = 'vault';
  static const String tagsBox = 'tags';
  static const String searchIndexBox = 'search_index';
  static const String settingsBox = 'settings';
  static const String subscriptionBox = 'subscription';
  static const String plannerMomentsBox = 'planner_moments';

  HiveService(this._encryptionService, this._keyManager);

  /// Initializes Hive with encryption
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      await Hive.initFlutter();
      
      // Get encryption key
      final masterKey = await _keyManager.getMasterKey();
      if (masterKey == null) {
        throw Exception('Master key not found. User must set up PIN first.');
      }

      // Create encryption cipher from master key
      // Derive 32-byte key from master key
      final keyBytes = _deriveKeyBytes(masterKey);
      final encryptionKey = HiveAesCipher(keyBytes);

      // Open encrypted boxes
      await _openBoxes(encryptionKey);

      _isInitialized = true;
    } catch (e) {
      throw HiveInitializationException('Failed to initialize Hive: $e');
    }
  }

  /// Opens all required Hive boxes with encryption
  Future<void> _openBoxes(HiveAesCipher encryptionKey) async {
    // Open boxes with encryption
    await Hive.openBox(documentsBox, encryptionCipher: encryptionKey);
    await Hive.openBox(notesBox, encryptionCipher: encryptionKey);
    await Hive.openBox(ideasBox, encryptionCipher: encryptionKey);
    await Hive.openBox(projectsBox, encryptionCipher: encryptionKey);
    await Hive.openBox(remindersBox, encryptionCipher: encryptionKey);
    await Hive.openBox(transactionsBox, encryptionCipher: encryptionKey);
    await Hive.openBox(tagsBox, encryptionCipher: encryptionKey);
    await Hive.openBox(searchIndexBox, encryptionCipher: encryptionKey);
    await Hive.openBox(settingsBox, encryptionCipher: encryptionKey);
    await Hive.openBox(subscriptionBox, encryptionCipher: encryptionKey);
    await Hive.openBox(plannerMomentsBox, encryptionCipher: encryptionKey);

    // Vault box uses additional encryption (will be handled separately)
    // For now, open it with same encryption
    await Hive.openBox(vaultBox, encryptionCipher: encryptionKey);
  }

  /// Gets a box by name
  Box getBox(String boxName) {
    if (!_isInitialized) {
      throw HiveNotInitializedException('Hive not initialized. Call init() first.');
    }
    return Hive.box(boxName);
  }

  /// Closes all boxes
  Future<void> closeAll() async {
    await Hive.close();
    _isInitialized = false;
  }

  /// Clears all data (for logout/reset)
  Future<void> clearAll() async {
    final boxes = [
      documentsBox,
      notesBox,
      ideasBox,
      projectsBox,
      remindersBox,
      transactionsBox,
      vaultBox,
      tagsBox,
      searchIndexBox,
      settingsBox,
      subscriptionBox,
      plannerMomentsBox,
    ];

    for (final boxName in boxes) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).clear();
      }
    }
  }

  /// Deletes all boxes (complete reset)
  Future<void> deleteAll() async {
    await closeAll();
    
    final boxes = [
      documentsBox,
      notesBox,
      ideasBox,
      projectsBox,
      remindersBox,
      transactionsBox,
      vaultBox,
      tagsBox,
      searchIndexBox,
      settingsBox,
      subscriptionBox,
      plannerMomentsBox,
    ];

    for (final boxName in boxes) {
      await Hive.deleteBoxFromDisk(boxName);
    }
  }

  /// Gets box path
  Future<String> getBoxPath(String boxName) async {
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/$boxName.hive';
  }

  /// Derives a 32-byte key from master key string
  List<int> _deriveKeyBytes(String key) {
    // Use first 32 bytes of base64 decoded key, or pad/truncate as needed
    final decoded = base64Decode(key);
    if (decoded.length >= 32) {
      return decoded.sublist(0, 32);
    } else {
      // Pad with zeros if needed
      return List<int>.from(decoded)..addAll(List.filled(32 - decoded.length, 0));
    }
  }
}

class HiveInitializationException implements Exception {
  final String message;
  HiveInitializationException(this.message);
  
  @override
  String toString() => 'HiveInitializationException: $message';
}

class HiveNotInitializedException implements Exception {
  final String message;
  HiveNotInitializedException(this.message);
  
  @override
  String toString() => 'HiveNotInitializedException: $message';
}
