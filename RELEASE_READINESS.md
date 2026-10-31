# Release Readiness Checklist (Android + iOS)

This document tracks what is done and what remains before publishing test builds.

## Completed in Repository
- Android release signing config now supports `android/key.properties` and keystore-based signing.
- Android fallback remains available for local release checks when no keystore is configured.
- iOS Podfile now declares platform `iOS 13.0` explicitly.
- iOS privacy metadata added for location and Face ID usage.
- iOS encryption declaration key added (`ITSAppUsesNonExemptEncryption=false`).
- Flutter app version now includes build number (`version: 0.1.0+1`).

## Remaining Manual Steps (Required)

### Android (Play Internal Testing)
1. Create a real upload keystore and place it locally (example path: `android/keystore/upload-keystore.jks`).
2. Copy `android/key.properties.example` to `android/key.properties` and fill all values.
3. Confirm the production package ID (`com.ialna.app`) matches the Android identity registered in Firebase and any future Play Console listing.
4. Build signed artifact:
   - `flutter build appbundle --release`
5. Upload the `.aab` to Play Console internal testing.

### iOS (TestFlight)
1. Set a production bundle id in Xcode (current is placeholder `com.example.muSuperApp`).
2. Ensure Apple Team, signing certificates, and provisioning profiles are configured in Xcode.
3. From macOS, run:
   - `flutter clean`
   - `flutter pub get`
   - `cd ios && pod install && cd ..`
   - `flutter build ipa --release`
4. Upload the IPA with Xcode Organizer or Transporter to App Store Connect.
5. Complete App Store Connect fields (privacy, export compliance, screenshots, test notes).

## Policy and Review Risks to Verify Before Store Submission
- Android uses high-risk permissions (`QUERY_ALL_PACKAGES`, accessibility, usage stats, overlay). Provide clear policy justification and declarations in Play Console.
- iOS app-blocking behavior is not equivalent to Android due to iOS platform limitations; ensure product text does not promise unsupported controls on iOS.
- Confirm all permission prompts shown to users match app behavior and are clearly explained.

## Recommended CI Validation
- `flutter analyze`
- `flutter test`
- `flutter build appbundle --release` (Android)
- `flutter build ipa --release` (macOS only)

## Android Compatibility Coverage

Flutter CI installs the same debug APK on Google APIs x86_64 emulators, resets
test app data, and cold-starts without optional permissions. It repeats startup
after granting and revoking usage access and, on API 33+, notifications. Each job
also installs the optimized release APK over the debug APK using the same CI
debug signing key. This signing fallback is for checks only, not publication.
Each phase checks screen launch, process survival for 30 seconds, and app-scoped
crash/plugin errors plus system ANR logs. Diagnostics are retained on failure.

| Android version | API | Coverage |
| --- | --- | --- |
| 7.0 | 24 | Minimum-version startup regression |
| 8.0 | 26 | Permission and release-upgrade regression |
| 9 | 28 | Permission and release-upgrade regression |
| 10 | 29 | Startup regression |
| 11 | 30 | Startup regression |
| 12 | 31 | Startup regression |
| 12L | 32 | Permission and release-upgrade regression |
| 13 | 33 | Startup regression |
| 14 | 34 | Startup regression |
| 15 | 35 | Startup regression |
| 16 | 36 | Startup regression |

This is a compatibility test range, not a market-share ranking or a claim of
full feature certification. SDK limits still follow the installed Flutter SDK;
check the merged release manifest before publishing. The matrix includes every
major Android release from 7 through 16 and Android 12L.

Before release, test the signed release APK on physical ARM devices, including
Samsung and at least one manufacturer with aggressive battery management:

- Deny, grant, and revoke notification, usage-access, accessibility, overlay,
   location, microphone, and exact-alarm permissions; verify safe fallbacks.
- On Android 12+, verify exact-alarm access and background service start limits.
- On Android 13+, verify notification denial does not crash startup or monitoring.
- On Android 14-16, verify foreground services, scheduled voice playback, and
   monitoring after reboot and app update under background-start restrictions.
