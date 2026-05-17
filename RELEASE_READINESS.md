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
3. Replace placeholder package id (`com.example.mu_super_app`) with your production package id if not finalized yet.
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
