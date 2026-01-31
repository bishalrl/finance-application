import 'package:equatable/equatable.dart';

abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {}

class NavigateToOnboarding extends SplashState {}

class NavigateToPinSetup extends SplashState {}

class NavigateToPinVerify extends SplashState {}

class NavigateToHome extends SplashState {}