- Verify app blocking, PIN unlock, prayer locks, VPN filtering, and monitoring
   with the screen off and battery saver enabled.
- Verify edge-to-edge layouts, system back navigation, large text, and tablet
   layouts; include Android 12L when tablets are supported.
- Confirm ARM64 and ARMv7 release artifacts install, and check 16 KB page-size
   compatibility on an Android 15+ ARM64 device/emulator.

Passing startup jobs does not certify these permission-dependent workflows,
release shrinking, native library page-size support, or manufacturer behavior.

### Local Verification (2026-10-31)

- The built debug APK reports minimum API 24, target API 36, and ARM64, ARMv7,
   and x86_64 native libraries.
- Dependency resolution, Dart analysis, all 176 tests, and the debug APK build
   passed. The shared startup script passed on an Android 16/API 36 emulator.
- The other matrix versions await CI execution; no physical-device certification
   was performed.
- App-module Android lint remains blocked by two missing
   `KILL_BACKGROUND_PROCESSES` permission reports, a deprecated Quick Settings
   activity-launch report, and the broad `QUERY_ALL_PACKAGES` permission report.
   Assess the version guard on the Quick Settings path and the package-visibility
   policy justification rather than treating every report as a proven crash.
- Whole-project lint additionally fails on existing `audio_session` dependency
   errors. The build also warns about future Flutter built-in Kotlin migration.

### Smaller Full-Feature Downloads

Both publishing paths now stage these signed release-mode artifacts. All keep
the same features, app ID, version and signing certificate, with Android 7.0+
as the current minimum. Per-Android-version copies would not reduce size; CPU
splits remove unused native libraries while runtime SDK guards handle versions.

| APK | Measured build size | Purpose |
| --- | --- | --- |
| ARMv7 | 23.0 MB | Confirmed 32-bit ARM devices |
| ARM64 | 25.3 MB | Confirmed 64-bit ARM devices |
| Universal | 64.7 MB | ARMv7, ARM64 and x86_64; unknown CPU fallback |

The website evaluates Android browser information locally. It requests CPU
architecture, bitness and Android version where available, with a 1.5-second
deadline. Reduced Chromium user agents are not treated as reliable version
evidence. Missing or ambiguous CPU hints select universal, not a guessed ARMv7.
Known Android versions below the minimum do not automatically download.

Android visitors receive one automatic download attempt per release per tab
session. iPhone, iPad and desktop visitors do not automatically receive APKs.
Blocked session storage disables the attempt. Browser download policies may
require a click; manual choices remain available. No browser device information
is uploaded by the selector.

Existing release metadata does not yet contain a published universal asset.
Until a new signed release publishes it, unknown devices see the release page
and manual APK choices rather than a fabricated universal download URL.

### Extended Verification (2026-10-31)

- Twelve automated website tests pass, covering Android 7-16, confirmed ARM
   variants, unknown/x86 hints, reduced user agents, unsupported systems,
   timeouts, missing assets, storage restrictions and session deduplication.
- TypeScript checks and the production website build pass.
- Browser checks with controlled metadata confirm ARM64/ARMv7/universal URL
   activation, no automatic activation on Android 6/iPhone/iPad/desktop, and no
   repeat activation after reload. Actual automatic file saving was not confirmed
   in the integrated browser; its download event did not fire. The tests therefore
   verify attempted downloads, not a bypass of browser download policies.
- Desktop 1440 px and mobile 390 px screenshots were inspected; no horizontal
   overflow or broken image assets were detected.
- All three real APKs built with API 24 minimum, API 36 target and matching
   signing certificates. ZIP alignment checks pass at 16 KB; all four ARM64
   native libraries have ELF LOAD alignment of at least 16 KB. This does not
   replace testing on an actual 16 KB-page device.
- The signed universal release APK passes six Android 16 phases: startup,
   usage-access grant/revocation, notification grant/revocation, and same-version
   reinstall. CI's debug-to-release update path and the other ten API levels
   await CI execution. These checks do not exercise blocking or PIN-data migration.
- No release was published and no website deployment was triggered locally.
