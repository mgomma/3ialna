# iOS Tasks

Last updated: 2026-05-17 (in-progress fixes applied)

## P0 Release Blockers

### I1) Finalize iOS bundle identifier and signing
- Type: Fix
- Status: OPEN
- Priority: P0
- Files:
  - ios/Runner.xcodeproj/project.pbxproj
  - Xcode signing settings
- Task:
  - Replace placeholder bundle id.
  - Verify team, certificates, and provisioning for Release/Profile.
- Acceptance:
  - IPA archive succeeds and uploads to TestFlight.

## P1 High-Risk Bugs

### I2) Remove forced cast startup crash risk
- Type: Bug
- Status: DONE
- Priority: P1
- File:
  - ios/Runner/AppDelegate.swift
- Task:
  - Replace forced FlutterViewController cast with safe guard and fallback.
- Acceptance:
  - No startup crash from root view controller assumptions.
  - Implemented: replaced forced cast with safe guard in `ios/Runner/AppDelegate.swift`.

### I3) Clarify iOS feature parity for Android-only controls
- Type: Fix
- Status: DONE
- Priority: P1
- Files:
  - ios/Runner/AppDelegate.swift
  - iOS-facing UI text and store metadata
- Task:
  - Ensure iOS behavior is clearly communicated in app and store listing.
- Acceptance:
  - No misleading statements about iOS app-blocking capability.
  - Implemented: added explicit unsupported responses in `ios/Runner/AppDelegate.swift` and iOS limitation messaging/disabled Android-only controls in `lib/presentation/parental_control/parent_dashboard_screen.dart`.

## P2 Important Enhancements

### I4) Add iOS TestFlight checklist template per build
- Type: Enhancement
- Status: DONE
- Priority: P2
- Task:
  - Add repeatable template for TestFlight build validation and tester notes.
- Acceptance:
  - Each TestFlight build has documented test scope and known limitations.
  - Implemented: added template file `.github/tasks/IOS_TESTFLIGHT_TEMPLATE.md`.

### I5) Add iOS crash monitoring hooks
- Type: Enhancement
- Status: DONE
- Priority: P2
- Task:
  - Add lightweight non-PII crash/error reporting hooks for beta cycles.
- Acceptance:
  - Startup and navigation failures are measurable during beta.
  - Implemented: added lightweight global error hooks and local error buffering in `lib/data/system/error_report_service.dart`, initialized in `lib/main.dart`.
