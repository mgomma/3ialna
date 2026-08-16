# Development Workflows for Copilot Users

## Daily Workflow
1. Pull latest changes.
2. Run `flutter pub get`.
3. Implement focused change.
4. Run `flutter analyze`.
5. Run `flutter test`.
6. Validate manually on Android for platform-sensitive behavior.

## High-Value Manual Checks
- Parent PIN creation/change/verification path
- App-blocking trigger and release behavior
- Overlay visibility and action buttons
- Schedule activation across active/inactive windows
- Prayer-lock timing and notifications
- Behavior when permissions are denied or revoked

## Android-Specific Checks
- Accessibility service enabled/disabled transitions
- Usage access permission state changes
- Foreground monitoring service lifecycle
- Method-channel calls from Dart to Kotlin and returned payload validity

## Change Discipline
- Keep PRs scoped by feature.
- Update docs when behavior changes.
- Avoid mixing refactors with feature work.
- Preserve public method names and data keys unless coordinated cross-layer updates are included.
