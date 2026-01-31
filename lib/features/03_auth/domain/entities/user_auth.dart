import 'package:equatable/equatable.dart';

class UserAuth extends Equatable {
  final bool hasPin;
  final bool hasBiometric;
  final bool isLocked;
  final DateTime? lastUnlockTime;
  final int failedAttempts;

  const UserAuth({
    this.hasPin = false,
    this.hasBiometric = false,
    this.isLocked = false,
    this.lastUnlockTime,
    this.failedAttempts = 0,
  });

  @override
  List<Object?> get props => [hasPin, hasBiometric, isLocked, lastUnlockTime, failedAttempts];
}
