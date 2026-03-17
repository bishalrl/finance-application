/// Resolves SMS sender IDs to human-readable bank/wallet names
/// and normalizes sender strings to source keys.
class BankNameResolver {
  BankNameResolver._();

  /// Normalize sender to uppercase key with no spaces/symbols.
  /// e.g. "Ncell App" -> "NCELLAPP", "NABIL_ALERT" -> "NABILALERT"
  static String normalizeSourceKey(String sender) {
    return sender.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  }

  /// Resolve sender ID to a human-readable bank/wallet name.
  /// Returns "Unknown" if no match.
  static String resolve(String sender) {
    final key = normalizeSourceKey(sender);

    // Try exact prefix matches first, then contains
    for (final entry in _senderMap.entries) {
      if (key.contains(entry.key)) return entry.value;
    }

    // Fallback: try to extract a recognizable word from sender
    final lowerSender = sender.toLowerCase();
    for (final entry in _fallbackMap.entries) {
      if (lowerSender.contains(entry.key)) return entry.value;
    }

    return 'Unknown';
  }

  // ─── Sender -> Bank Name Mapping (normalized keys) ─────────────────────────
  // Keys are uppercase, no spaces/symbols (matching normalizeSourceKey output)
  static const Map<String, String> _senderMap = {
    // Nepal: Commercial Banks
    'NABIL': 'Nabil Bank',
    'NICASIA': 'NIC Asia Bank',
    'ALNICA': 'NIC Asia Bank', // ALNICALERT
    'SBL': 'Siddhartha Bank',
    'SIDDHARTHA': 'Siddhartha Bank',
    'RBB': 'Rastriya Banijya Bank',
    'ADBL': 'Agriculture Dev Bank',
    'NBL': 'Nepal Bank Ltd',
    'NEPALBANK': 'Nepal Bank Ltd',
    'NIBL': 'Nepal Investment Bank',
    'EVEREST': 'Everest Bank',
    'HIMALAYAN': 'Himalayan Bank',
    'PRABHU': 'Prabhu Bank',
    'LAXMI': 'Laxmi Sunrise Bank',
    'SUNRISE': 'Laxmi Sunrise Bank',
    'GLOBALIME': 'Global IME Bank',
    'CITIZENS': 'Citizens Bank',
    'PRIME': 'Prime Commercial Bank',
    'NMB': 'NMB Bank',
    'SANIMA': 'Sanima Bank',
    'MACHHAPUCHCHHRE': 'Machhapuchchhre Bank',
    'KUMARI': 'Kumari Bank',
    'MEGA': 'Mega Bank',
    'CENTURY': 'Century Bank',
    'CIVIL': 'Civil Bank',
    'JANATA': 'Janata Bank',
    'STANDARD': 'Standard Chartered',

    // Nepal: Wallets & Digital Payments
    'ESEWA': 'eSewa',
    'KHALTI': 'Khalti',
    'IMEPAY': 'IME Pay',
    'IPAY': 'IME Pay',
    'CONNECTIPS': 'Connect IPS',
    'FONEPAY': 'FonePay',

    // India: Major Banks
    'HDFCBK': 'HDFC Bank',
    'HDFC': 'HDFC Bank',
    'ICICIB': 'ICICI Bank',
    'ICICI': 'ICICI Bank',
    'AXISBK': 'Axis Bank',
    'AXIS': 'Axis Bank',
    'SBIIN': 'State Bank of India',
    'SBI': 'State Bank of India',
    'PNBBNK': 'Punjab National Bank',
    'KOTAK': 'Kotak Mahindra Bank',
    'INDUSIND': 'IndusInd Bank',
    'YESBANK': 'Yes Bank',
    'BOB': 'Bank of Baroda',
    'CANARA': 'Canara Bank',
    'UNION': 'Union Bank',

    // India: Wallets
    'PAYTM': 'Paytm',
    'PHONEPE': 'PhonePe',
    'GPAY': 'Google Pay',
  };

  // Fallback: lowercase partial match on original sender
  static const Map<String, String> _fallbackMap = {
    'nabil': 'Nabil Bank',
    'nic asia': 'NIC Asia Bank',
    'siddhartha': 'Siddhartha Bank',
    'rastriya': 'Rastriya Banijya Bank',
    'agriculture': 'Agriculture Dev Bank',
    'everest': 'Everest Bank',
    'himalayan': 'Himalayan Bank',
    'prabhu': 'Prabhu Bank',
    'laxmi': 'Laxmi Sunrise Bank',
    'global ime': 'Global IME Bank',
    'citizens': 'Citizens Bank',
    'prime': 'Prime Commercial Bank',
    'sanima': 'Sanima Bank',
    'kumari': 'Kumari Bank',
    'esewa': 'eSewa',
    'khalti': 'Khalti',
    'bank': 'Bank', // Generic fallback for anything with "bank"
  };
}
