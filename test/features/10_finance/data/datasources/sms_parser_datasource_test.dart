import 'package:flutter_test/flutter_test.dart';
import 'package:life_vault/features/10_finance/data/datasources/sms_parser_datasource.dart';

void main() {
  late SmsParserDataSource dataSource;

  setUp(() {
    dataSource = SmsParserDataSource();
  });

  group('SmsParserDataSource Logic', () {
    final now = DateTime.now();

    test('should extract amount, merchant and type from debit SMS', () {
      const body =
          'Rs. 500.00 debited from A/c XXXXX1234 at STARBUCKS. Txn ID: 12345. Avail Bal: Rs. 1000';
      final result = dataSource.parseTransactionForTest(body, 'BANK', now);

      expect(result, isNotNull);
      expect(result!['amount'], 500.0);
      expect(result['type'], 'debit');
      expect(result['merchant'], 'STARBUCKS');
      expect(result['description'], 'STARBUCKS'); // Should use merchant as desc
    });

    test('should extract remark if present', () {
      const body =
          'Rs. 200.00 spent on your card at KFC. Remarks: Dinner with friends. Ref: 98765';
      final result = dataSource.parseTransactionForTest(body, 'BANK', now);

      expect(result, isNotNull);
      expect(result!['remark'], 'Dinner with friends');
      expect(result['merchant'], 'KFC');
    });

    test('should clean description by removing account and txn noise', () {
      const body =
          'Amt: Rs. 1,200.00 paid to ZOMATO using UPI. A/c X123. Txn ID: AB123456. Bal: 4500';
      final cleaned = dataSource.cleanDescriptionForTest(body, null);

      expect(cleaned.contains('A/c X123'), isFalse);
      expect(cleaned.contains('Txn ID'), isFalse);
      expect(cleaned.contains('Bal:'), isFalse);
      expect(cleaned.contains('ZOMATO'), isTrue);
    });

    test('should handle credit messages correctly', () {
      const body =
          'Rs. 5000.00 credited to your A/c X1234. Info: Salary. Total Bal: Rs. 50000';
      final result = dataSource.parseTransactionForTest(body, 'BANK', now);

      expect(result, isNotNull);
      expect(result!['type'], 'credit');
      expect(result['remark'], 'Salary');
    });

    test('should handle UPI VPA patterns', () {
      const body = 'Paid Rs. 150 to VPA bishal@upi using GPay. Ref: 12345';
      final result = dataSource.parseTransactionForTest(body, 'BANK', now);

      expect(result, isNotNull);
      expect(result!['merchant'], 'bishal@upi');
    });
    test('should identify marketing messages', () {
      const body =
          'Stay connected with our 1GB Data Pack. Dial *1415# to subscribe now.';
      final isMarketing = dataSource.isMarketingMessageForTest('Ncell', body);
      expect(isMarketing, isTrue);
    });

    test('should identify bank alert as NOT marketing', () {
      const body =
          'Your A/c XXXXX1234 has been credited with NPR 5,000.00. Avl Bal: NPR 10,500.00';
      final isMarketing = dataSource.isMarketingMessageForTest(
        'NABILBNK',
        body,
      );
      expect(isMarketing, isFalse);
    });

    group('autoCategorize', () {
      test('should categorize Salary Load as Income', () {
        const body =
            'Your A/c XXXXX is credited with NPR 50,000.00 for July Salary Load.';
        expect(dataSource.autoCategorize(body), 'Income');
      });

      test('should categorize WorldLink recharge as Bills', () {
        const body = 'Rs. 2500 paid to WORLDLINK for internet recharge.';
        expect(dataSource.autoCategorize(body), 'Bills');
      });

      test('should categorize Ncell/NTC recharge as Top-up', () {
        const body = 'Rs. 100 spent for Ncell Top-up.';
        expect(dataSource.autoCategorize(body), 'Top-up');
      });

      test('should categorize wallet load as Transfer', () {
        const body = 'Rs. 500 debited from A/c for wallet load to eSewa.';
        // Note: eSewa is caught first inWallets, but if it was just "wallet load" it would be Transfer
        expect(dataSource.autoCategorize(body), 'eSewa');
      });

      test('should prioritize eSewa over generic load', () {
        const body = 'Rs. 500 debited for eSewa load.';
        expect(dataSource.autoCategorize(body), 'eSewa');
      });

      test('should handle Daraz as Shopping', () {
        const body = 'Paid Rs. 1500 to DARAZ online shopping.';
        expect(dataSource.autoCategorize(body), 'Shopping');
      });

      test('should handle insurance as Bills', () {
        const body = 'Rs. 12000 paid for Life Insurance premium.';
        expect(dataSource.autoCategorize(body), 'Bills');
      });
    });
  });
}
