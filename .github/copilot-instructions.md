# Copilot Instructions for 3ialna

This repository is a Flutter mobile app with Android-native integrations for parental control and prayer-time locking.

## Core Stack
- Flutter (Dart, null safety)
- Android native (Kotlin) via method channels
- iOS folder exists, but most parental-control enforcement is Android-first

## Project Architecture (Current)
- `lib/data/local`: local persistence and settings services
- `lib/data/system`: platform/system integration (permissions, channels, usage, overlay, location, notifications)
- `lib/domain/models`: app/domain models
- `lib/presentation`: feature screens and widgets
- `lib/l10n`: localization delegates and translations

## What Copilot Should Optimize For
- Keep changes small, targeted, and easy to review.
- Preserve existing architecture boundaries (`presentation` -> `data/system` and `data/local` via services).
- Prefer extending existing services/screens over adding duplicate abstractions.
- Keep Android-specific logic in native Kotlin or `lib/data/system` bridges.
- Respect localization (`context.l10n`) for user-facing strings.
- Maintain permission-safe behavior and graceful fallback when permissions are missing.

## Coding Guidelines
- Follow `flutter_lints` and idiomatic Dart style.
- Avoid introducing new packages unless clearly required.
- Reuse existing models and service APIs when possible.
- Do not rewrite unrelated files or perform broad refactors unless requested.
- Add short comments only for non-obvious logic.

## Validation Workflow
Use these commands after non-trivial changes:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. `flutter run` (or targeted manual validation on Android device/emulator)

## High-Risk Areas
- App blocking and accessibility flows
- Usage tracking and foreground monitoring
- Overlay behavior and lock/unlock timing
- PIN authentication and parental settings security
- Method channel contract changes between Dart and Kotlin

When generating code, favor safety and backwards compatibility in these areas.
