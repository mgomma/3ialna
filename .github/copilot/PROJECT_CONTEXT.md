# 3ialna Project Context for AI

## Product Summary
3ialna is a parental control app with Islamic-focused features. Key capabilities include app usage limits, app blocking, overlay warnings, PIN-protected parent controls, scheduling, and prayer-time locking.

## Important Implementation Notes
- Android is the primary platform for advanced control features (usage stats, accessibility-based blocking, kiosk-like controls).
- Flutter UI and service orchestration live under `lib/`.
- Native integration exists through method channels and Android services/components.

## Primary Code Areas
- `lib/main.dart`: app and overlay entry points.
- `lib/presentation/parental_control`: parent-facing management screens.
- `lib/presentation/overlay`: warning/lock overlays.
- `lib/data/local`: persisted settings and control state.
- `lib/data/system`: OS/service integrations.
- `android/app/src/main`: Kotlin helpers, services, receivers, and channel handlers.

## Typical Change Patterns
- New setting: update model + storage service + screen.
- New platform capability: add/update Dart system service + method channel + Kotlin implementation.
- New restriction rule: implement logic in storage/system service, then surface status in UI.

## Safety Priorities
- Do not break parent authentication flow.
- Do not break app-blocking enforcement or release logic.
- Handle permission denial gracefully.
- Keep behavior predictable around schedules and prayer-time locks.
