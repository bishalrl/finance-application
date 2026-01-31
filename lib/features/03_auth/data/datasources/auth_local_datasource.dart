

import 'package:life_vault/core/security/biometric_service.dart';
import 'package:life_vault/core/security/key_manager.dart';
import 'package:life_vault/core/security/secure_storage_service.dart';

class AuthLocalDataSource {
  final KeyManager _keyManager;
  final SecureStorageService _secureStorage;
  final BiometricService _biometricService;

  AuthLocalDataSource(this._keyManager, this._secureStorage, this._biometricService);

  Future<bool> hasPin() async {
    return await _keyManager.hasMasterKey();
  }

  Future<bool> setupPin(String pin) async {
    try {
      print('AuthLocalDataSource: Attempting to derive master key...');
      await _keyManager.deriveMasterKey(pin);
      print('AuthLocalDataSource: Master key derived successfully.');
      return true;
    } catch (e) {
      print('AuthLocalDataSource: Error deriving master key: $e');
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    return await _keyManager.verifyPin(pin);
  }

  Future<bool> hasBiometric() async {
    return await _biometricService.isBiometricsAvailable();
  }

  Future<bool> setupBiometric() async {
    return await _biometricService.authenticate(
      reason: 'Setup biometric authentication',
    );
  }

  Future<bool> verifyBiometric() async {
    return await _biometricService.authenticate(
      reason: 'Authenticate to access your vault',
    );
  }
}
