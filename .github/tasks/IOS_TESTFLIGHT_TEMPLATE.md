# iOS TestFlight Build Template

Use this template for every TestFlight build.

## Build Info
- Version:
- Build number:
- Date:
- Commit:
- Tester group:

## Pre-Upload Checks
- [ ] Bundle identifier is production-ready.
- [ ] Signing team and provisioning profiles are valid for Release/Profile.
- [ ] Archive builds successfully in Xcode.
- [ ] Export and upload to App Store Connect succeeds.

## Functional Scope (Must Pass)
- [ ] App launch and onboarding.
- [ ] Parent PIN setup/authentication.
- [ ] Prayer settings and scheduling screens.
- [ ] Country profile selection and persistence.
- [ ] Navigation between home, dashboard, and settings.

## iOS Platform Notes (Known Limits)
- [ ] Verify Android-only controls are clearly indicated as unavailable on iOS.
- [ ] Verify no UI text claims direct app-kill, kiosk mode, or accessibility blocking on iOS.

## Regression Checks
- [ ] No startup crash.
- [ ] No crash when opening parental dashboard.
- [ ] No crash after app background/foreground cycles.
- [ ] Arabic and English layouts render correctly.

## Release Notes for Testers
- What changed:
- Known limitations:
- Areas to focus:

## Result
- [ ] PASS
- [ ] PASS WITH ISSUES
- [ ] FAIL

## Issues Found
1.
2.
3.
