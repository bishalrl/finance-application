import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(OnboardingInitial()) {
    on<OnboardingPageChanged>((event, emit) {
      emit(OnboardingInitial(currentPage: event.pageIndex));
    });

    on<OnboardingGetStarted>((event, emit) {
      emit(OnboardingNavigateToPinSetup());
    });
  }
}
