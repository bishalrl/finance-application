import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboard extends HomeEvent {
  const LoadDashboard();
}

class RefreshDashboard extends HomeEvent {
  const RefreshDashboard();
}

class ChangeTab extends HomeEvent {
  final int newIndex;

  const ChangeTab(this.newIndex);

  @override
  List<Object?> get props => [newIndex];
}
