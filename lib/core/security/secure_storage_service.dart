import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for secure storage using platform-specific secure storage
/// Uses Keychain on iOS and Keystore on Android
class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Stores a value securely
  Future<void> write({required String key, required String value}) async {
    print('SecureStorageService: Writing key: $key');
    await _storage.write(key: key, value: value);
    print('SecureStorageService: Key $key written successfully.');
  }

  /// Retrieves a value from secure storage
  Future<String?> read({required String key}) async {
    print('SecureStorageService: Reading key: $key');
    final value = await _storage.read(key: key);
    print('SecureStorageService: Key $key read, value: ${value != null ? "exists" : "null"}');
    return value;
  }

  /// Deletes a value from secure storage
  Future<void> delete({required String key}) async {
    print('SecureStorageService: Deleting key: $key');
    await _storage.delete(key: key);
    print('SecureStorageService: Key $key deleted successfully.');
  }

  /// Deletes all values from secure storage
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Checks if a key exists
  Future<bool> containsKey({required String key}) async {
    return await _storage.containsKey(key: key);
  }

  /// Reads all values
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
}
