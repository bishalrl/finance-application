import 'package:flutter_test/flutter_test.dart';
import 'package:life_vault/core/utils/sms_filter_service.dart';

void main() {
  group('SmsFilterService', () {
    // ─── Layer 1: Sender Blacklist ─────────────────────────────────────────
    test('should filter out Ncell promotional messages', () {
      const sender = 'Ncell';
      const body =
          'Unlimited All Nepal Voice Pack ma paunuhos! Dial *17118# to activate. Matra Rs.299.';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isFalse);
    });

    test('should filter out Ncell App sender', () {
      const sender = 'Ncell App';
      const body = 'Get 2GB data at Rs.195 only! Valid for 7 days.';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isFalse);
    });

    test('should filter out Ncell Saapati (loan) ads', () {
      const sender = 'Ncell';
      const body =
          'Get Rs. 40 Saapati now! Dial *9988# to avail this loan service.';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isFalse);
    });

    test('should filter out NTC pack offers', () {
      const sender = 'Namaste';
      const body =
          'Stay connected with our 1GB Data Pack. Dial *1415# to subscribe now.';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isFalse);
    });

    test('should filter out short numeric senders (like 1415)', () {
      const sender = '1415';
      const body =
          'Your balance is low. Recharge now to enjoy uninterrupted services.';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isFalse);
    });

    test('should filter out longer numeric shortcodes (like 32000)', () {
      const sender = '32000';
      const body = 'You have received Rs.100 data pack. 500MB for 3 days validity.';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isFalse);
    });

    // ─── Layer 2: Promo Keywords ───────────────────────────────────────────
    test('should filter out offer messages from unknown senders', () {
      const sender = 'ANY_SENDER';
      const body =
          'Congratulations! You have won a free gift voucher of Rs. 500. Hurry, claim now!';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isFalse);
    });

    test('should filter out data pack activation messages', () {
      const sender = 'TELECOM';
      const body = 'Your 1GB data pack has been activated. Rs.120 deducted. Valid for 7 days.';
      // Even though "deducted" is not in our strong keywords, "data pack" + "valid for" should catch it
      expect(SmsFilterService.isLikelyTransaction(sender, body), isFalse);
    });

    test('should filter out voice pack subscription', () {
      const sender = 'TELECOM';
      const body = 'All Nepal voice pack subscribed. Rs.195 charged. 100 mins for 7 days validity.';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isFalse);
    });

    // ─── Layer 3: USSD Patterns ────────────────────────────────────────────
    test('should filter out USSD dial messages', () {
      const sender = 'UNKNOWN';
      const body = 'Dial *123*1# for a special surprise offer!';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isFalse);
    });

    // ─── Layer 3: Telecom Patterns ─────────────────────────────────────────
    test('should filter out messages with MB/GB amounts', () {
      const sender = 'SERVICE';
      const body = 'You got 500MB data. Rs.100 has been charged to your account.';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isFalse);
    });

    test('should filter out messages with mins/days patterns', () {
      const sender = 'SERVICE';
      const body = 'Rs.195 charged. You got 200 mins and 1GB for 28 days validity.';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isFalse);
    });

    // ─── Layer 4: OTP and non-financial ────────────────────────────────────
    test('should filter out OTP messages', () {
      const sender = 'NIC ASIA';
      const body =
          'Dear Cardholder, Your Card Activation OTP is 858952. Thank you. NIC ASIA';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isFalse);
    });

    test('should filter out fixed deposit notifications', () {
      const sender = 'NIC ASIA';
      const body =
          'Dear BISHAL ARYAL, your fixed deposit request for amount 5000.0 has been approved for 3 months with Interest rate {interestRate}. Remarks: open';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isFalse);
    });

    // ─── Valid Transactions (should PASS) ──────────────────────────────────
    test('should accept valid bank credit alerts', () {
      const sender = 'NABILBNK';
      const body =
          'Your A/c XXXXX1234 has been credited with NPR 5,000.00 on 2024-02-06. Available Bal: NPR 10,500.00';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isTrue);
    });

    test('should accept valid bank debit alerts', () {
      const sender = 'NICASIA';
      const body =
          'Txn: Debit. Amt: Rs. 1,200.00 paid to ZOMATO. Ref No: 123456. A/c X1234. Avl Bal: Rs. 4,500.';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isTrue);
    });

    test('should accept valid wallet load alerts', () {
      const sender = 'ESEWA';
      const body =
          'NPR 1,000.00 has been debited from your account for eSewa Load. Txn ID: AB12345. Bal: NPR 200.';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isTrue);
    });

    test('should accept valid ATM withdrawal alerts', () {
      const sender = 'SBL';
      const body =
          'NPR 5,000.00 withdrawn from your A/c XXXX1234 at ATM SBL016130N. Avail Bal: NPR 12,000.00';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isTrue);
    });

    test('should accept valid fund transfer alerts', () {
      const sender = 'NABIL_ALERT';
      const body =
          'NPR 2,000.00 has been debited from your A/c for Fund Trf to TOP UP PAYABLE-NT Prepaid Topup. Ref: 123456';
      expect(SmsFilterService.isLikelyTransaction(sender, body), isTrue);
    });

    // ─── Edge Cases ────────────────────────────────────────────────────────
    test('should accept real recharge debit (bank SMS about recharge)', () {
      const sender = 'SBL_ALERT';
      const body =
          'Rs.100.00 debited from your A/c XXXX5678 for recharge. Txn ID: 987654. Avl Bal: Rs.3,400.';
      // Contains "recharge" (promo keyword) BUT also "debited" (strong txn keyword)
      expect(SmsFilterService.isLikelyTransaction(sender, body), isTrue);
    });
  });
}
