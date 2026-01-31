import 'package:dartz/dartz.dart';
import '../repositories/reminder_repository.dart';
import '../../../../core/errors/failures.dart';

class DeleteReminder {
  final ReminderRepository repository;

  DeleteReminder(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteReminder(id);
  }
}
