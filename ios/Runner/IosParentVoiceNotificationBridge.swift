import AVFoundation
import Flutter
import UserNotifications

/// Schedules a parent-recorded audio file as a local notification sound.
///
/// iOS owns delivery while the app is suspended. iOS notification sounds are
/// intentionally used instead of arbitrary background audio playback so the
/// reminder continues to work when Flutter is no longer running.
final class IosParentVoiceNotificationBridge {
  static let channelName = "parent_voice_notifications"
  private let notificationCenter = UNUserNotificationCenter.current()
  private let requestIdentifier = "3ialna.parent.voice"
  private let prayerRequestPrefix = "3ialna.prayer.voice."
  private let prayerAzanRequestPrefix = "3ialna.prayer.azan."
  private let prayerSoundName = "prayer_reminder_voice.wav"
  private let prayerAzanSoundName = "prayer_azan_voice.wav"
  private let maximumNotificationSoundDuration: TimeInterval = 29

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
      schedule(
        sourcePath: sourcePath,
        at: Date(timeIntervalSince1970: atMillis / 1000),
        identifier: requestIdentifier,
        result: result
      )

    case "schedulePrayerVoicePlayback":
      guard
        let arguments = call.arguments as? [String: Any],
        let sourcePath = arguments["path"] as? String,
        let values = arguments["atMillisList"] as? [NSNumber]
      else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Voice path and prayer reminder times are required.", details: nil))
        return
      }
      let dates = values
        .map { Date(timeIntervalSince1970: $0.doubleValue / 1000) }
        .filter { $0.timeIntervalSinceNow > 0 }
        .sorted()
      schedulePrayerReminders(
        sourcePath: sourcePath,
        at: dates,
        requestPrefix: prayerRequestPrefix,
        soundName: prayerSoundName,
        result: result
      )

    case "schedulePrayerAzanPlayback":
      guard
        let arguments = call.arguments as? [String: Any],
        let sourcePath = arguments["path"] as? String,
        let values = arguments["atMillisList"] as? [NSNumber]
      else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Azan path and prayer start times are required.", details: nil))
        return
      }
      let dates = values
        .map { Date(timeIntervalSince1970: $0.doubleValue / 1000) }
        .filter { $0.timeIntervalSinceNow > 0 }
        .sorted()
      schedulePrayerReminders(
        sourcePath: sourcePath,
        at: dates,
        requestPrefix: prayerAzanRequestPrefix,
        soundName: prayerAzanSoundName,
        result: result
      )

    case "cancelVoicePlayback":
      notificationCenter.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
      result(true)

    case "cancelPrayerVoicePlayback":
      notificationCenter.removePendingNotificationRequests(withIdentifiers: prayerRequestIdentifiers())
      result(true)

    case "cancelPrayerAzanPlayback":
      notificationCenter.removePendingNotificationRequests(withIdentifiers: prayerAzanRequestIdentifiers())
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

  private func schedule(
    sourcePath: String,
    at date: Date,
    identifier: String,
    result: @escaping FlutterResult
  ) {
    guard date.timeIntervalSinceNow > 0 else {
      result(false)
      return
    }

    do {
      let soundURL = try copyToNotificationSounds(sourcePath: sourcePath)
      let content = notificationContent(soundURL: soundURL)
      let trigger = UNTimeIntervalNotificationTrigger(
        timeInterval: max(1, date.timeIntervalSinceNow),
        repeats: false
      )
      let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
      notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
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

  private func schedulePrayerReminders(
    sourcePath: String,
    at dates: [Date],
    requestPrefix: String,
    soundName: String,
    result: @escaping FlutterResult
  ) {
    guard !dates.isEmpty else {
      result(false)
      return
    }

    do {
      let soundURL = try copyToNotificationSounds(sourcePath: sourcePath, soundName: soundName)
      notificationCenter.removePendingNotificationRequests(withIdentifiers: prayerRequestIdentifiers(prefix: requestPrefix))
      let group = DispatchGroup()
      var schedulingError: Error?
      for (index, date) in dates.prefix(35).enumerated() {
        let content = notificationContent(soundURL: soundURL)
        let components = Calendar.current.dateComponents(
          [.year, .month, .day, .hour, .minute, .second],
          from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
          identifier: "\(requestPrefix)\(index)",
          content: content,
          trigger: trigger
        )
        group.enter()
        notificationCenter.add(request) { error in
          if let error, schedulingError == nil {
            schedulingError = error
          }
          group.leave()
        }
      }
      group.notify(queue: .main) {
        if let schedulingError {
          result(FlutterError(code: "SCHEDULE_ERROR", message: schedulingError.localizedDescription, details: nil))
        } else {
          result(true)
        }
      }
    } catch {
      result(FlutterError(code: "AUDIO_COPY_ERROR", message: error.localizedDescription, details: nil))
    }
  }

  private func notificationContent(soundURL: URL) -> UNMutableNotificationContent {
    let content = UNMutableNotificationContent()
    content.title = "3ialna"
    content.body = ""
    content.sound = UNNotificationSound(named: UNNotificationSoundName(soundURL.lastPathComponent))
    content.threadIdentifier = "3ialna.parent.voice"
    return content
  }

  private func prayerRequestIdentifiers() -> [String] {
    prayerRequestIdentifiers(prefix: prayerRequestPrefix)
  }

  private func prayerAzanRequestIdentifiers() -> [String] {
    prayerRequestIdentifiers(prefix: prayerAzanRequestPrefix)
  }

  private func prayerRequestIdentifiers(prefix: String) -> [String] {
    (0..<35).map { "\(prefix)\($0)" }
  }

  private func copyToNotificationSounds(
    sourcePath: String,
    soundName: String = "parent_voice_notification.wav"
  ) throws -> URL {
    let fileManager = FileManager.default
    let sourceURL = URL(fileURLWithPath: sourcePath)
    guard fileManager.fileExists(atPath: sourceURL.path) else {
      throw NSError(domain: "3ialna.voice", code: 1, userInfo: [NSLocalizedDescriptionKey: "The parent recording does not exist."])
    }
    let duration = AVURLAsset(url: sourceURL).duration.seconds
    guard duration.isFinite, duration > 0, duration < maximumNotificationSoundDuration else {
      throw NSError(domain: "3ialna.voice", code: 2, userInfo: [NSLocalizedDescriptionKey: "The iOS prayer reminder recording must be shorter than 29 seconds."])
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
