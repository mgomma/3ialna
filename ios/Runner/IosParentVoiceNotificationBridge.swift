import AVFoundation
import Flutter
import UserNotifications

/// Schedules a parent-recorded audio file as a local notification sound.
///
/// iOS owns delivery while the app is suspended. This is intentionally a
/// notification-sound path, not a promise of arbitrary background code or
/// uninterrupted audio playback. The written notification remains Flutter's
/// responsibility and is scheduled independently.
final class IosParentVoiceNotificationBridge {
  static let channelName = "parent_voice_notifications"
  private let notificationCenter = UNUserNotificationCenter.current()
  private let requestIdentifier = "3ialna.parent.voice"
  private let soundName = "parent_voice_notification.wav"

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "scheduleVoicePlayback":
      guard
        let arguments = call.arguments as? [String: Any],
        let sourcePath = arguments["path"] as? String,
        let atMillis = (arguments["atMillis"] as? NSNumber)?.doubleValue
      else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Voice path and playback time are required.", details: nil))
        return
      }

      schedule(sourcePath: sourcePath, at: Date(timeIntervalSince1970: atMillis / 1000), result: result)

    case "cancelVoicePlayback":
      notificationCenter.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
      result(true)

    case "isVoicePlaybackScheduled":
      notificationCenter.getPendingNotificationRequests { requests in
        result(requests.contains { $0.identifier == self.requestIdentifier })
      }

    case "requestVoiceNotificationPermission":
      notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
        if let error {
          result(FlutterError(code: "PERMISSION_ERROR", message: error.localizedDescription, details: nil))
        } else {
          result(granted)
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func schedule(sourcePath: String, at date: Date, result: @escaping FlutterResult) {
    guard date.timeIntervalSinceNow > 0 else {
      result(false)
      return
    }

    do {
      let soundURL = try copyToNotificationSounds(sourcePath: sourcePath)
      let content = UNMutableNotificationContent()
      content.title = "3ialna"
      content.body = ""
      content.sound = UNNotificationSound(named: UNNotificationSoundName(soundURL.lastPathComponent))
      content.threadIdentifier = "3ialna.parent.voice"

      let trigger = UNTimeIntervalNotificationTrigger(
        timeInterval: max(1, date.timeIntervalSinceNow),
        repeats: false
      )
      let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
      notificationCenter.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
      notificationCenter.add(request) { error in
        if let error {
          result(FlutterError(code: "SCHEDULE_ERROR", message: error.localizedDescription, details: nil))
        } else {
          result(true)
        }
      }
    } catch {
      result(FlutterError(code: "AUDIO_COPY_ERROR", message: error.localizedDescription, details: nil))
    }
  }

  private func copyToNotificationSounds(sourcePath: String) throws -> URL {
    let fileManager = FileManager.default
    let sourceURL = URL(fileURLWithPath: sourcePath)
    guard fileManager.fileExists(atPath: sourceURL.path) else {
      throw NSError(domain: "3ialna.voice", code: 1, userInfo: [NSLocalizedDescriptionKey: "The parent recording does not exist."])
    }

    let libraryURL = try fileManager.url(
      for: .libraryDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let soundsURL = libraryURL.appendingPathComponent("Sounds", isDirectory: true)
    try fileManager.createDirectory(at: soundsURL, withIntermediateDirectories: true)
    let destinationURL = soundsURL.appendingPathComponent(soundName)
    if fileManager.fileExists(atPath: destinationURL.path) {
      try fileManager.removeItem(at: destinationURL)
    }
    try fileManager.copyItem(at: sourceURL, to: destinationURL)
    return destinationURL
  }
}
