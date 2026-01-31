import 'package:equatable/equatable.dart';
import 'package:life_vault/features/04_home/domain/entities/dashboard_stats.dart';
import 'package:life_vault/features/04_home/domain/entities/recent_item.dart';
import 'package:life_vault/features/08_reminders/domain/entities/reminder.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final DashboardStats? stats;
  final List<RecentItem> recentItems;
  final List<Reminder> upcomingReminders;
  final String? errorMessage;
  final int selectedIndex;

  const HomeState({
    this.status = HomeStatus.initial,
    this.stats,
    this.recentItems = const [],
    this.upcomingReminders = const [],
    this.errorMessage,
    this.selectedIndex = 0,
  });

  HomeState copyWith({
    HomeStatus? status,
    DashboardStats? stats,
    List<RecentItem>? recentItems,
    List<Reminder>? upcomingReminders,
    String? errorMessage,
    int? selectedIndex,
  }) {
    return HomeState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      recentItems: recentItems ?? this.recentItems,
      upcomingReminders: upcomingReminders ?? this.upcomingReminders,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }

  @override
  List<Object?> get props => [status, stats, recentItems, upcomingReminders, errorMessage, selectedIndex];
}
