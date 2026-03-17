import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:life_vault/core/errors/failures.dart';
import 'package:life_vault/core/errors/exceptions.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/time_period.dart';
import '../../domain/repositories/finance_repository.dart';
import '../datasources/finance_local_datasource.dart';
import '../datasources/sms_parser_datasource.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceLocalDataSource _localDataSource;
  final SmsParserDataSource _smsParserDataSource;

  FinanceRepositoryImpl({
    required FinanceLocalDataSource localDataSource,
    required SmsParserDataSource smsParserDataSource,
  }) : _localDataSource = localDataSource,
       _smsParserDataSource = smsParserDataSource;

  @override
  Future<Either<Failure, List<Transaction>>> getAllTransactions() async {
    try {
      final list = await _localDataSource.getAllTransactions();
      return Right(list);
    } catch (e) {
      return Left(CacheFailure('Failed to get transactions: $e'));
    }
  }

  @override
  Future<Either<Failure, Transaction>> addTransaction(
    Transaction transaction,
  ) async {
    try {
      await _localDataSource.saveTransaction(transaction);
      return Right(transaction);
    } catch (e) {
      return Left(CacheFailure('Failed to add transaction: $e'));
    }
  }

  @override
  Future<Either<Failure, Transaction>> updateCategory(
    String id,
    String category,
  ) async {
    try {
      await _localDataSource.updateCategory(id, category);
      final t = await _localDataSource.getTransactionById(id);
      if (t == null) return Left(CacheFailure('Transaction not found'));
      return Right(t);
    } catch (e) {
      return Left(CacheFailure('Failed to update category: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getTransactionsByMonth(
    int year,
    int month,
  ) async {
    try {
      final list = await _localDataSource.getTransactionsByMonth(year, month);
      return Right(list);
    } catch (e) {
      return Left(CacheFailure('Failed to get monthly transactions: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getMonthlySummary(
    int year,
    int month,
  ) async {
    return getSummary(TimePeriod.monthly, DateTime(year, month));
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getSummary(
    TimePeriod period,
    DateTime date,
  ) async {
    try {
      DateTime start;
      DateTime end;

      switch (period) {
        case TimePeriod.daily:
          start = DateTime(date.year, date.month, date.day);
          end = DateTime(date.year, date.month, date.day, 23, 59, 59);
          break;
        case TimePeriod.weekly:
          // Assuming Monday is start of week
          final int daysToSubtract = date.weekday - 1;
          start = DateTime(date.year, date.month, date.day - daysToSubtract);
          final endDt = start.add(const Duration(days: 6));
          end = DateTime(endDt.year, endDt.month, endDt.day, 23, 59, 59);
          break;
        case TimePeriod.monthly:
          start = DateTime(date.year, date.month, 1);
          end = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
          break;
        case TimePeriod.yearly:
          start = DateTime(date.year, 1, 1);
          end = DateTime(date.year, 12, 31, 23, 59, 59);
          break;
      }

      final list = await _localDataSource.getTransactionsByDateRange(
        start,
        end,
      );

      double totalCredit = 0;
      double totalDebit = 0;
      final byCategory = <String, double>{};
      final dailyTotals =
          <int, double>{}; // Key: day/month index, Value: amount

      for (final t in list) {
        if (t.type == TransactionType.credit) {
          totalCredit += t.amount;
        } else {
          totalDebit += t.amount;
          final cat = t.category ?? 'Other';
          byCategory[cat] = (byCategory[cat] ?? 0) + t.amount;
        }

        // Aggregate for charts
        int key;
        if (period == TimePeriod.yearly) {
          key = t.date.month;
        } else {
          key = t.date.day; // good for monthly/weekly/daily
        }

        // sum up debits for chart (or net flow? usually spending is what we track)
        if (t.type == TransactionType.debit) {
          dailyTotals[key] = (dailyTotals[key] ?? 0) + t.amount;
        }
      }

      return Right({
        'totalCredit': totalCredit,
        'totalDebit': totalDebit,
        'byCategory': byCategory,
        'graphData': dailyTotals,
        'transactionCount': list.length,
        'period': period,
        'startDate': start,
        'endDate': end,
      });
    } catch (e) {
      return Left(CacheFailure('Failed to get summary: $e'));
    }
  }

  /// Parses SMS inbox and saves only new transactions. Never clears or replaces
  /// existing data — merge-only. Re-import after user deletes messages or
  /// re-runs import keeps all previously extracted data; only new ids are added.
  @override
  Future<Either<Failure, List<Transaction>>>
  parseAndSaveSmsTransactions() async {
    try {
      final maps = await _smsParserDataSource.parseSmsTransactions();
      debugPrint(
        'Finance: Data source returned ${maps.length} potential transactions.',
      );
      final existing = await _localDataSource.getAllTransactions();
      final existingIds = existing.map((t) => t.id).toSet();
      final merge = mergeNewTransactions(
        parsedMaps: maps,
        existingIds: existingIds,
        buildTransaction: _transactionFromParsedMap,
        idFromMap: _transactionIdFromMap,
      );
      debugPrint(
        'Finance: Skipped ${merge.skipped} existing, found ${merge.newTransactions.length} new transactions.',
      );
      if (merge.newTransactions.isNotEmpty) {
        await _localDataSource.saveTransactions(merge.newTransactions);
      }
      final all = await _localDataSource.getAllTransactions();
      return Right(all);
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } on SmsParseException catch (e) {
      return Left(GeneralFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to parse SMS: $e'));
    }
  }

  String _transactionIdFromMap(Map<String, dynamic> map) {
    final date = map['date'] is DateTime
        ? map['date'] as DateTime
        : DateTime.fromMillisecondsSinceEpoch(map['date'] as int);
    final amount = (map['amount'] as num).toDouble();
    final merchant = map['merchant'] as String? ?? '';
    final type = map['type'] as String? ?? '';
    return '${date.millisecondsSinceEpoch}_${amount}_${merchant}_$type'.hashCode
        .abs()
        .toString();
  }

  /// Pure merge logic (unit-testable): determines which parsed SMS maps are new.
  static ({
    List<Transaction> newTransactions,
    int skipped,
  }) mergeNewTransactions({
    required List<Map<String, dynamic>> parsedMaps,
    required Set<String> existingIds,
    required Transaction? Function(Map<String, dynamic> map) buildTransaction,
    required String Function(Map<String, dynamic> map) idFromMap,
  }) {
    final newTransactions = <Transaction>[];
    int skipped = 0;

    for (final map in parsedMaps) {
      final id = idFromMap(map);
      if (existingIds.contains(id)) {
        skipped++;
        continue;
      }
      existingIds.add(id);
      final t = buildTransaction(map);
      if (t != null) newTransactions.add(t);
    }

    return (newTransactions: newTransactions, skipped: skipped);
  }

  /// Build transaction from parsed SMS — only extracted fields, no raw SMS body stored.
  Transaction? _transactionFromParsedMap(Map<String, dynamic> map) {
    try {
      final date = map['date'] is DateTime
          ? map['date'] as DateTime
          : DateTime.fromMillisecondsSinceEpoch((map['date'] as num).toInt());
      final amount = (map['amount'] as num).toDouble();
      final typeStr = map['type'] as String? ?? 'debit';
      final type = typeStr.toString().toLowerCase().contains('credit')
          ? TransactionType.credit
          : TransactionType.debit;
      final merchant = map['merchant'] as String?;
      final category = map['category'] as String?;
      final rawRemark = map['rawRemark'] as String?;
      final systemRemark = map['systemRemark'] as String?;
      final remark = map['remark'] as String?; // Backward compatibility
      final id = _transactionIdFromMap(map);
      final description = map['description'] as String? ??
          (merchant != null && merchant.isNotEmpty
              ? '$merchant — ${type == TransactionType.credit ? '+' : ''}₹${amount.toStringAsFixed(2)}'
              : '${type == TransactionType.credit ? 'Credit' : 'Debit'} — ₹${amount.toStringAsFixed(2)}');
      return Transaction(
        id: id,
        amount: amount,
        type: type,
        description: description,
        category: category,
        date: date,
        merchant: merchant,
        isAutoCategorized: map['isAutoCategorized'] as bool? ?? true,
        reference: null,
        rawMessage: map['rawMessage'] as String?,
        remark: remark, // Backward compatibility
        rawRemark: rawRemark,
        systemRemark: systemRemark,
        sender: map['sender'] as String?,
        sourceKey: map['sourceKey'] as String?,
        bankName: map['bankName'] as String?,
        title: map['title'] as String?,
        userRemark: map['userRemark'] as String?, // null = empty by default
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Either<Failure, Transaction>> updateTransaction(
    Transaction transaction,
  ) async {
    try {
      await _localDataSource.updateTransaction(transaction);
      return Right(transaction);
    } catch (e) {
      return Left(CacheFailure('Failed to update transaction: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      await _localDataSource.deleteTransaction(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete transaction: $e'));
    }
  }
}
