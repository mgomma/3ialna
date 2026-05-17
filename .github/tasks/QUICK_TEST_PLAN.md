# Quick Test Plan

Use this checklist for a fast but meaningful release-candidate test pass.

## Preconditions
- Use release-like builds where possible.
- Use clean install devices.
- Test English and Arabic.
- Run both platform sections below.

## Android Quick Testing

### 1) Build and Startup
- [ ] Release AAB builds successfully.
- [ ] App installs and launches with no crash on first run.
- [ ] App relaunches normally after force close.
- [ ] App relaunches after reboot.

### 2) Permission and Setup
- [ ] Usage access prompt appears and can be granted.
- [ ] Accessibility service setup flow works.
- [ ] Overlay permission flow works.
- [ ] Notification permission flow works.
- [ ] Parent PIN creation and verification works.

### 3) Core Parental Controls
- [ ] App list loads with names/icons.
- [ ] Block action blocks selected app.
- [ ] Time limit reached shows warning overlay.
- [ ] Take a Break closes app and block expires after configured duration.
- [ ] Kiosk mode enable and disable works with proper authorization.

### 4) Schedule and Prayer Lock
- [ ] Schedule enforces restrictions inside active window.
- [ ] Restrictions are not incorrectly enforced outside active window.
- [ ] Prayer lock warns before lock and enforces during lock window.
- [ ] Friday behavior is correct when configured.

### 5) Android Regression
- [ ] No ANR/freezes during repeated app open/close.
- [ ] Background monitoring survives at least 15 minutes with screen on/off cycles.
- [ ] Notification behavior is sensible and not spammy.

## iOS Quick Testing

### 1) Build and Startup
- [ ] IPA builds successfully from macOS.
- [ ] App installs and launches with no crash on first run.
- [ ] App relaunches normally after force close.

### 2) Permission and Setup
- [ ] Location permission prompt appears when prayer feature needs location.
- [ ] Face ID path works when enabled on device.
- [ ] Parent PIN creation and verification works.

### 3) Core App Flows
- [ ] Home, parental settings, and schedule/prayer screens navigate without native crash.
- [ ] Parent flows are stable after app relaunch.
- [ ] Android-only controls are clearly presented as unavailable or limited.

### 4) Localization and UI
- [ ] Arabic RTL layout renders correctly on key screens.
- [ ] No obvious text overflow or clipping in Arabic or English.
- [ ] No missing translation keys in tested screens.

## Exit Criteria
- [ ] No open P0 defects.
- [ ] No new crash in core flows on either platform.
- [ ] Any unresolved P1 has mitigation and explicit go/no-go decision.
