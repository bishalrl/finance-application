import 'package:flutter/material.dart';

class PinInputWidget extends StatelessWidget {
  final String pin;
  final Function(String) onPinChanged;
  final bool obscurePin;

  const PinInputWidget({
    super.key,
    required this.pin,
    required this.onPinChanged,
    this.obscurePin = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available width and adjust box size
        final availableWidth = constraints.maxWidth;
        final totalMargins = 4.0 * 12; // 4px margin on each side of 6 boxes
        final maxBoxWidth = (availableWidth - totalMargins) / 6;
        final boxSize = maxBoxWidth.clamp(40.0, 56.0); // Min 40, max 56
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final isFilled = index < pin.length;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                color: isFilled
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFilled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: isFilled
                    ? obscurePin
                        ? Icon(
                            Icons.circle,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 12,
                          )
                        : Text(
                            pin[index],
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                    : null,
              ),
            );
          }),
        );
      },
    );
  }
}

// Numeric Keypad Widget
class NumericKeypad extends StatelessWidget {
  final Function(String) onNumberPressed;
  final VoidCallback onDelete;
  final VoidCallback? onBiometric;

  const NumericKeypad({
    super.key,
    required this.onNumberPressed,
    required this.onDelete,
    this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate key size based on available width
        final availableWidth = constraints.maxWidth;
        final totalMargins = 4.0 * 6; // 4px margin on each side of 3 keys
        final maxKeyWidth = (availableWidth - totalMargins) / 3;
        final keySize = maxKeyWidth.clamp(60.0, 80.0); // Min 60, max 80
        
        return Column(
          children: [
            _buildRow(['1', '2', '3'], context, keySize),
            const SizedBox(height: 16),
            _buildRow(['4', '5', '6'], context, keySize),
            const SizedBox(height: 16),
            _buildRow(['7', '8', '9'], context, keySize),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onBiometric != null)
                  _buildKey(
                    icon: Icons.fingerprint,
                    onTap: onBiometric!,
                    context: context,
                    keySize: keySize,
                  )
                else
                  SizedBox(width: keySize),
                _buildKey(
                  text: '0',
                  onTap: () => onNumberPressed('0'),
                  context: context,
                  keySize: keySize,
                ),
                _buildKey(
                  icon: Icons.backspace_outlined,
                  onTap: onDelete,
                  context: context,
                  keySize: keySize,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildRow(List<String> numbers, BuildContext context, double keySize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers.map((num) {
        return _buildKey(
          text: num,
          onTap: () => onNumberPressed(num),
          context: context,
          keySize: keySize,
        );
      }).toList(),
    );
  }

  Widget _buildKey({
    String? text,
    IconData? icon,
    required VoidCallback onTap,
    required BuildContext context,
    required double keySize,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: keySize,
      height: keySize,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(keySize / 2),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: text != null
                  ? Text(
                      text,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    )
                  : Icon(
                      icon,
                      size: 28,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
