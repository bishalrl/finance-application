import 'package:android_sms_reader/android_sms_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:another_telephony/telephony.dart';
import 'package:meta/meta.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/sms_filter_service.dart';
import '../../../../core/utils/bank_name_resolver.dart';
import '../../domain/entities/transaction.dart';
import 'sms_background_handler.dart';
import 'remark_extraction_engine.dart';

/// Data source for parsing SMS transactions
/// Android only - iOS doesn't allow SMS access
class SmsParserDataSource {
  final RemarkExtractionEngine _remarkEngine;

  SmsParserDataSource({RemarkExtractionEngine? remarkEngine})
    : _remarkEngine = remarkEngine ?? RemarkExtractionEngine();

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

  /// Initializes background SMS listening using Telephony.
  Future<void> initializeBackgroundTracking() async {
    try {
      final telephony = Telephony.instance;
      final granted = await telephony.requestSmsPermissions;
      if (granted != null && granted) {
        telephony.listenIncomingSms(
          onNewMessage: (SmsMessage message) {
            debugPrint('Finance: Foreground SMS received: ${message.body}');
            // The background handler will also run if configured,
            // or we can manually trigger sync here.
          },
          onBackgroundMessage: backgroundMessageHandler,
        );
        debugPrint('Finance: Background SMS tracking initialized.');
      }
    } catch (e) {
      debugPrint('Finance: Failed to initialize background tracking: $e');
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

        // Check if message is transactional using the new filtering service
        if (SmsFilterService.isLikelyTransaction(sender, body)) {
          final transaction = _parseTransaction(body, sender, date);
          if (transaction != null) {
            debugPrint(
              'Finance: Extracted transaction: ${transaction['amount']} ${transaction['type']} from $sender',
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

  // Removed old _isMarketingMessage, _isTransactionalMessage, and _looksLikeFinancialSender
  // in favor of the more robust core/utils/SmsFilterService

  @visibleForTesting
  Map<String, dynamic>? parseTransactionForTest(
    String body,
    String sender,
    DateTime date,
  ) => _parseTransaction(body, sender, date);

  @visibleForTesting
  String? extractRemarkForTest(String body) => _extractRemark(body);

  @visibleForTesting
  String cleanDescriptionForTest(String body, String? merchant) =>
      _cleanDescription(body, merchant);

  @visibleForTesting
  bool isMarketingMessageForTest(String sender, String body) =>
      !SmsFilterService.isLikelyTransaction(sender, body);

  /// True if the amount at [matchStart] is likely balance/ref, not transaction amount.
  bool _isBalanceOrNonTxnContext(String cleanedBody, int matchStart) {
    const start = 0;
    final end = matchStart.clamp(0, cleanedBody.length);
    final before = cleanedBody.substring(start, end).toLowerCase();
    const balanceMarkers = [
      'avail bal',
      'avail. bal',
      'avl bal',
      'available bal',
      'available balance',
      'balance rs',
      'balance inr',
      'bal rs',
      'bal inr',
      'total bal',
      'closing bal',
      'ledger bal',
      'opening bal',
      'ref no',
      'ref no.',
      'ref:',
      'otp',
      'txn id',
    ];
    return balanceMarkers.any((m) => before.contains(m));
  }

  /// Finds the best transaction amount from body: prefers amount near debited/credited, rejects balance.
  double? _extractTransactionAmount(String cleanedBody) {
    // 1) Amount immediately before/after debited/credited/spent/withdrawn (most reliable)
    final txnPatterns = [
      // NABIL / Nepal: "has been withdrawn by NPR 4,425.00" or "withdrawn by NPR 75.00"
      RegExp(
        r'(?:has been )?withdrawn by\s*(?:NPR|Rs\.?|INR)\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      // SBL / Nepal: "NPR 50.00 withdrawn on 07/12/2025" or "AC ###..., NPR 1,000.00 withdrawn"
      RegExp(
        r'(?:Rs\.?|INR|NPR)\s*([\d,]+\.?\d*)\s*(?:debited|spent|paid|sent to|recharged|withdrawn)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:debited|spent|paid|recharged|withdrawn)\s+(?:by|for|of|with)?\s*(?:Rs\.?|INR|NPR)\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:Rs\.?|INR|NPR)\s*([\d,]+\.?\d*)\s*(?:credited|received|added)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:credited|received|added)\s+(?:with|of)?\s*(?:Rs\.?|INR|NPR)\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:amount|amt\.?)\s*(?:rs\.?|inr|npr)?\s*[:\s]*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:debited from|credited to|trf to|paid to)[\s\S]*?(?:Rs\.?|INR|NPR)\s*([\d,]+\.?\d*)',
        caseSensitive: false,
      ),
    ];

    for (final re in txnPatterns) {
      final match = re.firstMatch(cleanedBody);
      if (match != null) {
        final amountStr = match.group(1);
        if (amountStr == null) continue;
        if (_isBalanceOrNonTxnContext(cleanedBody, match.start)) continue;
        final amount = _parseAmount(amountStr);
        if (amount > 0) return amount;
      }
    }

    // 2) Fallback: any Rs/INR amount not in balance context (e.g. single-amount SMS)
    final anyAmount = RegExp(
      r'(?:Rs\.?|INR|NPR)\s*([\d,]+\.?\d*)',
      caseSensitive: false,
    );
    for (final match in anyAmount.allMatches(cleanedBody)) {
      if (_isBalanceOrNonTxnContext(cleanedBody, match.start)) continue;
      final amount = _parseAmount(match.group(1) ?? '');
      if (amount > 0) return amount;
    }

    return null;
  }

  /// Parses a single SMS message to extract transaction details
  Map<String, dynamic>? _parseTransaction(
    String body,
    String sender,
    DateTime date,
  ) {
    try {
      final cleanedBody = body.replaceAll('\n', ' ').replaceAll('\r', ' ');

      final amount = _extractTransactionAmount(cleanedBody);
      if (amount == null || amount <= 0) return null;

      final type = _determineType(cleanedBody);
      final merchant = _extractMerchant(body);

      // Extract remarks using the new engine
      final transactionType = type == 'credit'
          ? TransactionType.credit
          : TransactionType.debit;
      final remarks = _remarkEngine.extractRemarks(
        body,
        merchant,
        transactionType,
      );

      // Bank name resolution
      final sourceKey = BankNameResolver.normalizeSourceKey(sender);
      final bankName = BankNameResolver.resolve(sender);
      // Normalize: keep title == bank/source label (no type suffix) so
      // grouping by bank/source and by title matches 1:1.
      final txnTitle = (bankName != 'Unknown' ? bankName : sourceKey).trim();

      return {
        'amount': amount,
        'type': type,
        'description': _cleanDescription(body, merchant),
        'merchant': merchant,
        'date': date,
        'category': autoCategorize(body),
        'isAutoCategorized': true,
        'rawMessage': body,
        'remark':
            remarks['rawRemark'] ??
            remarks['systemRemark'], // Backward compatibility
        'rawRemark': remarks['rawRemark'],
        'systemRemark': remarks['systemRemark'],
        'sender': sender,
        'sourceKey': sourceKey,
        'bankName': bankName,
        'title': txnTitle,
        'userRemark': null, // Empty by default — user fills in manually
      };
    } catch (e) {
      debugPrint('Finance: Error parsing SMS: $e');
      return null;
    }
  }

  /// Extracts remark/info from SMS body (e.g. NABIL/SBL: "Remarks: eSewa Load 9849631")
  String? _extractRemark(String body) {
    final patterns = [
      RegExp(r'Remarks:\s*([^\n.]+)', caseSensitive: false),
      RegExp(r'Info:\s*([^\n.]+)', caseSensitive: false),
      RegExp(r'Ref:\s*([^\n.]+)', caseSensitive: false),
      RegExp(r'Note:\s*([^\n.]+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }
    return null;
  }

  /// Cleans up the raw SMS body to create a readable description
  String _cleanDescription(String body, String? merchant) {
    var desc = body.replaceAll('\n', ' ').replaceAll('\r', ' ').trim();

    // If we have a merchant, that's often the best description base
    if (merchant != null && merchant.length > 3) {
      return merchant;
    }

    // Remove known noisy patterns
    final noisePatterns = [
      RegExp(r'A/c\s+X+\d+', caseSensitive: false), // Account numbers
      RegExp(r'Txn\s*ID[:\s]*[a-zA-Z0-9]+', caseSensitive: false), // Txn IDs
      RegExp(
        r'Ref\s*No[:\s]*[a-zA-Z0-9]+',
        caseSensitive: false,
      ), // Ref numbers
      RegExp(r'Ref[:\s]*[a-zA-Z0-9]+', caseSensitive: false), // Ref
      RegExp(r'Avail\s+Bal.*', caseSensitive: false), // Balance info
      RegExp(r'Total\s+Bal.*', caseSensitive: false),
      RegExp(r'Bal[:\s]*\d+', caseSensitive: false), // Short bal
      RegExp(r'OTP\s+\d+', caseSensitive: false), // OTPs
    ];

    for (final pattern in noisePatterns) {
      desc = desc.replaceAll(pattern, '');
    }

    // Collapse multiple spaces
    desc = desc.replaceAll(RegExp(r'\s+'), ' ').trim();

    // If description becomes too short or empty, return first few words of original
    if (desc.length < 5) {
      final words = body.split(' ');
      return words.take(5).join(' ');
    }

    return desc;
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
    final patterns = [
      // 1. Specific Nepal Merchant Patterns (eSewa/Khalti styles)
      RegExp(r'paid\s+to\s+([^\n.]+?)\s*(?:TxnID|\s*$)', caseSensitive: false),
      RegExp(
        r'Successfuuly paid to\s+([^\n.]+?)\s*(?:\.|TxnID|\s*$)',
        caseSensitive: false,
      ),
      RegExp(
        r'Transfer to\s+([^\n.]+?)\s*(?:\.|TxnID|\s*$)',
        caseSensitive: false,
      ),
      RegExp(r'Ref:\s*([^\n.]+?)\s*(?:@|TxnID|\s*$)', caseSensitive: false),

      // 2. Original VPA Patterns
      RegExp(
        r'to\s+VPA\s+([a-zA-Z0-9._-]+@[a-zA-Z0-9_-]+)',
        caseSensitive: false,
      ),
      RegExp(r'VPA\s+([a-zA-Z0-9._-]+@[a-zA-Z0-9_-]+)', caseSensitive: false),

      // 3. Bank Patterns
      RegExp(
        r'at\s+([A-Z0-9][A-Z0-9\s#&-]+?)(?:\s+on|\s+at|\s+using|\.|\s|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'to\s+([A-Z0-9][A-Z0-9\s#&-]+?)(?:\s+on|\s+at|\s+using|\.|\s|UPI|VPA|$)',
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        var merchant = match.group(1)?.trim();
        if (merchant != null && merchant.isNotEmpty) {
          // Clean up common suffix
          merchant = merchant
              .replaceAll(
                RegExp(r'successfully\s+paid\s+to', caseSensitive: false),
                '',
              )
              .trim();

          if (merchant.length > 2 && !_isCommonBankWord(merchant)) {
            return merchant;
          }
        }
      }
    }
    return null;
  }

  bool _isCommonBankWord(String merchant) {
    final upper = merchant.toUpperCase();
    return [
      'BANK',
      'ACCOUNT',
      'CARD',
      'YOUR',
      'INFO',
      'DEBIT',
      'CREDIT',
    ].contains(upper);
  }

  /// Auto-categorizes transaction for charts and filters (Nepal & India).
  String autoCategorize(String description) {
    final desc = description.toLowerCase();

    // 1. --- Specific Nepal Services (Highest Specificity) ---
    // These should override ANY wallet or bank name
    if (desc.contains('nea') || desc.contains('electricity')) return 'Bills';
    if (desc.contains('khanepani') || desc.contains('water')) return 'Bills';
    if (desc.contains('ntc') ||
        desc.contains('ncell') ||
        desc.contains('smart cell') ||
        desc.contains('top up') ||
        desc.contains('topup'))
      return 'Top-up';
    if (desc.contains('worldlink') ||
        desc.contains('vianet') ||
        desc.contains('subisu'))
      return 'Bills';
    if (desc.contains('foodmandu') ||
        desc.contains('bhoj') ||
        desc.contains('swiggy') ||
        desc.contains('zomato'))
      return 'Food';
    if (desc.contains('daraz') || desc.contains('sastodeal')) return 'Shopping';
    if (desc.contains('pathao') ||
        desc.contains('indrive') ||
        desc.contains('uber') ||
        desc.contains('ola'))
      return 'Travel';
    if (desc.contains('qfx') ||
        desc.contains('movie') ||
        desc.contains('cinema'))
      return 'Entertainment';

    // 2. --- Wallet Operations (Distinguish Load vs Payment) ---
    if (desc.contains('load') ||
        desc.contains('trf from bank') ||
        desc.contains('fund trf')) {
      if (desc.contains('esewa') ||
          desc.contains('khalti') ||
          desc.contains('ime pay')) {
        return 'Transfer';
      }
    }

    // 3. --- Income ---
    if (desc.contains('salary') ||
        desc.contains('payroll') ||
        desc.contains('stipend') ||
        desc.contains('interest credit') ||
        desc.contains('bonus')) {
      return 'Income';
    }

    // 4. --- Generic Wallet Mappings (Fallback) ---
    if (desc.contains('esewa') || desc.contains('e-sewa')) return 'eSewa';
    if (desc.contains('khalti')) return 'Khalti';
    if (desc.contains('ime pay')) return 'IME Pay';
    if (desc.contains('ips') || desc.contains('connectips'))
      return 'Connect IPS';
    if (desc.contains('fonepay')) return 'FonePay';

    // 4. --- Bills & Utilities ---
    if (desc.contains('electricity') ||
        desc.contains('water') ||
        desc.contains('gas') ||
        desc.contains('internet') ||
        desc.contains('wifi') ||
        desc.contains('broadband') ||
        desc.contains('tv') ||
        desc.contains('dish home') ||
        desc.contains('netflix') ||
        desc.contains('spotify') ||
        desc.contains('subscription') ||
        desc.contains('insurance') ||
        desc.contains('premium')) {
      return 'Bills';
    }

    // 5. --- Top-up ---
    if (desc.contains('top up') ||
        desc.contains('topup') ||
        desc.contains('top-up') ||
        desc.contains('prepaid topup') ||
        desc.contains('recharge')) {
      return 'Top-up';
    }

    // 6. --- Food & Dining ---
    if (desc.contains('zomato') ||
        desc.contains('swiggy') ||
        desc.contains('food') ||
        desc.contains('restaurant') ||
        desc.contains('cafe') ||
        desc.contains('bakery') ||
        desc.contains('pizza')) {
      return 'Food';
    }

    // 7. --- Travel ---
    if (desc.contains('uber') ||
        desc.contains('ola') ||
        desc.contains('pathao') ||
        desc.contains('indrive') ||
        desc.contains('petrol') ||
        desc.contains('diesel') ||
        desc.contains('fuel') ||
        desc.contains('taxi') ||
        desc.contains('flight') ||
        desc.contains('airline') ||
        desc.contains('bus')) {
      return 'Travel';
    }

    // 8. --- Shopping ---
    if (desc.contains('amazon') ||
        desc.contains('flipkart') ||
        desc.contains('myntra') ||
        desc.contains('daraz') ||
        desc.contains('grocery') ||
        desc.contains('supermarket') ||
        desc.contains('shopping') ||
        desc.contains('mall')) {
      return 'Shopping';
    }

    // 9. --- ATM & Cash ---
    if (desc.contains('atm') || desc.contains('cash withdraw')) return 'ATM';

    // 10. --- Remittance ---
    if (desc.contains('remittance') ||
        desc.contains('remit') ||
        desc.contains('western union') ||
        desc.contains('moneygram') ||
        desc.contains('ime remit')) {
      return 'Remittance';
    }

    // 11. --- Bank / Fund Transfer ---
    if (desc.contains('fund trf') ||
        desc.contains('fund transfer') ||
        desc.contains('ibft') ||
        desc.contains('neft') ||
        desc.contains('imps') ||
        desc.contains('rtgs') ||
        desc.contains('transfer') ||
        desc.contains('trf') ||
        desc.contains('upi')) {
      return 'Bank Transfer';
    }

    // 12. --- Medical ---
    if (desc.contains('hospital') ||
        desc.contains('pharmacy') ||
        desc.contains('medical') ||
        desc.contains('doctor') ||
        desc.contains('clinic')) {
      return 'Medical';
    }

    // 13. --- Entertainment ---
    if (desc.contains('movie') ||
        desc.contains('cinema') ||
        desc.contains('qfx') ||
        desc.contains('netflix') ||
        desc.contains('disney') ||
        desc.contains('entertainment')) {
      return 'Entertainment';
    }

    // 14. --- Generic Payment ---
    if (desc.contains('payment') || desc.contains('paid to')) return 'Payment';

    return 'Other';
  }
}

class SmsParseException implements Exception {
  final String message;
  SmsParseException(this.message);

  @override
  String toString() => 'SmsParseException: $message';
}
