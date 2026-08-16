# Pull-request CI/CD checks

Every pull request targeting `dev` or `main` should pass a common Flutter quality gate before platform builds are considered valid.

## Pipeline sequence

| Stage | Runner | Required checks |
|---|---|---|
| Checkout and dependency setup | Ubuntu | Checkout the PR merge commit, install stable Flutter, run `flutter pub get`, then run `flutter pub get --enforce-lockfile`. |
| Formatting | Ubuntu | Run `dart format --output=none --set-exit-if-changed .` once the repository formatter baseline is stable. |
| Static analysis | Ubuntu | Run `flutter analyze` and fail on analyzer findings. |
| Unit and widget tests | Ubuntu | Run `flutter test --coverage`; the job must not skip once `test/` contains widget tests. Upload `coverage/lcov.info`. |
| Android validation | Ubuntu | Install Java 17 and run `flutter build apk --debug`; upload the APK only as a diagnostic artifact. |
| iOS validation | macOS | Run `pod install --repo-update` in `ios/`, then `flutter build ios --debug --no-codesign`. |
| Required status | GitHub | Require analysis, tests, Android, and iOS jobs as branch-protection checks. |

Use `pull_request` triggers for `dev` and `main`, plus `push` triggers for those branches. Use concurrency cancellation keyed by workflow and PR/ref so superseded runs do not consume unnecessary runners.

## Security and release boundaries

Use `permissions: contents: read`. Keep signing keys out of pull-request jobs. The Android debug APK and unsigned iOS build validate compilation only; release signing should run only from protected tags or an approved environment.

An unsigned iOS build does not validate Family Controls authorization, Network Extension entitlements, provisioning, device behavior, or App Store review readiness. Those checks require a Mac, Xcode, an Apple Developer configuration, and real-device or simulator validation.

## Failure triage

Fix analyzer failures before interpreting platform failures. Treat widget-test failures as product regressions, especially for Arabic direction, semantics, empty states, permission actions, URL normalization, search, and rule removal. Treat Android failures as Gradle/manifest/native-service issues and iOS failures as Podfile, Swift availability, target membership, entitlement, signing, or deployment-target issues.
