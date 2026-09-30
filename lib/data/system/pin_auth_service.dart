import 'dart:convert';
import 'dart:math';

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
    await _storage.setParentPin(_encodePin(pin, _randomSalt()));
    await _clearFailedAttempts();
  }

  /// Time left before PIN entry is accepted again, or [Duration.zero].
  Future<Duration> lockoutRemaining() async {
    final DateTime? until = await _storage.getPinLockoutUntil();
    if (until == null) return Duration.zero;
    final Duration remaining = until.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Validates a PIN against the stored hash.
  ///
  /// Returns false while a lockout is active, so repeated guessing cannot be
  /// reset by restarting the app. Transparently upgrades legacy unsalted
  /// digests once the parent proves the PIN, keeping existing installs working.
  Future<bool> validatePin(String pin) async {
    final storedHash = await _storage.getParentPin();
    if (storedHash == null || storedHash.isEmpty) return false;
    if (await lockoutRemaining() > Duration.zero) return false;

    final bool isValid = storedHash.startsWith('$_algorithmId\$')
        ? _matchesEncoded(pin, storedHash)
        : _constantTimeEquals(_legacyHashPin(pin), storedHash);

    if (!isValid) {
      await _registerFailedAttempt();
      return false;
    }

    if (!storedHash.startsWith('$_algorithmId\$')) {
      await _storage.setParentPin(_encodePin(pin, _randomSalt()));
    }
    await _clearFailedAttempts();
    return true;
  }

  /// Checks if a PIN is set.
  Future<bool> hasPin() async {
    return await _storage.hasParentPin();
  }

  static const int _attemptsBeforeLockout = 5;
  static const Duration _initialLockout = Duration(seconds: 30);
  static const Duration _maxLockout = Duration(minutes: 15);

  Future<void> _registerFailedAttempt() async {
    final int attempts = await _storage.getPinFailedAttempts() + 1;
    await _storage.setPinFailedAttempts(attempts);
    if (attempts % _attemptsBeforeLockout != 0) return;

    final int lockoutIndex = attempts ~/ _attemptsBeforeLockout;
    int seconds = _initialLockout.inSeconds;
    for (int i = 1; i < lockoutIndex; i++) {
      seconds *= 2;
      if (seconds >= _maxLockout.inSeconds) break;
    }
    final Duration penalty = Duration(
      seconds: seconds.clamp(_initialLockout.inSeconds, _maxLockout.inSeconds),
    );
    await _storage.setPinLockoutUntil(DateTime.now().add(penalty));
  }

  Future<void> _clearFailedAttempts() async {
    await _storage.setPinFailedAttempts(0);
    await _storage.setPinLockoutUntil(null);
  }

  static const String _algorithmId = 'pbkdf2_sha256';
  // Balances unlock latency on low-end devices against offline guessing cost.
  // Stored hashes carry their own count, so this can be raised without breaking them.
  static const int _iterations = 50000;
  static const int _keyLengthBytes = 32;
  static const int _saltLengthBytes = 16;

  List<int> _randomSalt() {
    final Random random = Random.secure();
    return List<int>.generate(_saltLengthBytes, (_) => random.nextInt(256));
  }

  String _encodePin(String pin, List<int> salt) {
    final List<int> derived = _pbkdf2(utf8.encode(pin), salt, _iterations);
    return '$_algorithmId\$$_iterations\$${base64Encode(salt)}\$${base64Encode(derived)}';
  }

  bool _matchesEncoded(String pin, String encoded) {
    final List<String> parts = encoded.split(r'$');
    if (parts.length != 4) return false;
    final int? iterations = int.tryParse(parts[1]);
    if (iterations == null || iterations <= 0) return false;
    try {
      final List<int> salt = base64Decode(parts[2]);
      final List<int> derived = _pbkdf2(utf8.encode(pin), salt, iterations);
      return _constantTimeEquals(base64Encode(derived), parts[3]);
    } catch (_) {
      return false;
    }
  }

  /// PBKDF2-HMAC-SHA256 (RFC 2898) built on `crypto`, which has no native KDF.
  List<int> _pbkdf2(List<int> password, List<int> salt, int iterations) {
    final Hmac hmac = Hmac(sha256, password);
    final List<int> result = <int>[];
    for (int block = 1; result.length < _keyLengthBytes; block++) {
      final List<int> seed = <int>[
        ...salt,
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ];
      List<int> current = hmac.convert(seed).bytes;
      final List<int> accumulated = List<int>.from(current);
      for (int i = 1; i < iterations; i++) {
        current = hmac.convert(current).bytes;
        for (int j = 0; j < accumulated.length; j++) {
          accumulated[j] ^= current[j];
        }
      }
      result.addAll(accumulated);
    }
    return result.sublist(0, _keyLengthBytes);
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    int difference = 0;
    for (int i = 0; i < a.length; i++) {
      difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return difference == 0;
  }

  /// Digest format used before salted hashing shipped; verification only.
  String _legacyHashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  /// Clears the stored PIN (for testing/reset purposes).
  Future<void> clearPin() async {
    await _storage.setParentPin('');
  }
}

