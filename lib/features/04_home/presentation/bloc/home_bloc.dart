import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_vault/features/04_home/domain/entities/dashboard_stats.dart';
import 'package:life_vault/features/04_home/domain/entities/recent_item.dart';
import 'package:life_vault/features/04_home/domain/usecases/get_dashboard_stats.dart';
import 'package:life_vault/features/04_home/domain/usecases/get_recent_items.dart';
import 'package:life_vault/features/04_home/domain/usecases/get_upcoming_reminders.dart';
import 'package:life_vault/features/04_home/presentation/bloc/home_event.dart';
import 'package:life_vault/features/04_home/presentation/bloc/home_state.dart';
import 'package:life_vault/features/08_reminders/domain/entities/reminder.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetDashboardStats getDashboardStats;
  final GetRecentItems getRecentItems;
  final GetUpcomingReminders getUpcomingReminders;

  HomeBloc({
    required this.getDashboardStats,
    required this.getRecentItems,
    required this.getUpcomingReminders,
  }) : super(const HomeState()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
    on<ChangeTab>(_onChangeTab);
  }

  Future<void> _onLoadDashboard(LoadDashboard event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading, errorMessage: null));
    await _fetchDashboard(emit);
  }

  Future<void> _onRefreshDashboard(RefreshDashboard event, Emitter<HomeState> emit) async {
    await _fetchDashboard(emit);
  }

  void _onChangeTab(ChangeTab event, Emitter<HomeState> emit) {
    emit(state.copyWith(selectedIndex: event.newIndex));
  }

  Future<void> _fetchDashboard(Emitter<HomeState> emit) async {
    final statsResult = await getDashboardStats();
    final recentResult = await getRecentItems();
    final upcomingResult = await getUpcomingReminders();

    final stats = statsResult.getOrElse(() => const DashboardStats());
    final recentItems = recentResult.getOrElse(() => <RecentItem>[]);
    final upcomingReminders = upcomingResult.getOrElse(() => <Reminder>[]);

    if (statsResult.isLeft()) {
      emit(state.copyWith(
        status: HomeStatus.error,
        errorMessage: statsResult.fold((f) => f.toString(), (_) => ''),
      ));
      return;
    }

    emit(state.copyWith(
      status: HomeStatus.loaded,
      stats: stats,
      recentItems: recentItems,
      upcomingReminders: upcomingReminders,
      errorMessage: null,
    ));
  }
}
