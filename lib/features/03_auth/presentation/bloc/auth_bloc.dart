import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:life_vault/features/03_auth/domain/usecases/setup_pin.dart';
import 'package:life_vault/features/03_auth/domain/usecases/verify_pin.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SetupPin _setupPin;
  final VerifyPin _verifyPin;

  AuthBloc({
    required SetupPin setupPin,
    required VerifyPin verifyPin,
  })  : _setupPin = setupPin,
        _verifyPin = verifyPin,
        super(AuthInitial()) {
    on<PinDigitPressed>(_onPinDigitPressed);
    on<PinDeletePressed>(_onPinDeletePressed);
    on<PinContinuePressed>(_onPinContinuePressed);
    on<PinConfirmPressed>(_onPinConfirmPressed);
    on<TogglePinVisibility>(_onTogglePinVisibility);
    on<PinBackToSetup>(_onPinBackToSetup);
    on<SetupPinEvent>(_onSetupPinEvent);
    on<VerifyPinEvent>(_onVerifyPinEvent);
    on<ResetPinState>(_onResetPinState);
    on<ResetToVerificationState>(_onResetToVerificationState);
  }

  void _onPinDigitPressed(PinDigitPressed event, Emitter<AuthState> emit) {
    final currentState = state;
    if (currentState is PinSetupInProgress) {
      if (!currentState.isConfirming) {
        if (currentState.pin.length < 6) {
          emit(currentState.copyWith(pin: currentState.pin + event.digit));
        }
      } else {
        if (currentState.confirmPin.length < 6) {
          emit(currentState.copyWith(confirmPin: currentState.confirmPin + event.digit));
        }
      }
    } else if (currentState is PinVerificationInProgress) {
      if (currentState.pin.length < 6) {
        emit(currentState.copyWith(pin: currentState.pin + event.digit));
      }
    } else if (currentState is AuthInitial) {
      emit(PinSetupInProgress(pin: event.digit, confirmPin: '', isConfirming: false, obscurePin: true));
    }
  }

  void _onPinDeletePressed(PinDeletePressed event, Emitter<AuthState> emit) {
    if (state is PinSetupInProgress) {
      final currentState = state as PinSetupInProgress;
      if (!currentState.isConfirming) {
        if (currentState.pin.isNotEmpty) {
          emit(currentState.copyWith(pin: currentState.pin.substring(0, currentState.pin.length - 1)));
        }
      } else {
        if (currentState.confirmPin.isNotEmpty) {
          emit(currentState.copyWith(confirmPin: currentState.confirmPin.substring(0, currentState.confirmPin.length - 1)));
        }
      }
    } else if (state is PinVerificationInProgress) {
      final currentState = state as PinVerificationInProgress;
      if (currentState.pin.isNotEmpty) {
        emit(currentState.copyWith(pin: currentState.pin.substring(0, currentState.pin.length - 1)));
      }
    }
  }

  void _onPinContinuePressed(PinContinuePressed event, Emitter<AuthState> emit) {
    if (state is PinSetupInProgress) {
      final currentState = state as PinSetupInProgress;
      if (currentState.pin.length == 6) {
        emit(currentState.copyWith(isConfirming: true, errorMessage: null));
      } else {
        emit(currentState.copyWith(errorMessage: 'PIN must be 6 digits.'));
      }
    }
  }

  void _onPinConfirmPressed(PinConfirmPressed event, Emitter<AuthState> emit) async {
    if (state is PinSetupInProgress) {
      final currentState = state as PinSetupInProgress;
      if (currentState.pin == currentState.confirmPin && currentState.confirmPin.length == 6) {
        final result = await _setupPin(currentState.pin);
        result.fold(
          (failure) => emit(PinSetupFailure(failure.message)),
          (_) => emit(PinSetupSuccess()),
        );
      } else {
        emit(currentState.copyWith(
          pin: '',
          confirmPin: '',
          isConfirming: false,
          errorMessage: 'PINs do not match. Please try again.',
        ));
      }
    }
  }

  void _onTogglePinVisibility(TogglePinVisibility event, Emitter<AuthState> emit) {
    if (state is PinSetupInProgress) {
      final currentState = state as PinSetupInProgress;
      emit(currentState.copyWith(obscurePin: !currentState.obscurePin));
    } else if (state is PinVerificationInProgress) {
      final currentState = state as PinVerificationInProgress;
      emit(currentState.copyWith(obscurePin: !currentState.obscurePin));
    }
  }

  void _onPinBackToSetup(PinBackToSetup event, Emitter<AuthState> emit) {
    if (state is PinSetupInProgress) {
      final currentState = state as PinSetupInProgress;
      emit(currentState.copyWith(isConfirming: false, confirmPin: '', errorMessage: null));
    }
  }

  void _onSetupPinEvent(SetupPinEvent event, Emitter<AuthState> emit) async {
    final result = await _setupPin(event.pin);
    result.fold(
      (failure) => emit(PinSetupFailure(failure.message)),
      (_) => emit(PinSetupSuccess()),
    );
  }

  void _onVerifyPinEvent(VerifyPinEvent event, Emitter<AuthState> emit) async {
    final result = await _verifyPin(event.pin);
    result.fold(
      (failure) => emit(PinVerificationFailure(failure.message)),
      (_) => emit(PinVerificationSuccess()),
    );
  }

  void _onResetPinState(ResetPinState event, Emitter<AuthState> emit) {
    emit(PinSetupInProgress(pin: '', confirmPin: '', isConfirming: false, obscurePin: true));
  }

  void _onResetToVerificationState(ResetToVerificationState event, Emitter<AuthState> emit) {
    emit(PinVerificationInProgress(pin: '', obscurePin: true));
  }
}