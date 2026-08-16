# Pre-Publish Backlog (Bugs, Fixes, Enhancements)

Last updated: 2026-05-17

## P0 Release Blockers

### 1) Replace placeholder package identifiers
- Type: Fix
- Status: OPEN
- Priority: P0
- Impact: Store upload rejection or wrong app identity.
- Evidence:
  - android/app/build.gradle.kts uses com.example.mu_super_app
  - ios/Runner.xcodeproj/project.pbxproj uses com.example.muSuperApp
- Task:
  - Set final Android applicationId/namespace and iOS bundle identifier.
  - Update Kotlin package path/imports accordingly.
  - Re-test method channels and services after rename.
- Acceptance:
  - Android and iOS build with final IDs.
  - Existing app functionality preserved.

### 2) Enforce real release signing for Android publishing
- Type: Fix
- Status: OPEN
- Priority: P0
- Impact: Unsignable or improperly signed release for Play upload.
- Evidence:
  - android/app/build.gradle.kts still allows debug signing fallback.
- Task:
  - For release branch/profile, fail build when key.properties is missing.
  - Keep debug fallback only for local developer profile if needed.
- Acceptance:
  - appbundle release build fails without release keystore.
  - appbundle release build succeeds with valid keystore.

## P1 High-Risk Bugs

### 3) Potential crash on iOS due to forced cast in AppDelegate
- Type: Bug
- Status: OPEN
- Priority: P1
- File: ios/Runner/AppDelegate.swift
- Risk:
  - Forced cast to FlutterViewController can crash if root view controller changes unexpectedly.
- Task:
  - Replace forced cast with safe guard and fallback handling.
- Acceptance:
  - No startup crash from view controller casting path.

### 4) NaN/invalid progress edge case when time limit is zero
- Type: Bug
- Status: OPEN
- Priority: P1
- File: lib/presentation/home/home_screen.dart
- Risk:
  - usedMinutes / timeLimitMinutes may produce NaN/Infinity when limit is 0.
- Task:
  - Guard division with minimum denominator and define UI behavior for zero limit.
- Acceptance:
  - Progress indicator always receives valid value in [0..1].

### 5) Fragile manual JSON parsing for blocked apps in Android native code
- Type: Bug
- Status: OPEN
- Priority: P1
- Files:
  - android/app/src/main/kotlin/com/example/mu_super_app/MainActivity.kt
  - android/app/src/main/kotlin/com/example/mu_super_app/blocking/AppBlockingAccessibilityService.kt
- Risk:
  - String-split parsing is brittle and can corrupt state.
- Task:
  - Replace manual parsing with robust JSON parser.
  - Add migration handling for existing stored values.
- Acceptance:
  - Parsing handles malformed input safely and logs cleanly.

## P2 Important Fixes

### 6) Schedule parsing logic in MonitorForegroundService is simplified
- Type: Fix
- Status: OPEN
- Priority: P2
- File: android/app/src/main/kotlin/com/example/mu_super_app/usage/MonitorForegroundService.kt
- Risk:
  - Comment indicates simplified behavior, may produce incorrect enforcement edge cases.
- Task:
  - Implement full JSON schedule parsing and unit-style validation.
- Acceptance:
  - Schedule behavior matches configured start/end/day rules.

### 7) Clarify iOS feature parity messaging
- Type: Fix
- Status: OPEN
- Priority: P2
- Files:
  - ios/Runner/AppDelegate.swift
  - user-facing docs/screens
- Risk:
  - iOS cannot enforce Android-level app blocking in the same way.
- Task:
  - Ensure UI and store listing describe iOS limitations clearly.
- Acceptance:
  - No misleading claims in app UI or store metadata.

## P3 Enhancements

### 8) Add smoke-test automation
- Type: Enhancement
- Status: OPEN
- Priority: P3
- Task:
  - Add a minimal CI workflow to run analyze and tests on pull requests.
- Acceptance:
  - CI reports pass/fail before release tagging.

### 9) Add release checklist gate in repository
- Type: Enhancement
- Status: OPEN
- Priority: P3
- Task:
  - Add a pull request template section requiring completion of quick test plan.
- Acceptance:
  - Release PRs include completed checklist links.

### 10) Add lightweight telemetry for critical flow failures
- Type: Enhancement
- Status: OPEN
- Priority: P3
- Task:
  - Add non-PII error logging hooks for permission/setup failures.
- Acceptance:
  - Actionable error events available during beta.
