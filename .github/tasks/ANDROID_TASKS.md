# Android Tasks

Last updated: 2026-05-17 (in-progress fixes applied)

## P0 Release Blockers

### A1) Finalize Android package identity
- Type: Fix
- Status: OPEN
- Priority: P0
- Files:
  - android/app/build.gradle.kts
  - android/app/src/main/kotlin/com/example/mu_super_app/*
- Task:
  - Replace placeholder applicationId and namespace.
  - Migrate Kotlin package path/imports to match final namespace.
- Acceptance:
  - Android release build works with final package id.

### A2) Enforce production signing for release artifacts
- Type: Fix
- Status: DONE
- Priority: P0
- File:
  - android/app/build.gradle.kts
- Task:
  - Require release keystore in release profile.
  - Keep optional debug fallback only for local non-publish builds.
- Acceptance:
  - Publishing build fails when signing credentials are missing.
  - Implemented: release/publish tasks now fail without `android/key.properties` unless explicitly overridden with `-PallowDebugReleaseSigning=true` for local checks.

## P1 High-Risk Bugs

### A3) Replace fragile blocked-app JSON parsing
- Type: Bug
- Status: DONE
- Priority: P1
- Files:
  - android/app/src/main/kotlin/com/example/mu_super_app/MainActivity.kt
  - android/app/src/main/kotlin/com/example/mu_super_app/blocking/AppBlockingAccessibilityService.kt
- Task:
  - Replace manual split-based parsing with proper JSON parsing.
  - Add malformed-data safeguards and logs.
- Acceptance:
  - No crashes or data corruption with malformed values.
  - Implemented: migrated both files to `JSONObject` parsing/serialization with type-safe conversion and malformed-data handling.

### A4) Improve schedule enforcement parsing
- Type: Fix
- Status: DONE
- Priority: P1
- File:
  - android/app/src/main/kotlin/com/example/mu_super_app/usage/MonitorForegroundService.kt
- Task:
  - Replace simplified schedule checks with complete parsing and validation.
- Acceptance:
  - Active windows and day rules are enforced exactly as configured.
  - Implemented: native service now parses full schedule JSON (`enabled`, `activeDays`, `differentWeekendRules`, `weekendStartTime`, `weekendEndTime`) with explicit time parsing and overnight handling.

### A5) Handle zero-limit progress safely in Flutter UI
- Type: Bug
- Status: DONE
- Priority: P1
- File:
  - lib/presentation/home/home_screen.dart
- Task:
  - Guard divide-by-zero and define UI for zero-minute limit.
- Acceptance:
  - Progress indicator always receives a valid value.
  - Implemented: progress now uses a guarded non-zero denominator.

## P2 Important Enhancements

### A6) Add Android smoke checks in CI
- Type: Enhancement
- Status: OPEN
- Priority: P2
- Task:
  - Add CI jobs for analyze/test and optional Android build smoke.
- Acceptance:
  - PR checks catch obvious regressions early.

### A7) Add Play policy evidence checklist
- Type: Enhancement
- Status: OPEN
- Priority: P2
- Task:
  - Add evidence templates for sensitive permission declarations.
- Acceptance:
  - Faster Play Console compliance submissions.
