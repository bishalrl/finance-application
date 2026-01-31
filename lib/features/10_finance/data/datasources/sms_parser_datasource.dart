import 'package:android_sms_reader/android_sms_reader.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/errors/exceptions.dart';

/// Data source for parsing SMS transactions
/// Android only - iOS doesn't allow SMS access
class SmsParserDataSource {
  /// Requests SMS read permission
  Future<bool> requestPermission() async {
    try {
      // Use android_sms_reader's built-in permission handler
      final granted = await AndroidSMSReader.requestPermissions();
      if (!granted) {
        // Fallback to permission_handler
        final status = await Permission.sms.request();
        return status.isGranted;
      }
      return granted;
    } catch (e) {
      return false;
    }
  }

  /// Checks if SMS permission is granted
  Future<bool> hasPermission() async {
    try {
      final status = await Permission.sms.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Parses SMS messages to extract transactions
  Future<List<Map<String, dynamic>>> parseSmsTransactions() async {
    try {
      // Check permission first
      if (!await hasPermission()) {
        if (!await requestPermission()) {
          throw PermissionException('SMS permission not granted');
        }
      }

      // Get all SMS messages from inbox
      final messages = await AndroidSMSReader.fetchMessages(
        type: AndroidSMSType.inbox,
        start: 0,
        count: 100, // Limit to recent 100 messages
      );

      final transactions = <Map<String, dynamic>>[];

      // Parse each message
      for (final message in messages) {
        final body = message.body;
        final sender = message.address;
        // Convert milliseconds since epoch to DateTime
        final date = DateTime.fromMillisecondsSinceEpoch(message.date);
        
        // Check if message is from a bank (common Indian bank numbers)
        if (_isBankMessage(sender, body)) {
          final transaction = _parseTransaction(
            body, 
            sender, 
            date,
          );
          if (transaction != null) {
            transactions.add(transaction);
          }
        }
      }

      return transactions;
    } catch (e) {
      throw SmsParseException('Failed to parse SMS transactions: $e');
    }
  }

  /// Checks if message is from a bank
  bool _isBankMessage(String sender, String body) {
    // Common Indian bank SMS sender patterns
    final bankKeywords = [
      'bank',
      'hdfc',
      'icici',
      'sbi',
      'axis',
      'pnb',
      'bob',
      'canara',
      'union',
      'kotak',
    ];

    final bodyLower = body.toLowerCase();
    return bankKeywords.any((keyword) => bodyLower.contains(keyword)) ||
        _isBankNumber(sender);
  }

  /// Checks if sender number is a known bank number
  bool _isBankNumber(String sender) {
    // Common Indian bank SMS numbers (simplified - real implementation would have full list)
    final bankNumbers = [
      'VM-AXISBK',
      'VM-HDFCBK',
      'VM-ICICIB',
      'SBIIN',
      'PNBBNK',
    ];
    return bankNumbers.any((num) => sender.contains(num));
  }

  /// Parses a single SMS message to extract transaction details
  Map<String, dynamic>? _parseTransaction(String body, String sender, DateTime date) {
    try {
      // Pattern 1: INR XX.XX debited/credited
      var match = RegExp(r'INR\s*([\d,]+\.?\d*)\s*(debited|credited)', caseSensitive: false).firstMatch(body);
      if (match != null) {
        final amount = _parseAmount(match.group(1) ?? '0');
        final type = match.group(2)?.toLowerCase() ?? 'debited';
        
        return {
          'amount': amount,
          'type': type.contains('credit') ? 'credit' : 'debit',
          'description': body,
          'merchant': _extractMerchant(body),
          'date': date,
          'category': autoCategorize(body),
          'isAutoCategorized': true,
        };
      }

      // Pattern 2: Rs.XX.XX spent/paid
      match = RegExp(r'Rs\.?\s*([\d,]+\.?\d*)\s*(spent|paid)', caseSensitive: false).firstMatch(body);
      if (match != null) {
        final amount = _parseAmount(match.group(1) ?? '0');
        
        return {
          'amount': amount,
          'type': 'debit',
          'description': body,
          'merchant': _extractMerchant(body),
          'date': date,
          'category': autoCategorize(body),
          'isAutoCategorized': true,
        };
      }

      // Pattern 3: Amount with debited/credited
      match = RegExp(r'(\d+\.\d{2})\s*(debited|credited)', caseSensitive: false).firstMatch(body);
      if (match != null) {
        final amount = double.tryParse(match.group(1) ?? '0') ?? 0.0;
        final type = match.group(2)?.toLowerCase() ?? 'debited';
        
        return {
          'amount': amount,
          'type': type.contains('credit') ? 'credit' : 'debit',
          'description': body,
          'merchant': _extractMerchant(body),
          'date': date,
          'category': autoCategorize(body),
          'isAutoCategorized': true,
        };
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Parses amount string to double
  double _parseAmount(String amountStr) {
    try {
      // Remove commas and parse
      final cleaned = amountStr.replaceAll(',', '');
      return double.tryParse(cleaned) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Extracts merchant name from SMS body
  String? _extractMerchant(String body) {
    // Try to extract merchant name from common patterns
    final merchantPattern = RegExp(r'at\s+([A-Z][A-Z\s]+?)(?:\s|$)', caseSensitive: false);
    final match = merchantPattern.firstMatch(body);
    return match?.group(1)?.trim();
  }

  /// Auto-categorizes transaction based on description
  String autoCategorize(String description) {
    final desc = description.toLowerCase();
    
    // Food & Dining
    if (desc.contains('zomato') || 
        desc.contains('swiggy') || 
        desc.contains('restaurant') ||
        desc.contains('food') ||
        desc.contains('cafe')) {
      return 'Food';
    }
    
    // Travel & Transportation
    if (desc.contains('uber') || 
        desc.contains('ola') || 
        desc.contains('petrol') ||
        desc.contains('diesel') ||
        desc.contains('fuel') ||
        desc.contains('taxi')) {
      return 'Travel';
    }
    
    // Shopping
    if (desc.contains('amazon') || 
        desc.contains('flipkart') || 
        desc.contains('myntra') ||
        desc.contains('shopping') ||
        desc.contains('mall')) {
      return 'Shopping';
    }
    
    // Bills & Utilities
    if (desc.contains('bill') ||
        desc.contains('electricity') ||
        desc.contains('water') ||
        desc.contains('gas') ||
        desc.contains('internet') ||
        desc.contains('phone')) {
      return 'Bills';
    }
    
    // Medical
    if (desc.contains('hospital') ||
        desc.contains('pharmacy') ||
        desc.contains('medical') ||
        desc.contains('doctor')) {
      return 'Medical';
    }
    
    // Entertainment
    if (desc.contains('movie') ||
        desc.contains('netflix') ||
        desc.contains('spotify') ||
        desc.contains('entertainment')) {
      return 'Entertainment';
    }
    
    return 'Other';
  }
}

class SmsParseException implements Exception {
  final String message;
  SmsParseException(this.message);
  
  @override
  String toString() => 'SmsParseException: $message';
}
