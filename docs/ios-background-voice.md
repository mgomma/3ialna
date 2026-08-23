# iOS background parent voice playback

3ialna uses a native `UNUserNotificationCenter` bridge for suspended-app voice delivery. The Flutter recorder stores an iOS WAV recording locally, capped at 30 seconds so it can be used as a custom local-notification sound. The Swift bridge copies the recording into the app’s `Library/Sounds` directory and schedules one pending voice notification using a time-interval trigger. The written prayer notification remains a separate request and remains visible even when the voice request fails.

This path is intentionally privacy-aware: the audio file stays in the app sandbox, no transcript is created, and no recording is uploaded. The bridge supports scheduling, cancelation, pending-status checks, and notification permission requests through `parent_voice_notifications`.

## Important iOS boundary

A local notification sound is the supported background delivery mechanism here. It does not grant arbitrary background execution, continuous playback, exact wall-clock guarantees under every Focus/Low Power/notification policy, or permission to bypass the user’s notification settings. A parent must grant microphone and notification permissions, and iOS may suppress or alter presentation according to system policy.

## Mac validation checklist

Run `flutter pub get`, open `ios/Runner.xcworkspace` in Xcode, confirm `IosParentVoiceNotificationBridge.swift` is a Runner source, and build on a physical iPhone. Test a recording shorter than 30 seconds, preview it, grant notifications, background the app, wait for the scheduled request, and confirm the custom sound plays while the written notification remains independent. Also test cancelation, replacement, deletion, reboot/resume behavior, Focus mode, silent mode, and denied notification permission. Validate that the file remains inside the app sandbox and is absent after deletion.
