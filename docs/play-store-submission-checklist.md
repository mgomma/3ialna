# 3ialna Google Play Store submission checklist

This checklist is for the production Android App Bundle for package `com.ialna.app`. The Firebase and GitHub APK workflows are evaluation/internal-testing paths and must not be submitted to Google Play.

## Identity and account

- [ ] Confirm the Play Console developer account is verified and the correct organization or individual identity is displayed.
- [ ] Confirm the application ID is exactly `com.ialna.app`; do not change it after the first production upload.
- [ ] Confirm the app name, Arabic and English descriptions, support email, privacy-policy URL, category, and contact information.
- [ ] Confirm the target countries, age target, content rating questionnaire, and whether the app is intended for families or children under Google Play Families requirements.

## Production signing and versioning

- [ ] Create or verify the Play App Signing enrollment and upload key process.
- [ ] Store the production keystore, upload certificate, passwords, and aliases in a password manager or protected CI secrets; never commit them.
- [ ] Configure `android/key.properties` only in a secure build environment.
- [ ] Increment Flutter `version:` for every upload; ensure the generated `versionCode` is greater than the prior Play artifact.
- [ ] Build a signed Android App Bundle, not an APK:

```bash
flutter clean
flutter pub get
flutter analyze
flutter test --coverage
flutter build appbundle --release
```

- [ ] Verify the generated `.aab` is signed with the intended upload key and that no debug-signing override was used.
- [ ] Preserve R8/resource shrinking only after validating startup, accessibility, VPN/app-blocking, notifications, voice playback, permission onboarding, Quick Settings, and child switching on release builds.

## Privacy and data safety

- [ ] Confirm the Data safety answers match the implementation: child names, birth dates, gender, PINs, recordings, app rules, domains, requests, tokens, and usage history are local-only unless the product scope explicitly changes.
- [ ] Confirm crash diagnostics contain only sanitized error categories and stack locations; never upload recordings, child identity, usage, rules, or credentials.
- [ ] Confirm the privacy policy explains local storage, deletion, export/import sanitization, permissions, notifications, accessibility, VPN/DNS filtering, and parent-controlled data removal.
- [ ] Confirm export/import files strip child names, birth dates, gender, PINs, recordings, usage history, and device identifiers before sharing.
- [ ] Confirm the app provides a parent-controlled path to delete local history and recordings.
- [ ] Review every declared permission and remove unused permissions. Explain location, usage access, accessibility, notification, microphone, VPN, and exact-alarm behavior in the listing and onboarding.

## Functional release validation

- [ ] Fresh-install test on a supported Android phone and tablet.
- [ ] Upgrade test from the previous public version without package-conflict or data-loss errors.
- [ ] Permission onboarding returns to the app after each system settings grant and does not crash when permission is denied or revoked.
- [ ] Accessibility/app-blocking start, stop, and recovery behavior works; verify the app gives a clear fallback when accessibility cannot be enabled.
- [ ] Prayer lock starts and ends at the configured interval, including PIN entry from the system keyboard.
- [ ] Prayer and parent-voice reminders fire when the app is backgrounded and the device is locked, subject to Android notification and battery policies.
- [ ] Battery-optimization guidance and whitelist handling are clear and safe.
- [ ] Multiple-child switching works from the app and Quick Settings; each child receives independent limits and reports.
- [ ] Parent profile remains PIN-protected, has no child time limit, and does not bypass the parent security gate.
- [ ] Reward requests, Flex Tokens, approval/decline, voice celebration, and local persistence work after restart.
- [ ] Website download and installation guidance refer only to the intended public artifact.

## Play Console listing and testing tracks

- [ ] Upload the signed `.aab` to Internal testing first.
- [ ] Add trusted testers and complete the internal-testing release notes in Arabic and English.
- [ ] Test install, update, uninstall/reinstall, permissions, notifications, tablets, and low-memory behavior from the Play-delivered artifact.
- [ ] Promote to Closed testing only after internal tests pass and the release notes are reviewed.
- [ ] Provide accurate screenshots showing the Arabic RTL interface, parent dashboard, child selection, reward journey, and privacy boundaries. Do not show real family data.
- [ ] Complete the content rating, target-audience, ads, app-access, and Data safety forms truthfully.
- [ ] Add a support route and privacy-policy link that work without login.
- [ ] Submit for production only after the staged rollout decision is approved.

## Post-release monitoring

- [ ] Watch Android vitals, crash/ANR rate, permission failures, notification reliability, and user-reported installation issues.
- [ ] Keep diagnostic exports sanitized and local by default.
- [ ] Use a staged rollout and define a rollback or halt threshold before publishing.
- [ ] Record the Play version code, Git commit, CI run URL, artifact checksum, and release notes in the release log.

## Explicit blockers before production submission

The following items must be resolved or consciously accepted by the release owner before production:

- [ ] Production upload-key and Play App Signing configuration verified.
- [ ] Store listing and privacy policy reviewed in Arabic and English.
- [ ] Data safety and family-policy answers reviewed against the final binary.
- [ ] Release build tested on at least one current phone and one Android tablet.
- [ ] No failing analyzer, unit, widget, integration, or release smoke test.
- [ ] iOS signing/distribution remains separate and does not block the Android Play submission.
