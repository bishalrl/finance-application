import '../../domain/entities/transaction.dart';

/// Engine for extracting raw and system remarks from SMS transaction messages
class RemarkExtractionEngine {
  /// Extracts both raw_remark and system_remark from SMS body
  Map<String, String?> extractRemarks(
    String smsBody,
    String? merchant,
    TransactionType type,
  ) {
    final rawRemark = _extractRawRemark(smsBody, merchant);
    final systemRemark = _generateSystemRemark(
      smsBody,
      rawRemark,
      merchant,
      type,
    );

    return {
      'rawRemark': rawRemark,
      'systemRemark': systemRemark,
    };
  }

  /// Extracts raw remark - literal text from SMS (merchant name, reference, etc.)
  String? _extractRawRemark(String body, String? merchant) {
    // 1. Look for explicit remark patterns
    final explicitPatterns = [
      RegExp(r'Remarks:\s*([^\n.]+)', caseSensitive: false),
      RegExp(r'Info:\s*([^\n.]+)', caseSensitive: false),
      RegExp(r'Ref:\s*([^\n.]+)', caseSensitive: false),
      RegExp(r'Note:\s*([^\n.]+)', caseSensitive: false),
      RegExp(r'Reference:\s*([^\n.]+)', caseSensitive: false),
    ];

    for (final pattern in explicitPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final remark = match.group(1)?.trim();
        if (remark != null && remark.isNotEmpty) {
          return remark;
        }
      }
    }

    // 2. Extract ATM references (e.g., "ATM XX4589")
    final atmPattern = RegExp(
      r'ATM\s+([A-Z0-9]+(?:\s+[A-Z0-9]+)?)',
      caseSensitive: false,
    );
    final atmMatch = atmPattern.firstMatch(body);
    if (atmMatch != null) {
      return 'ATM ${atmMatch.group(1)?.trim()}';
    }

    // 3. Extract merchant names from common patterns
    final merchantPatterns = [
      RegExp(r'at\s+([A-Z0-9][A-Z0-9\s#&-]+?)(?:\s+on|\s+at|\s+using|\.|\s|$)', caseSensitive: false),
      RegExp(r'to\s+([A-Z0-9][A-Z0-9\s#&-]+?)(?:\s+on|\s+at|\s+using|\.|\s|UPI|VPA|$)', caseSensitive: false),
      RegExp(r'paid\s+to\s+([A-Z0-9][A-Z0-9\s#&-]+?)(?:\s+on|\s+at|\s+using|\.|\s|$)', caseSensitive: false),
      RegExp(r'debited\s+at\s+([A-Z0-9][A-Z0-9\s#&-]+?)(?:\s+on|\s+at|\s+using|\.|\s|$)', caseSensitive: false),
    ];

    for (final pattern in merchantPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final extracted = match.group(1)?.trim();
        if (extracted != null &&
            extracted.isNotEmpty &&
            extracted.length > 2 &&
            !_isCommonBankWord(extracted)) {
          return extracted;
        }
      }
    }

    // 4. Extract UPI/VPA references
    final upiPatterns = [
      RegExp(r'VPA\s+([a-zA-Z0-9._-]+@[a-zA-Z0-9_-]+)', caseSensitive: false),
      RegExp(r'to\s+VPA\s+([a-zA-Z0-9._-]+@[a-zA-Z0-9_-]+)', caseSensitive: false),
      RegExp(r'UPI\s+ID[:\s]+([a-zA-Z0-9._-]+@[a-zA-Z0-9_-]+)', caseSensitive: false),
    ];

    for (final pattern in upiPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return match.group(1)?.trim();
      }
    }

    // 5. Fallback to merchant name if available
    if (merchant != null && merchant.isNotEmpty && merchant.length > 2) {
      return merchant;
    }

    return null;
  }

  /// Generates system remark - human-friendly explanation of transaction purpose
  String _generateSystemRemark(
    String body,
    String? rawRemark,
    String? merchant,
    TransactionType type,
  ) {
    final bodyLower = body.toLowerCase();
    final rawRemarkLower = rawRemark?.toLowerCase() ?? '';
    final merchantLower = merchant?.toLowerCase() ?? '';

    // ATM withdrawals
    if (bodyLower.contains('atm') ||
        bodyLower.contains('cash withdraw') ||
        bodyLower.contains('withdrawn from atm')) {
      return 'Cash withdrawal';
    }

    // Store purchases
    if (bodyLower.contains('debited at') ||
        bodyLower.contains('at ') ||
        (bodyLower.contains('purchase') && merchant != null)) {
      if (merchant != null && merchant.length > 2) {
        return 'Store purchase';
      }
      return 'Store purchase';
    }

    // UPI payments
    if (bodyLower.contains('upi') ||
        bodyLower.contains('vpa') ||
        bodyLower.contains('@paytm') ||
        bodyLower.contains('@gpay') ||
        bodyLower.contains('@phonepe')) {
      return 'UPI payment';
    }

    // Recharges and top-ups
    if (bodyLower.contains('recharged') ||
        bodyLower.contains('topup') ||
        bodyLower.contains('top up') ||
        bodyLower.contains('prepaid') ||
        bodyLower.contains('load') ||
        rawRemarkLower.contains('recharge') ||
        rawRemarkLower.contains('topup')) {
      if (bodyLower.contains('data') || bodyLower.contains('internet')) {
        return 'Data recharge';
      }
      return 'Mobile recharge';
    }

    // Money transfers
    if (bodyLower.contains('transferred to') ||
        bodyLower.contains('sent to') ||
        bodyLower.contains('fund trf') ||
        bodyLower.contains('fund transfer') ||
        bodyLower.contains('trf to') ||
        bodyLower.contains('neft') ||
        bodyLower.contains('imps') ||
        bodyLower.contains('rtgs')) {
      return 'Money transfer';
    }

    // Bill payments
    if (bodyLower.contains('bill payment') ||
        bodyLower.contains('bill paid') ||
        bodyLower.contains('utility') ||
        bodyLower.contains('electricity') ||
        bodyLower.contains('water') ||
        bodyLower.contains('gas')) {
      return 'Bill payment';
    }

    // Salary/Income (credits)
    if (type == TransactionType.credit) {
      if (bodyLower.contains('salary') ||
          bodyLower.contains('credited') ||
          bodyLower.contains('income')) {
        return 'Salary/Income';
      }
      if (bodyLower.contains('refund') || bodyLower.contains('reversed')) {
        return 'Refund';
      }
      return 'Money received';
    }

    // Refunds (debits that are refunds)
    if (bodyLower.contains('refund') || bodyLower.contains('reversed')) {
      return 'Refund';
    }

    // Online payments
    if (bodyLower.contains('online payment') ||
        bodyLower.contains('payment gateway') ||
        bodyLower.contains('card payment')) {
      return 'Online payment';
    }

    // Generic payment
    if (bodyLower.contains('paid to') || bodyLower.contains('payment of')) {
      if (merchant != null && merchant.length > 2) {
        return 'Payment to $merchant';
      }
      return 'Payment';
    }

    // Default based on type
    if (type == TransactionType.credit) {
      return 'Money received';
    } else {
      if (merchant != null && merchant.length > 2) {
        return 'Payment to $merchant';
      }
      return 'Expense';
    }
  }

  /// Checks if extracted text is a common bank word (should be filtered out)
  bool _isCommonBankWord(String text) {
    final upper = text.toUpperCase();
    return [
      'BANK',
      'ACCOUNT',
      'CARD',
      'YOUR',
      'INFO',
      'DEBIT',
      'CREDIT',
      'ALERT',
      'SMS',
    ].contains(upper);
  }
}
