import 'package:android_sms_reader/android_sms_reader.dart';
import 'package:flutter/foundation.dart';
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
        count: 500, // Increased limit to scan deeper
      );

      debugPrint(
        'Finance: Fetched ${messages.length} messages from SMS inbox.',
      );

      final transactions = <Map<String, dynamic>>[];

      // Parse each message
      for (final message in messages) {
        final body = message.body;
        final sender = message.address;
        // Convert milliseconds since epoch to DateTime
        final date = DateTime.fromMillisecondsSinceEpoch(message.date);

        // Check if message is transactional
        if (_isTransactionalMessage(sender, body)) {
          final transaction = _parseTransaction(body, sender, date);
          if (transaction != null) {
            debugPrint(
              'Finance: Extracted transaction: ${transaction['amount']} ${transaction['type']}',
            );
            transactions.add(transaction);
          }
        }
      }

      return transactions;
    } catch (e) {
      throw SmsParseException('Failed to parse SMS transactions: $e');
    }
  }

  /// Checks if message is transactional
  bool _isTransactionalMessage(String sender, String body) {
    final bodyLower = body.toLowerCase();

    // Keywords indicating a financial transaction
    final transactionKeywords = [
      'debited',
      'credited',
      'spent',
      'paid',
      'sent to',
      'received',
      'added',
      'rs.',
      'inr',
      'npr',
      'vpa',
      'upi',
      'txn',
      'transaction',
      'transfer',
      'withdrawn',
      'a/c',
      'account',
      'balance',
      'available limit',
      'spent on',
      'payment of',
      'recharged',
      'bill payment',
    ];

    // Common bank indicators
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
      'paytm',
      'phonepe',
      'gpay',
      'amazonpay',
      'slice',
      'uni',
      'cred',
    ];

    final hasTransactionKeyword = transactionKeywords.any(
      (keyword) => bodyLower.contains(keyword),
    );
    final looksLikeBank =
        bankKeywords.any((keyword) => bodyLower.contains(keyword)) ||
        _isBankNumber(sender);

    return hasTransactionKeyword &&
        (looksLikeBank ||
            body.contains(RegExp(r'Rs\.?\s*\d+', caseSensitive: false)));
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
  Map<String, dynamic>? _parseTransaction(
    String body,
    String sender,
    DateTime date,
  ) {
    try {
      // Clean up body for easier parsing
      final cleanedBody = body.replaceAll('\n', ' ').replaceAll('\r', ' ');

      // Patterns list: most specific to most general
      final patterns = [
        // Pattern: Rs. 500.00 debited/spent
        RegExp(
          r'(?:Rs\.?|INR|NPR)\s*([\d,]+\.?\d*)\s*(?:debited|spent|paid|sent to|recharged)',
          caseSensitive: false,
        ),
        // Pattern: debited/spent/paid by Rs. 500.00
        RegExp(
          r'(?:debited|spent|paid|recharged)\s+(?:by|for|of)?\s*(?:Rs\.?|INR|NPR)\s*([\d,]+\.?\d*)',
          caseSensitive: false,
        ),
        // Pattern: received/added/credited Rs. 500.00
        RegExp(
          r'(?:received|added|credited)\s*(?:of|Rs\.?|INR|NPR)*\s*([\d,]+\.?\d*)',
          caseSensitive: false,
        ),
        // Pattern: Rs. 500.00 credited
        RegExp(
          r'(?:Rs\.?|INR|NPR)\s*([\d,]+\.?\d*)\s*(?:credited|received|added)',
          caseSensitive: false,
        ),
        // Pattern: Simple Amount with currency
        RegExp(r'(?:Rs\.?|INR|NPR)\s*([\d,]+\.?\d*)', caseSensitive: false),
      ];

      for (var i = 0; i < patterns.length; i++) {
        final match = patterns[i].firstMatch(cleanedBody);
        if (match != null) {
          final amountStr = match.group(1);
          if (amountStr == null) continue;

          final amount = _parseAmount(amountStr);
          if (amount <= 0) continue;

          final type = _determineType(cleanedBody);

          return {
            'amount': amount,
            'type': type,
            'description': body,
            'merchant': _extractMerchant(body),
            'date': date,
            'category': autoCategorize(body),
            'isAutoCategorized': true,
          };
        }
      }

      return null;
    } catch (e) {
      debugPrint('Finance: Error parsing SMS: $e');
      return null;
    }
  }

  String _determineType(String body) {
    final bodyLower = body.toLowerCase();
    if (bodyLower.contains('debited') ||
        bodyLower.contains('spent') ||
        bodyLower.contains('paid') ||
        bodyLower.contains('sent to') ||
        bodyLower.contains('withdrawn') ||
        bodyLower.contains('payment of')) {
      return 'debit';
    }
    if (bodyLower.contains('credited') ||
        bodyLower.contains('received') ||
        bodyLower.contains('added')) {
      return 'credit';
    }
    return 'debit'; // Default
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
    final patterns = [
      RegExp(
        r'at\s+([A-Z0-9][A-Z0-9\s#&-]+?)(?:\s+on|\s+at|\s+using|\.|\s|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'to\s+([A-Z0-9][A-Z0-9\s#&-]+?)(?:\s+on|\s+at|\s+using|\.|\s|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'paid\s+to\s+([A-Z0-9][A-Z0-9\s#&-]+?)(?:\s+on|\s+at|\s+using|\.|\s|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'using\s+[A-Z]+\s+card\s+at\s+([A-Z0-9][A-Z0-9\s#&-]+?)(?:\s+on|\s+at|\s+using|\.|\s|$)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final merchant = match.group(1)?.trim();
        if (merchant != null && merchant.isNotEmpty && merchant.length > 2) {
          // Avoid common bank words as merchants
          if (!['BANK', 'ACCOUNT', 'CARD'].contains(merchant.toUpperCase())) {
            return merchant;
          }
        }
      }
    }
    return null;
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
