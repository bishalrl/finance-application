import 'package:dartz/dartz.dart';
import '../entities/recent_item.dart';
import '../repositories/home_repository.dart';
import '../../../../core/errors/failures.dart';

class GetRecentItems {
  final HomeRepository repository;

  GetRecentItems(this.repository);

  Future<Either<Failure, List<RecentItem>>> call() async {
    return await repository.getRecentItems();
  }
}
