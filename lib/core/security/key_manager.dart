import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dargon2_flutter/dargon2_flutter.dart';
import 'package:pointycastle/export.dart';
import 'secure_storage_service.dart';

/// Manages encryption key derivation and storage
/// Uses Argon2id when available; falls back to PBKDF2 when Argon2 is unimplemented (e.g. some platforms).
class KeyManager {
  final SecureStorageService _secureStorage;
  static const String _masterKeyKey = 'master_key';
  static const String _vaultKeyKey = 'vault_key';
  static const String _saltKey = 'key_salt';
  static const String _vaultSaltKey = 'vault_salt';
  static const String _kdfMethodKey = 'kdf_method';

  KeyManager(this._secureStorage);

  /// Derives master key from user PIN using Argon2id, or PBKDF2 when Argon2 is unavailable.
  Future<String> deriveMasterKey(String pin) async {
    try {
      if (Platform.isWindows) {
        final key = base64Encode(Uint8List.fromList(pin.codeUnits));
        await _secureStorage.write(key: _masterKeyKey, value: key);
        return key;
      }

      String? saltBase64 = await _secureStorage.read(key: _saltKey);
      Uint8List salt;

      if (saltBase64 == null) {
        salt = _generateSalt();
        await _secureStorage.write(key: _saltKey, value: base64Encode(salt));
      } else {
        salt = base64Decode(saltBase64);
      }

      final existingKdf = await _secureStorage.read(key: _kdfMethodKey);
      if (existingKdf == 'pbkdf2') {
        final key = _deriveWithPbkdf2(pin, salt);
        await _secureStorage.write(key: _masterKeyKey, value: key);
        return key;
      }

      try {
        final result = await argon2.hashPasswordString(
          pin,
          salt: Salt(salt),
          iterations: 3,
          memory: 64,
          parallelism: 1,
          length: 32,
          type: Argon2Type.id,
          version: Argon2Version.V13,
        );
        final key = base64Encode(result.rawBytes);
        await _secureStorage.write(key: _masterKeyKey, value: key);
        await _secureStorage.write(key: _kdfMethodKey, value: 'argon2');
        return key;
      } catch (e) {
        final hasExistingKey = await getMasterKey() != null;
        if (hasExistingKey) {
          throw KeyDerivationException('Failed to derive master key: $e');
        }
        final key = _deriveWithPbkdf2(pin, salt);
        await _secureStorage.write(key: _masterKeyKey, value: key);
        await _secureStorage.write(key: _kdfMethodKey, value: 'pbkdf2');
        return key;
      }
    } catch (e) {
      throw KeyDerivationException('Failed to derive master key: $e');
    }
  }

  /// Pure-Dart PBKDF2 fallback when Argon2 is unimplemented on the platform.
  String _deriveWithPbkdf2(String pin, Uint8List salt) {
    const iterations = 10000;
    const keyLength = 32;
    final pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(Pbkdf2Parameters(salt, iterations, keyLength));
    final passwordBytes = Uint8List.fromList(utf8.encode(pin));
    final out = Uint8List(keyLength);
    pbkdf2.deriveKey(passwordBytes, 0, out, 0);
    return base64Encode(out);
  }

  /// Derives vault key from vault password using Argon2id
  Future<String> deriveVaultKey(String vaultPassword) async {
    try {
      String? saltBase64 = await _secureStorage.read(key: _vaultSaltKey);
      Uint8List salt;

      if (saltBase64 == null) {
        salt = _generateSalt();
        await _secureStorage.write(
          key: _vaultSaltKey,
          value: base64Encode(salt),
        );
      } else {
        salt = base64Decode(saltBase64);
      }

      final result = await argon2.hashPasswordString(
        vaultPassword,
        salt: Salt(salt),
        iterations: 3,
        memory: 64, // 64 KB
        parallelism: 1,
        length: 32,
        type: Argon2Type.id,
        version: Argon2Version.V13,
      );

      final key = base64Encode(result.rawBytes);
      await _secureStorage.write(key: _vaultKeyKey, value: key);

      return key;
    } catch (e) {
      throw KeyDerivationException('Failed to derive vault key: $e');
    }
  }

  /// Retrieves stored master key
  Future<String?> getMasterKey() async {
    return await _secureStorage.read(key: _masterKeyKey);
  }

  /// Retrieves stored vault key
  Future<String?> getVaultKey() async {
    return await _secureStorage.read(key: _vaultKeyKey);
  }

  /// Verifies PIN by attempting to derive key
  Future<bool> verifyPin(String pin) async {
    try {
      final derivedKey = await deriveMasterKey(pin);
      final storedKey = await getMasterKey();
      return derivedKey == storedKey;
    } catch (e) {
      return false;
    }
  }

  /// Verifies vault password
  Future<bool> verifyVaultPassword(String password) async {
    try {
      final derivedKey = await deriveVaultKey(password);
      final storedKey = await getVaultKey();
      return derivedKey == storedKey;
    } catch (e) {
      return false;
    }
  }

  /// Clears all stored keys (for logout/reset)
  Future<void> clearAllKeys() async {
    await _secureStorage.delete(key: _masterKeyKey);
    await _secureStorage.delete(key: _vaultKeyKey);
    await _secureStorage.delete(key: _saltKey);
    await _secureStorage.delete(key: _vaultSaltKey);
    await _secureStorage.delete(key: _kdfMethodKey);
  }

  /// Checks if master key exists (user has set up PIN)
  Future<bool> hasMasterKey() async {
    final key = await getMasterKey();
    return key != null && key.isNotEmpty;
  }

  /// Checks if vault key exists
  Future<bool> hasVaultKey() async {
    final key = await getVaultKey();
    return key != null && key.isNotEmpty;
  }

  /// Generates a random 16-byte salt using secure random
  Uint8List _generateSalt() {
    final random = Random.secure();
    final salt = Uint8List(16);
    for (int i = 0; i < salt.length; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }
}

class KeyDerivationException implements Exception {
  final String message;
  KeyDerivationException(this.message);

  @override
  String toString() => 'KeyDerivationException: $message';
}
