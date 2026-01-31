part of 'onboarding_bloc.dart';

@immutable
sealed class OnboardingState {}

final class OnboardingInitial extends OnboardingState {
  final int currentPage;

  OnboardingInitial({this.currentPage = 0});
}

final class OnboardingNavigateToPinSetup extends OnboardingState {}
