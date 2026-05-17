---
applyTo: "lib/**/*.dart,android/app/src/main/**/*.kt,ios/**/*.swift"
---
# Flutter + Platform Instruction Set

Use these rules when editing application logic.

## Boundary Rules
- UI widgets/screens belong in `lib/presentation`.
- Persistence and local preferences belong in `lib/data/local`.
- Platform features (usage stats, overlay, accessibility, notifications, location, channels) belong in `lib/data/system` and native Android code.
- Data models belong in `lib/domain/models`.

## Platform Contract Rules
- If you change any method-channel method names, payload keys, or argument types in Dart, update Kotlin side in the same change.
- Keep payloads stable and defensive (null checks, defaults).
- Do not move Android-only enforcement logic into iOS paths.

## Product Behavior Rules
- Parent protection paths must remain PIN-protected.
- Blocking/limit logic must fail safe (no crash if permission/service unavailable).
- Keep prayer lock scheduling deterministic and time-zone aware.
- Exclude the app itself/system apps from destructive blocking behavior where already expected by current design.

## Localization Rules
- Avoid hardcoded user-facing strings in UI.
- Use localization helpers where the surrounding screen already uses localized strings.

## Testing Guidance
After feature edits, validate:
- `flutter analyze`
- `flutter test`
- Android manual path for permission flows and app-blocking behavior
