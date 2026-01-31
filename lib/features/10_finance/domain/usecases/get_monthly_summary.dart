import 'package:dartz/dartz.dart';
import '../repositories/finance_repository.dart';
import '../../../../core/errors/failures.dart';

class GetMonthlySummary {
  final FinanceRepository repository;

  GetMonthlySummary(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(int year, int month) async {
    return await repository.getMonthlySummary(year, month);
  }
}
