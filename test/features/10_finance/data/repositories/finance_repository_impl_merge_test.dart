import 'package:flutter_test/flutter_test.dart';
import 'package:life_vault/features/10_finance/data/repositories/finance_repository_impl.dart';
import 'package:life_vault/features/10_finance/domain/entities/transaction.dart';

void main() {
  group('FinanceRepositoryImpl.mergeNewTransactions', () {
    test('adds only new ids and keeps existing ids intact', () {
      final now = DateTime(2026, 3, 8);

      final parsedMaps = <Map<String, dynamic>>[
        {'id': 'a', 'date': now, 'amount': 10, 'type': 'debit'},
        {'id': 'b', 'date': now, 'amount': 20, 'type': 'debit'},
        {'id': 'a', 'date': now, 'amount': 10, 'type': 'debit'}, // duplicate
        {'id': 'c', 'date': now, 'amount': 30, 'type': 'credit'},
      ];

      final existingIds = <String>{'b'}; // already stored

      final res = FinanceRepositoryImpl.mergeNewTransactions(
        parsedMaps: parsedMaps,
        existingIds: existingIds,
        idFromMap: (m) => m['id'] as String,
        buildTransaction: (m) {
          return Transaction(
            id: m['id'] as String,
            amount: (m['amount'] as num).toDouble(),
            type: (m['type'] as String) == 'credit'
                ? TransactionType.credit
                : TransactionType.debit,
            description: 't',
            date: m['date'] as DateTime,
          );
        },
      );

      expect(res.skipped, 2); // 'b' existing + second 'a' duplicate
      expect(res.newTransactions.map((t) => t.id).toList(), ['a', 'c']);

      // Existing set mutated to include new ids (how repo keeps add-only behavior).
      expect(existingIds.contains('b'), isTrue);
      expect(existingIds.contains('a'), isTrue);
      expect(existingIds.contains('c'), isTrue);
    });

    test('does not add when buildTransaction returns null', () {
      final parsedMaps = <Map<String, dynamic>>[
        {'id': 'a'},
        {'id': 'b'},
      ];
      final existingIds = <String>{};

      final res = FinanceRepositoryImpl.mergeNewTransactions(
        parsedMaps: parsedMaps,
        existingIds: existingIds,
        idFromMap: (m) => m['id'] as String,
        buildTransaction: (m) => null,
      );

      expect(res.newTransactions, isEmpty);
      expect(res.skipped, 0);
      // IDs are still tracked so we don't re-process them in the same run.
      expect(existingIds, containsAll(['a', 'b']));
    });
  });
}

