import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/router.dart';
import '../bloc/auth_bloc.dart';

import '../widgets/pin_input_widget.dart';

class SetupPinPage extends StatefulWidget {
  const SetupPinPage({super.key});

  @override
  State<SetupPinPage> createState() => _SetupPinPageState();
}

class _SetupPinPageState extends State<SetupPinPage> {
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthBloc>().add(ResetPinState());
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is PinSetupSuccess) {
          Navigator.of(context).pushReplacementNamed(AppRouter.home);
        } else if (state is PinSetupFailure) {
          _showError(context, state.message);
          context.read<AuthBloc>().add(ResetPinState());
        } else if (state is AuthError) {
          _showError(context, state.message);
          context.read<AuthBloc>().add(ResetPinState());
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final pinState = state is PinSetupInProgress
                      ? state
                      : PinSetupInProgress(
                          pin: '',
                          confirmPin: '',
                          isConfirming: false,
                          obscurePin: true,
                          isSubmitting: false,
                        );

                  final isSubmitting = pinState.isSubmitting;

                  if (pinState.errorMessage != null) {
                    _showError(context, pinState.errorMessage!);
                    // Clear error message after showing
                    // This might require a new event/state in BLoC to clear the error
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon
                      Container(
                        width: screenWidth * 0.25,
                        height: screenWidth * 0.25,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: screenWidth * 0.12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),

                      // Title
                      Text(
                        pinState.isConfirming
                            ? 'Confirm Your PIN'
                            : 'Create Your PIN',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.06,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Description
                      Text(
                        pinState.isConfirming
                            ? 'Enter your PIN again to confirm'
                            : 'Choose a 6-digit PIN to secure your vault',
                        style:
                            Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.7),
                                  fontSize: screenWidth * 0.04,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.06),

                      // PIN Input
                      PinInputWidget(
                        pin: pinState.isConfirming
                            ? pinState.confirmPin
                            : pinState.pin,
                        onPinChanged: (_) {}, // Not used with keypad
                        obscurePin: pinState.obscurePin,
                      ),
                      SizedBox(height: screenHeight * 0.04),

                      // Toggle Visibility
                      TextButton.icon(
                        onPressed: isSubmitting
                            ? null
                            : () {
                          context.read<AuthBloc>().add(TogglePinVisibility());
                        },
                        icon: Icon(
                          pinState.obscurePin
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: screenWidth * 0.05,
                        ),
                        label: Text(
                          pinState.obscurePin ? 'Show PIN' : 'Hide PIN',
                          style: TextStyle(fontSize: screenWidth * 0.04),
                        ),
                      ),

                      // Submit/Continue Button (shown when PIN is complete)
                      if ((!pinState.isConfirming &&
                              pinState.pin.length == 6) ||
                          (pinState.isConfirming &&
                              pinState.confirmPin.length == 6))
                        Padding(
                          padding: EdgeInsets.only(
                              top: screenHeight * 0.03,
                              bottom: screenHeight * 0.03),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                if (!pinState.isConfirming &&
                                    pinState.pin.length == 6) {
                                  context
                                      .read<AuthBloc>()
                                      .add(PinContinuePressed());
                                } else if (pinState.isConfirming &&
                                    pinState.confirmPin.length == 6) {
                                  context
                                      .read<AuthBloc>()
                                      .add(PinConfirmPressed());
                                }
                              },
                              icon: isSubmitting
                                  ? SizedBox(
                                      width: screenWidth * 0.05,
                                      height: screenWidth * 0.05,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      pinState.isConfirming
                                          ? Icons.check
                                          : Icons.arrow_forward,
                                      size: screenWidth * 0.05,
                                    ),
                              label: Text(
                                pinState.isConfirming
                                    ? 'Confirm PIN'
                                    : 'Continue',
                                style: TextStyle(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w600),
                              ),
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    vertical: screenHeight * 0.02),
                              ),
                            ),
                          ),
                        ),

                      // Back button during confirmation
                      if (pinState.isConfirming)
                        TextButton(
                          onPressed: isSubmitting
                              ? null
                              : () {
                            context.read<AuthBloc>().add(PinBackToSetup());
                          },
                          child: Text(
                            'Back to change PIN',
                            style: TextStyle(fontSize: screenWidth * 0.04),
                          ),
                        ),

                      SizedBox(height: screenHeight * 0.03),

                      // Numeric Keypad
                      NumericKeypad(
                        onNumberPressed: (digit) {
                          if (isSubmitting) return;
                          context.read<AuthBloc>().add(PinDigitPressed(digit));
                        },
                        onDelete: () {
                          if (isSubmitting) return;
                          context.read<AuthBloc>().add(PinDeletePressed());
                        },
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Info
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                              size: screenWidth * 0.05,
                            ),
                            SizedBox(width: screenWidth * 0.03),
                            Expanded(
                              child: Text(
                                'Your PIN is encrypted and never stored in plain text. You\'ll need it to unlock your vault.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontSize: screenWidth * 0.035,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
