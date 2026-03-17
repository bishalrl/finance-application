import 'package:flutter/foundation.dart';

/// A robust SMS filtering service to distinguish between financial transactions
/// and promotional/marketing noise, specifically optimized for the Nepal market.
///
/// Five-layer protection:
///   1. Sender Blacklist — known promo senders
///   2. Promo Keyword Exclusion — promotional phrases
///   3. USSD / Telecom Pattern Detection — dial-in codes, data/voice packs
///   4. Transaction Keyword Confirmation — must have strong financial verbs
///   5. Amount Context — currency pattern without promo context
class SmsFilterService {
  // ─── Layer 1: Sender Blacklist ─────────────────────────────────────────────
  static final List<String> _promoSenders = [
    // Nepal: Telecom operators
    'ncell', 'ntc', 'namaste', 'smartcell', 'smart cell', 'hello mobile',
    'ncell app', 'ncell wifi', 'ntc wifi', 'nepal telecom',
    // Nepal: Common promo shortcodes
    '1414', '1415', '1400', '1600', '1601', '1200',
    '31001', '32000', '32001', '34000', '35000', '36000',
    // Generic promo prefixes
    'promo', 'info', 'ad-', 'dm-', 'td-', 'vm-promo',
  ];

  // Also block pure-numeric senders shorter than 6 digits (promo shortcodes)
  static final RegExp _shortNumericSender = RegExp(r'^\d{1,5}$');

  // ─── Layer 2: Promotional Keywords ─────────────────────────────────────────
  static final List<String> _promoKeywords = [
    // English promo
    'unlimited', 'offer', 'offers', 'special offer', 'exclusive offer',
    'promotion', 'promotional', 'promo code', 'promocode',
    'subscribe', 'subscription', 'activate', 'deactivate',
    'free', 'bonus', 'gift', 'win', 'prize', 'lottery', 'winning', 'winner',
    'hurry', 'limited time', 'act now', 'book now', 'buy now',
    'discount', 'cashback', 'cash back', 'voucher', 'coupon',
    'refer', 'referral', 'refer and earn',
    'upgrade now', 'upgrade to',
    // Nepal-specific promo
    'saapati', 'loan service', 'sapati',
    'matra rs', 'rs. ma', 'ma paunuhos', 'paunuhunechha',
    'डायल गर्नुहोस्', 'गर्नुहोस्',
    'dial', 'dial to',
    // Telecom pack/bundle indicators
    'data pack', 'voice pack', 'sms pack', 'combo pack', 'bundle',
    'night pack', 'social pack', 'youtube pack', 'tiktok pack',
    'all nepal', 'all network', 'on-net', 'off-net',
    'pack activated', 'pack subscribed', 'pack renewed',
    'validity', 'valid for', 'valid till',
    'day pack', 'weekly pack', 'monthly pack',
  ];

  // ─── Layer 3: USSD & Telecom Pattern Detection ────────────────────────────
  static final RegExp _ussdRegex = RegExp(r'\*[0-9\*#]{3,}#');

  // Telecom data/voice patterns: "100MB", "2GB", "30 mins", "100 SMS", "7 days"
  static final List<RegExp> _telecomPatterns = [
    RegExp(r'\d+\s*(?:mb|gb|tb)\b', caseSensitive: false), // Data amounts
    RegExp(r'\d+\s*(?:min|mins|minutes)\b', caseSensitive: false), // Voice
    RegExp(r'\d+\s*(?:sms|texts?)\b', caseSensitive: false), // SMS counts
    RegExp(
      r'\d+\s*(?:days?|hrs?|hours?)\s*(?:validity|valid)',
      caseSensitive: false,
    ), // Validity
    RegExp(
      r'(?:rs\.?|npr)\s*\d+\s*(?:ma|maa|for)\s',
      caseSensitive: false,
    ), // "Rs.100 ma" pattern
    RegExp(
      r'(?:internet|data|wifi|hotspot)\s+(?:pack|plan|offer)',
      caseSensitive: false,
    ),
    RegExp(r'(?:voice|call)\s+(?:pack|plan|offer)', caseSensitive: false),
    RegExp(
      r'(?:recharge|topup|top\-?up)\s+(?:of|for)\s+(?:rs\.?|npr)',
      caseSensitive: false,
    ),
  ];

