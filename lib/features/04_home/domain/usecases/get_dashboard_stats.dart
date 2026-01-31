import 'package:dartz/dartz.dart';
import '../entities/dashboard_stats.dart';
import '../repositories/home_repository.dart';
import '../../../../core/errors/failures.dart';

class GetDashboardStats {
  final HomeRepository repository;

  GetDashboardStats(this.repository);

  Future<Either<Failure, DashboardStats>> call() async {
    return await repository.getDashboardStats();
  }
}
