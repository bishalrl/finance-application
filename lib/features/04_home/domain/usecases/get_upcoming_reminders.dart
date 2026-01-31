import 'package:dartz/dartz.dart';
import 'package:life_vault/features/08_reminders/domain/entities/reminder.dart';
import '../repositories/home_repository.dart';
import '../../../../core/errors/failures.dart';

class GetUpcomingReminders {
  final HomeRepository repository;

  GetUpcomingReminders(this.repository);

  Future<Either<Failure, List<Reminder>>> call() async {
    return await repository.getUpcomingReminders();
  }
}
