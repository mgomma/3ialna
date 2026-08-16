import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import '../local/parental_control_storage_service.dart';

/// Service for handling PIN authentication for parental controls.
class PinAuthService {
  final ParentalControlStorageService _storage = ParentalControlStorageService();
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Checks if biometric authentication is available.
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      return false;
    }
  }

  /// Authenticates using biometrics (fingerprint, face, etc.).
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access parental controls',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  /// Sets a new parent PIN.
  Future<void> setPin(String pin) async {
    final hashedPin = _hashPin(pin);
    await _storage.setParentPin(hashedPin);
  }

  /// Validates a PIN against the stored hash.
  Future<bool> validatePin(String pin) async {
    final storedHash = await _storage.getParentPin();
    if (storedHash == null) return false;

    final inputHash = _hashPin(pin);
    return storedHash == inputHash;
  }

  /// Checks if a PIN is set.
  Future<bool> hasPin() async {
    return await _storage.hasParentPin();
  }

  /// Hashes a PIN using SHA-256.
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Clears the stored PIN (for testing/reset purposes).
  Future<void> clearPin() async {
    await _storage.setParentPin('');
  }
}

