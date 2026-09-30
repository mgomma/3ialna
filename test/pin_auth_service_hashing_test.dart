import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mu_super_app/data/local/parental_control_storage_service.dart';
import 'package:mu_super_app/data/system/pin_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

String legacyDigest(String pin) => sha256.convert(utf8.encode(pin)).toString();

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('stores the PIN salted rather than as a bare SHA-256 digest', () async {
    final PinAuthService service = PinAuthService();
    await service.setPin('1234');

    final String? stored = await ParentalControlStorageService().getParentPin();

    expect(stored, isNotNull);
    expect(stored, startsWith('pbkdf2_sha256\$'));
    expect(stored, isNot(legacyDigest('1234')));
  });

  test('accepts the correct PIN and rejects an incorrect one', () async {
    final PinAuthService service = PinAuthService();
    await service.setPin('4321');

    expect(await service.validatePin('4321'), isTrue);
    expect(await service.validatePin('1234'), isFalse);
  });

  test('uses a unique salt so two identical PINs hash differently', () async {
    final PinAuthService service = PinAuthService();

    await service.setPin('1111');
    final String? first = await ParentalControlStorageService().getParentPin();
    await service.setPin('1111');
    final String? second = await ParentalControlStorageService().getParentPin();

    expect(first, isNot(second));
  });

  test('still accepts a PIN saved by the previous unsalted build', () async {
    await ParentalControlStorageService().setParentPin(legacyDigest('2468'));
    final PinAuthService service = PinAuthService();

    expect(await service.validatePin('2468'), isTrue);
    expect(await service.validatePin('1357'), isFalse);
  });

  test('migrates a legacy digest to the salted format once it is verified', () async {
    final ParentalControlStorageService storage = ParentalControlStorageService();
    await storage.setParentPin(legacyDigest('9876'));
    final PinAuthService service = PinAuthService();

    await service.validatePin('9876');

    final String? migrated = await storage.getParentPin();
    expect(migrated, startsWith('pbkdf2_sha256\$'));
    expect(await service.validatePin('9876'), isTrue);
  });

  test('does not migrate when the legacy PIN is wrong', () async {
    final ParentalControlStorageService storage = ParentalControlStorageService();
    await storage.setParentPin(legacyDigest('5555'));
    final PinAuthService service = PinAuthService();

    expect(await service.validatePin('0000'), isFalse);
    expect(await storage.getParentPin(), legacyDigest('5555'));
  });

  test('treats a corrupted stored hash as a failed attempt', () async {
    await ParentalControlStorageService().setParentPin('pbkdf2_sha256\$notanumber\$@@\$@@');

    expect(await PinAuthService().validatePin('1234'), isFalse);
  });

  test('locks entry after five consecutive wrong attempts', () async {
    final PinAuthService service = PinAuthService();
    await service.setPin('1234');

    for (int attempt = 0; attempt < 4; attempt++) {
      expect(await service.validatePin('0000'), isFalse);
      expect(await service.lockoutRemaining(), Duration.zero);
    }
    expect(await service.validatePin('0000'), isFalse);

    expect(await service.lockoutRemaining(), greaterThan(Duration.zero));
  });

  test('rejects even the correct PIN while locked out', () async {
    final PinAuthService service = PinAuthService();
    await service.setPin('1234');
    for (int attempt = 0; attempt < 5; attempt++) {
      await service.validatePin('0000');
    }

    expect(await service.validatePin('1234'), isFalse);
  });

  test('accepts the correct PIN again once the lockout expires', () async {
    final ParentalControlStorageService storage = ParentalControlStorageService();
    final PinAuthService service = PinAuthService();
    await service.setPin('1234');
    for (int attempt = 0; attempt < 5; attempt++) {
      await service.validatePin('0000');
    }

    await storage.setPinLockoutUntil(
      DateTime.now().subtract(const Duration(seconds: 1)),
    );

    expect(await service.lockoutRemaining(), Duration.zero);
    expect(await service.validatePin('1234'), isTrue);
  });

  test('clears the failed-attempt counter after a successful unlock', () async {
    final ParentalControlStorageService storage = ParentalControlStorageService();
    final PinAuthService service = PinAuthService();
    await service.setPin('1234');
    await service.validatePin('0000');
    await service.validatePin('0000');

    expect(await service.validatePin('1234'), isTrue);

    expect(await storage.getPinFailedAttempts(), 0);
    expect(await storage.getPinLockoutUntil(), isNull);
  });

  test('keeps the lockout in storage so restarting the app cannot bypass it', () async {
    final PinAuthService service = PinAuthService();
    await service.setPin('1234');
    for (int attempt = 0; attempt < 5; attempt++) {
      await service.validatePin('0000');
    }

    // A fresh instance models the app being relaunched by the child.
    expect(await PinAuthService().lockoutRemaining(), greaterThan(Duration.zero));
    expect(await PinAuthService().validatePin('1234'), isFalse);
  });
}
