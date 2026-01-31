import 'package:dartz/dartz.dart';
import '../entities/transaction.dart';
import '../repositories/finance_repository.dart';
import '../../../../core/errors/failures.dart';

/// Parses transactional SMS on-device and saves only extracted fields (no raw SMS stored).
class ParseSmsTransactions {
  final FinanceRepository repository;

  ParseSmsTransactions(this.repository);

  Future<Either<Failure, List<Transaction>>> call() async {
    return await repository.parseAndSaveSmsTransactions();
  }
}
