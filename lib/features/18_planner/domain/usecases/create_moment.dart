import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../entities/planner_moment.dart';
import '../repositories/planner_repository.dart';
import '../../../../core/errors/failures.dart';

class CreateMoment {
  final PlannerRepository repository;

  CreateMoment(this.repository);

  Future<Either<Failure, PlannerMoment>> call({
    required MomentType type,
    required String title,
    String? note,
    required DateTime date,
    DateTime? dateEnd,
    DateTime? reminderAt,
    MomentImportance importance = MomentImportance.normal,
    double? amount,
    bool isRecurring = false,
    String? recurrenceRule,
  }) async {
    final now = DateTime.now();
    final moment = PlannerMoment(
      id: const Uuid().v4(),
      type: type,
      title: title,
      note: note,
      date: date,
      dateEnd: dateEnd,
      reminderAt: reminderAt,
      status: date.isBefore(now) && (dateEnd == null || (dateEnd.isBefore(now)))
          ? MomentStatus.past
          : MomentStatus.upcoming,
      importance: importance,
      amount: amount,
      createdAt: now,
      updatedAt: now,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
    );
    return repository.createMoment(moment);
  }
}
