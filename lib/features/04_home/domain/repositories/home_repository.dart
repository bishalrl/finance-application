import 'package:dartz/dartz.dart';
import 'package:life_vault/features/08_reminders/domain/entities/reminder.dart';
import '../../../../core/errors/failures.dart';
import '../entities/dashboard_stats.dart';
import '../entities/recent_item.dart';

abstract class HomeRepository {
  Future<Either<Failure, DashboardStats>> getDashboardStats();
  Future<Either<Failure, List<RecentItem>>> getRecentItems();
  Future<Either<Failure, List<Reminder>>> getUpcomingReminders();
}
