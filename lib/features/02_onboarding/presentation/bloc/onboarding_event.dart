part of 'onboarding_bloc.dart';

@immutable
sealed class OnboardingEvent {}

class OnboardingPageChanged extends OnboardingEvent {
  final int pageIndex;

  OnboardingPageChanged(this.pageIndex);
}

class OnboardingGetStarted extends OnboardingEvent {}
