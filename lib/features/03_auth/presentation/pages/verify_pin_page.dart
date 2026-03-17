import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/router.dart';
import '../../../../core/config/dependency_injection.dart' as di;
import '../bloc/auth_bloc.dart';

import '../widgets/pin_input_widget.dart';

class VerifyPinPage extends StatefulWidget {
  const VerifyPinPage({super.key});

  @override
  State<VerifyPinPage> createState() => _VerifyPinPageState();
}

class _VerifyPinPageState extends State<VerifyPinPage> {
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
      if (mounted) context.read<AuthBloc>().add(ResetToVerificationState());
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocProvider.value(
      value: context.read<AuthBloc>(),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PinVerificationSuccess) {
            di.ensureHiveInitialized().then((_) {
              if (!context.mounted) return;
              Navigator.of(context).pushReplacementNamed(AppRouter.home);
            });
          } else if (state is PinVerificationFailure) {
            _showError(context, state.message);
            // Optionally reset pin input after failure
            context.read<AuthBloc>().add(ResetPinState());
          } else if (state is AuthError) {
            _showError(context, state.message);
            context.read<AuthBloc>().add(ResetPinState());
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      String currentPin = '';
                      bool obscurePin = true;
                      String? errorMessage;
                      bool isSubmitting = false;

                      if (state is PinVerificationInProgress) {
                        currentPin = state.pin;
                        obscurePin = state.obscurePin;
                        errorMessage = state.errorMessage;
                        isSubmitting = state.isSubmitting;
                      }

                      if (errorMessage != null) {
                        _showError(context, errorMessage);
                        // Clear error message after showing
                        // This might require a new event/state in BLoC to clear the error
                      }

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            // Icon
                            Container(
                              width: screenWidth * 0.25,
                              height: screenWidth * 0.25,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                              'Enter Your PIN',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth * 0.06,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.02),

                            // Description
                            Text(
                              'Unlock Artha',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontSize: screenWidth * 0.04,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenHeight * 0.06),

                            // PIN Input
                            PinInputWidget(
                              pin: currentPin,
                              onPinChanged: (_) {}, // Not used with keypad
                              obscurePin: obscurePin,
                            ),
                            SizedBox(height: screenHeight * 0.03),

                            // Toggle Visibility
                            TextButton.icon(
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                context.read<AuthBloc>().add(TogglePinVisibility());
                              },
                              icon: Icon(
                                obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                size: screenWidth * 0.05,
                              ),
                              label: Text(
                                obscurePin ? 'Show PIN' : 'Hide PIN',
                                style: TextStyle(fontSize: screenWidth * 0.04),
                              ),
                            ),

                            // Submit Button (shown when PIN is complete)
                            if (currentPin.length == 6)
                              Padding(
                                padding: EdgeInsets.only(top: screenHeight * 0.03, bottom: screenHeight * 0.03),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: FilledButton.icon(
                                    onPressed: isSubmitting
                                        ? null
                                        : () {
                                      context.read<AuthBloc>().add(
                                            VerifyPinEvent(currentPin),
                                          );
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
                                            Icons.lock_open,
                                            size: screenWidth * 0.05,
                                          ),
                                    label: Text(
                                      'Unlock',
                                      style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w600),
                                    ),
                                    style: FilledButton.styleFrom(
                                      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                                    ),
                                  ),
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
                              onBiometric: () {
                                // TODO: Implement biometric authentication
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