  // ─── Layer 4: Transaction Keywords (Strong Financial Verbs Only) ──────────
  // These MUST appear in a real financial SMS
  static final List<String> _strongTransactionKeywords = [
    // Debit indicators
    'debited', 'withdrawn', 'spent', 'paid to', 'sent to',
    'payment of', 'debited from', 'dr from', 'purchase',
    // Credit indicators
    'credited', 'received', 'deposited', 'cr to', 'added to',
    'credited to', 'received from',
    // Transfer indicators
    'transferred', 'fund trf', 'fund transfer', 'trf to', 'trf from',
    'neft', 'imps', 'rtgs', 'ibft',
    // Transaction identifiers
    'txn id', 'txn no', 'txn ref', 'transaction id',
    'ref no', 'reference no',
  ];

  // Weaker keywords that support but don't confirm on their own
  static final List<String> _supportingKeywords = [
    'a/c',
    'acct',
    'account',
    'balance',
    'bal',
    'avl bal',
    'avail bal',
  ];

  // ─── Layer 5: Promotional Amount Context ──────────────────────────────────
  // Amounts followed by promo words like "OFF", "cashback", etc.
  static final List<RegExp> _promoAmountPatterns = [
    RegExp(
      r'(?:rs\.?|inr|npr)\s*[\d,]+\s*(?:off|discount|cashback|reward|bonus)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:get|earn|win|avail)\s+(?:rs\.?|inr|npr)\s*[\d,]+',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:upto|up to|flat)\s+(?:rs\.?|inr|npr)\s*[\d,]+\s*(?:off|cashback)',
      caseSensitive: false,
    ),
    RegExp(
      r'(?:save|saving)\s+(?:rs\.?|inr|npr)\s*[\d,]+',
      caseSensitive: false,
    ),
  ];

  /// Core logic to determine if an SMS is a valid financial transaction.
  static bool isLikelyTransaction(String sender, String body) {
    final lowerBody = body.toLowerCase();
    final lowerSender = sender.toLowerCase().trim();

    // --- Layer 1: Sender Blacklist ---
    // --- Layer 1: Sender Blacklist ---
    if (_promoSenders.any((s) => lowerSender.contains(s))) {
      // Exception: If body has STRONG transaction keywords, let it proceed to further checks
      final hasStrongTxn = _strongTransactionKeywords.any(
        (k) => lowerBody.contains(k),
      );
      if (!hasStrongTxn) {
        debugPrint('SmsFilter: Skip Layer 1 (Sender Blacklist): $sender');
        return false;
      }
      debugPrint(
        'SmsFilter: Bypass Layer 1 (Sender Blacklist) due to strong keyword: $sender',
      );
    }

    // Block short numeric senders (promo shortcodes like 1415, 32000)
    if (_shortNumericSender.hasMatch(sender.trim())) {
      debugPrint('SmsFilter: Skip Layer 1 (Short Numeric Sender): $sender');
      return false;
    }
    // Also block longer numeric-only senders (e.g. "32000", "36000")
    if (RegExp(r'^\d+$').hasMatch(sender.trim()) && sender.trim().length <= 6) {
      debugPrint('SmsFilter: Skip Layer 1 (Numeric Shortcode): $sender');
      return false;
    }

    // --- Layer 2: Promotional Keywords ---
    if (_promoKeywords.any((k) => lowerBody.contains(k))) {
      // Exception: if the message ALSO has strong transaction keywords,
      // it might be a real transaction mentioning a promo-like word
      // (e.g. "Rs.500 debited for recharge" contains "recharge")
      final hasStrongTxn = _strongTransactionKeywords.any(
        (k) => lowerBody.contains(k),
      );
      if (!hasStrongTxn) {
        debugPrint(
          'SmsFilter: Skip Layer 2 (Promo Keywords): ${body.length > 60 ? body.substring(0, 60) : body}...',
        );
        return false;
      }
      // Has both promo + transaction keywords - check if promo context dominates
      final promoCount = _promoKeywords
          .where((k) => lowerBody.contains(k))
          .length;
      final txnCount = _strongTransactionKeywords
          .where((k) => lowerBody.contains(k))
          .length;
      if (promoCount > txnCount * 2) {
        debugPrint(
          'SmsFilter: Skip Layer 2 (Promo dominates): ${body.length > 60 ? body.substring(0, 60) : body}...',
        );
        return false;
      }
    }

    // --- Layer 3: USSD & Telecom Patterns ---
    if (_ussdRegex.hasMatch(body)) {
      debugPrint(
        'SmsFilter: Skip Layer 3 (USSD Pattern): ${body.length > 60 ? body.substring(0, 60) : body}...',
      );
      return false;
    }

    // Telecom data/voice pack patterns (100MB, 30 mins, 7 days validity, etc.)
    final telecomMatches = _telecomPatterns
        .where((p) => p.hasMatch(body))
        .length;
    if (telecomMatches >= 1) {
      // If it looks like a telecom pack message, only allow if strong txn keywords present
      final hasStrongTxn = _strongTransactionKeywords.any(
        (k) => lowerBody.contains(k),
      );
      if (!hasStrongTxn) {
        debugPrint(
          'SmsFilter: Skip Layer 3 (Telecom Pack Pattern): ${body.length > 60 ? body.substring(0, 60) : body}...',
        );
        return false;
      }
    }

    // --- Layer 4: Transaction Keyword Confirmation ---
    final hasStrongKeyword = _strongTransactionKeywords.any(
      (k) => lowerBody.contains(k),
    );
    final hasSupportingKeyword = _supportingKeywords.any(
      (k) => lowerBody.contains(k),
    );

    if (!hasStrongKeyword && !hasSupportingKeyword) {
      debugPrint(
        'SmsFilter: Skip Layer 4 (No Transaction Keywords): ${body.length > 80 ? body.substring(0, 80) : body}...',
      );
      return false;
    }

    // If only supporting keywords (no strong ones), be more skeptical
    if (!hasStrongKeyword && hasSupportingKeyword) {
      // Needs at least a currency amount pattern to proceed
      final hasAmount = RegExp(
        r'(?:Rs\.?|INR|NPR)\s*[\d,]+',
        caseSensitive: false,
      ).hasMatch(body);
      if (!hasAmount) {
        debugPrint(
          'SmsFilter: Skip Layer 4 (Weak Keywords, No Amount): ${body.length > 80 ? body.substring(0, 80) : body}...',
        );
        return false;
      }
    }

    // --- Layer 5: Amount Context ---
    final amountPattern = RegExp(
      r'(?:Rs\.?|INR|NPR)\s*[\d,]+',
      caseSensitive: false,
    );
    if (!amountPattern.hasMatch(body)) {
      debugPrint(
        'SmsFilter: Skip Layer 5 (No Amount Pattern): ${body.length > 80 ? body.substring(0, 80) : body}...',
      );
      return false;
    }

    // Check if the amount is in a promotional context
    if (_promoAmountPatterns.any((p) => p.hasMatch(body))) {
      final hasStrongTxn = _strongTransactionKeywords.any(
        (k) => lowerBody.contains(k),
      );
      if (!hasStrongTxn) {
        debugPrint(
          'SmsFilter: Skip Layer 5 (Promo Amount Context): ${body.length > 60 ? body.substring(0, 60) : body}...',
        );
        return false;
      }
    }

    return true;
  }
}
