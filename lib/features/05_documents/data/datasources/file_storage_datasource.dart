import 'dart:io';
import 'dart:typed_data';
import 'package:life_vault/core/security/encryption_service.dart';
import 'package:life_vault/core/security/key_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;


/// Data source for file storage operations with encryption
class FileStorageDataSource {
  final EncryptionService _encryptionService;
  final KeyManager _keyManager;

  FileStorageDataSource(this._encryptionService, this._keyManager);

  /// Saves a file with encryption
  /// 
  /// [fileBytes] - The file bytes to save
  /// [fileName] - Original file name
  /// [documentId] - Unique document ID
  /// Returns path to encrypted file
  Future<String> saveEncryptedFile(
    Uint8List fileBytes,
    String fileName,
    String documentId,
  ) async {
    try {
      // Get app documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final documentsDir = Directory(path.join(appDir.path, 'documents'));
      
      if (!await documentsDir.exists()) {
        await documentsDir.create(recursive: true);
      }

      // Get master key for encryption
      final masterKey = await _keyManager.getMasterKey();
      if (masterKey == null) {
        throw Exception('Master key not found');
      }

      // Encrypt file bytes
      final encryptedBytes = await _encryptionService.encryptBytes(fileBytes, masterKey);

      // Save encrypted file
      final fileExtension = path.extension(fileName);
      final encryptedFileName = '$documentId$fileExtension.encrypted';
      final encryptedFilePath = path.join(documentsDir.path, encryptedFileName);
      
      final file = File(encryptedFilePath);
      await file.writeAsBytes(encryptedBytes);

      return encryptedFilePath;
    } catch (e) {
      throw FileStorageException('Failed to save encrypted file: $e');
    }
  }

  /// Retrieves and decrypts a file
  /// 
  /// [encryptedFilePath] - Path to encrypted file
  /// Returns decrypted file bytes
  Future<Uint8List> getDecryptedFile(String encryptedFilePath) async {
    try {
      final masterKey = await _keyManager.getMasterKey();
      if (masterKey == null) {
        throw Exception('Master key not found');
      }

      // Read encrypted file
      final file = File(encryptedFilePath);
      if (!await file.exists()) {
        throw FileNotFoundException('Encrypted file not found: $encryptedFilePath');
      }

      final encryptedBytes = await file.readAsBytes();

      // Decrypt file bytes
      final decryptedBytes = await _encryptionService.decryptBytes(encryptedBytes, masterKey);

      return decryptedBytes;
    } catch (e) {
      throw FileStorageException('Failed to decrypt file: $e');
    }
  }

  /// Deletes an encrypted file
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw FileStorageException('Failed to delete file: $e');
    }
  }

  /// Gets file size
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      throw FileStorageException('Failed to get file size: $e');
    }
  }

  /// Checks if file exists
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Gets documents directory path
  Future<String> getDocumentsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return path.join(appDir.path, 'documents');
  }
}

class FileStorageException implements Exception {
  final String message;
  FileStorageException(this.message);
  
  @override
  String toString() => 'FileStorageException: $message';
}

class FileNotFoundException implements Exception {
  final String message;
  FileNotFoundException(this.message);
  
  @override
  String toString() => 'FileNotFoundException: $message';
}
