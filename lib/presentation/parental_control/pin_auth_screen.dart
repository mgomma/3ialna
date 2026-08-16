import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/system/pin_auth_service.dart';

/// Screen for PIN authentication to access parental controls.
class PinAuthScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;
  final bool isSetupMode;

  const PinAuthScreen({
    super.key,
    required this.onAuthenticated,
    this.isSetupMode = false,
  });

  @override
  State<PinAuthScreen> createState() => _PinAuthScreenState();
}

class _PinAuthScreenState extends State<PinAuthScreen> {
  final PinAuthService _pinAuthService = PinAuthService();
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (_) => FocusNode(),
  );
  String _enteredPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String? _errorMessage;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _focusNodes[0].requestFocus();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _pinAuthService.isBiometricAvailable();
    setState(() {
      _biometricAvailable = available;
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    final success = await _pinAuthService.authenticateWithBiometrics();
    if (success && mounted) {
      widget.onAuthenticated();
    }
  }

  void _onPinChanged(int index, String value) {
    if (value.length > 1) {
      _controllers[index].text = value[value.length - 1];
    }

    _enteredPin = _controllers.map((c) => c.text).join();

    if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() {
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      _handlePinComplete();
    }
  }

  void _handlePinComplete() async {
    if (widget.isSetupMode) {
      if (!_isConfirming) {
        setState(() {
          _isConfirming = true;
          _confirmPin = _enteredPin;
          _enteredPin = '';
          for (final controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        });
      } else {
        if (_enteredPin == _confirmPin) {
          await _pinAuthService.setPin(_enteredPin);
          if (mounted) {
            widget.onAuthenticated();
          }
        } else {
          setState(() {
            _errorMessage = 'PINs do not match. Please try again.';
            _isConfirming = false;
            _enteredPin = '';
            _confirmPin = '';
            for (final controller in _controllers) {
              controller.clear();
            }
            _focusNodes[0].requestFocus();
          });
        }
      }
    } else {
      final isValid = await _pinAuthService.validatePin(_enteredPin);
      if (isValid) {
        if (mounted) {
          widget.onAuthenticated();
        }
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN. Please try again.';
          _enteredPin = '';
          for (final controller in _controllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();
        });
        HapticFeedback.vibrate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                widget.isSetupMode
                    ? (_isConfirming
                        ? 'Confirm PIN'
                        : 'Set Parent PIN')
                    : 'Enter PIN',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isSetupMode
                    ? (_isConfirming
                        ? 'Re-enter your PIN to confirm'
                        : 'Create a PIN to protect parental controls')
                    : 'Enter your PIN to access parental controls',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // PIN input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _enteredPin.length > index
                            ? colorScheme.primary
                            : colorScheme.outline,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      obscureText: true,
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: theme.textTheme.headlineSmall,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                      ),
                      onChanged: (value) => _onPinChanged(index, value),
                      onTap: () {
                        _focusNodes[index].requestFocus();
                      },
                    ),
                  );
                }),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),
              // Biometric authentication button
              if (_biometricAvailable && !widget.isSetupMode) ...[
                OutlinedButton.icon(
                  onPressed: _authenticateWithBiometrics,
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Use Biometric'),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

