part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

final class PinSetupInProgress extends AuthState {
  final String pin;
  final String confirmPin;
  final bool isConfirming;
  final bool obscurePin;
  final String? errorMessage;

  PinSetupInProgress({
    required this.pin,
    required this.confirmPin,
    required this.isConfirming,
    required this.obscurePin,
    this.errorMessage,
  });

  PinSetupInProgress copyWith({
    String? pin,
    String? confirmPin,
    bool? isConfirming,
    bool? obscurePin,
    String? errorMessage,
  }) {
    return PinSetupInProgress(
      pin: pin ?? this.pin,
      confirmPin: confirmPin ?? this.confirmPin,
      isConfirming: isConfirming ?? this.isConfirming,
      obscurePin: obscurePin ?? this.obscurePin,
      errorMessage: errorMessage,
    );
  }
}

final class PinSetupSuccess extends AuthState {}

final class PinSetupFailure extends AuthState {
  final String message;

  PinSetupFailure(this.message);
}

final class PinVerificationInProgress extends AuthState {
  final String pin;
  final bool obscurePin;
  final String? errorMessage;

  PinVerificationInProgress({
    required this.pin,
    required this.obscurePin,
    this.errorMessage,
  });

  PinVerificationInProgress copyWith({
    String? pin,
    bool? obscurePin,
    String? errorMessage,
  }) {
    return PinVerificationInProgress(
      pin: pin ?? this.pin,
      obscurePin: obscurePin ?? this.obscurePin,
      errorMessage: errorMessage,
    );
  }
}

final class PinVerificationSuccess extends AuthState {}

final class PinVerificationFailure extends AuthState {
  final String message;

  PinVerificationFailure(this.message);
}

final class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}