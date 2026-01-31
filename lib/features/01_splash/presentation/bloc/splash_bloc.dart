import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/dependency_injection.dart' as di;
import '../../../../core/security/key_manager.dart';
import 'splash_event.dart';
import 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(SplashInitial()) {
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<SplashState> emit,
  ) async {
    try {
      // Check if master key exists (user has set up PIN)
      final hasMasterKey = await di.sl<KeyManager>().hasMasterKey();
      
      if (!hasMasterKey) {
        // First time user - show onboarding
        emit(NavigateToOnboarding());
        return;
      }

      // Check if app is locked
      // For now, always verify PIN if master key exists
      // In future, can check if app was locked
      emit(NavigateToPinVerify());
    } catch (e) {
      // On error, go to onboarding
      emit(NavigateToOnboarding());
    }
  }
}
