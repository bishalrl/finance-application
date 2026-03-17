import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/transaction.dart';
import '../entities/time_period.dart';

abstract class FinanceRepository {
  Future<Either<Failure, List<Transaction>>> getAllTransactions();
  Future<Either<Failure, Transaction>> addTransaction(Transaction transaction);
  Future<Either<Failure, Transaction>> updateCategory(
    String id,
    String category,
  );
  Future<Either<Failure, List<Transaction>>> getTransactionsByMonth(
    int year,
    int month,
  );
  Future<Either<Failure, Map<String, dynamic>>> getMonthlySummary(
    int year,
    int month,
  );
  Future<Either<Failure, Map<String, dynamic>>> getSummary(
    TimePeriod period,
    DateTime date,
  );
  Future<Either<Failure, List<Transaction>>> parseAndSaveSmsTransactions();
  Future<Either<Failure, Transaction>> updateTransaction(Transaction transaction);
  Future<Either<Failure, void>> deleteTransaction(String id);
}
