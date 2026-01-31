import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

/// Service for encrypting and decrypting data using AES-256-GCM
class EncryptionService {
  /// Encrypts plain text using AES-256-GCM
  /// 
  /// [plainText] - The text to encrypt
  /// [key] - The encryption key (should be 32 bytes for AES-256)
  /// Returns base64 encoded encrypted string
  Future<String> encrypt(String plainText, String key) async {
    try {
      // Ensure key is 32 bytes for AES-256
      final keyBytes = _deriveKey(key);
      final encrypter = Encrypter(AES(Key(keyBytes), mode: AESMode.gcm));
      
      // Generate random IV
      final iv = IV.fromSecureRandom(12); // 12 bytes for GCM
      
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      
      // Combine IV and encrypted data
      final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
      return base64Encode(combined);
    } catch (e) {
      throw EncryptionException('Failed to encrypt data: $e');
    }
  }

  /// Decrypts encrypted text using AES-256-GCM
  /// 
  /// [encrypted] - Base64 encoded encrypted string
  /// [key] - The decryption key
  /// Returns decrypted plain text
  Future<String> decrypt(String encrypted, String key) async {
    try {
      final keyBytes = _deriveKey(key);
      final encrypter = Encrypter(AES(Key(keyBytes), mode: AESMode.gcm));
      
      // Decode base64
      final combined = base64Decode(encrypted);
      
      // Extract IV (first 12 bytes) and encrypted data
      final iv = IV(combined.sublist(0, 12));
      final encryptedBytes = combined.sublist(12);
      
      final encryptedData = Encrypted(encryptedBytes);
      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      throw EncryptionException('Failed to decrypt data: $e');
    }
  }

  /// Encrypts binary data (files)
  Future<Uint8List> encryptBytes(Uint8List data, String key) async {
    try {
      final keyBytes = _deriveKey(key);
      final encrypter = Encrypter(AES(Key(keyBytes), mode: AESMode.gcm));
      
      final iv = IV.fromSecureRandom(12);
      final encrypted = encrypter.encryptBytes(data, iv: iv);
      
      // Combine IV and encrypted data
      return Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
    } catch (e) {
      throw EncryptionException('Failed to encrypt bytes: $e');
    }
  }

  /// Decrypts binary data (files)
  Future<Uint8List> decryptBytes(Uint8List encryptedData, String key) async {
    try {
      final keyBytes = _deriveKey(key);
      final encrypter = Encrypter(AES(Key(keyBytes), mode: AESMode.gcm));
      
      // Extract IV (first 12 bytes) and encrypted data
      final iv = IV(encryptedData.sublist(0, 12));
      final encryptedBytes = encryptedData.sublist(12);
      
      final encrypted = Encrypted(encryptedBytes);
      final decrypted = encrypter.decryptBytes(encrypted, iv: iv);
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw EncryptionException('Failed to decrypt bytes: $e');
    }
  }

  /// Derives a 32-byte key from a string using SHA-256
  Uint8List _deriveKey(String key) {
    final bytes = utf8.encode(key);
    final hash = sha256.convert(bytes);
    return Uint8List.fromList(hash.bytes);
  }

  /// Generates a random encryption key
  String generateKey() {
    final key = Key.fromSecureRandom(32);
    return base64Encode(key.bytes);
  }
}

class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);
  
  @override
  String toString() => 'EncryptionException: $message';
}
