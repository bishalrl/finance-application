part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

class SetupPinEvent extends AuthEvent {
  final String pin;

  SetupPinEvent(this.pin);
}

class VerifyPinEvent extends AuthEvent {
  final String pin;

  VerifyPinEvent(this.pin);
}

class PinDigitPressed extends AuthEvent {
  final String digit;

  PinDigitPressed(this.digit);
}

class PinDeletePressed extends AuthEvent {}

class PinContinuePressed extends AuthEvent {}

class PinConfirmPressed extends AuthEvent {}

class TogglePinVisibility extends AuthEvent {}

class PinBackToSetup extends AuthEvent {}

class ResetPinState extends AuthEvent {}

class ResetToVerificationState extends AuthEvent {}