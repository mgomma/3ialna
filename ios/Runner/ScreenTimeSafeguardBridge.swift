import DeviceActivity
import FamilyControls
import Flutter
import ManagedSettings
import SwiftUI
import UIKit

@available(iOS 16.0, *)
final class ScreenTimeSafeguardBridge {
  static let channelName = "parental_control/ios_screen_time"

  private let store = ManagedSettingsStore(named: .init("3ialna.childSafeguards"))
  private let preferences = UserDefaults(suiteName: ScreenTimeSafeguardStore.appGroup)
  private let activityCenter = DeviceActivityCenter()

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard AuthorizationCenter.shared.authorizationStatus == .approved else {
      result(FlutterError(
        code: "FAMILY_CONTROLS_NOT_AUTHORIZED",
        message: "Guardian approval is required before scheduling iOS safeguards.",
        details: nil
      ))
      return
    }

    switch call.method {
    case "isSafeguardSelectionConfigured":
      result(loadSelection() != nil)
    case "selectSafeguardApps":
      presentActivityPicker(result: result)
    case "syncSleepShield":
      guard let arguments = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing sleep safeguard arguments.", details: nil))
        return
      }
      syncSleep(arguments, result: result)
    case "schedulePrayerShields":
      guard let arguments = call.arguments as? [[String: Any]] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing prayer safeguard windows.", details: nil))
        return
      }
      schedulePrayerWindows(arguments, result: result)
    case "clearPrayerShields":
      stopPrayerWindows()
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func presentActivityPicker(result: @escaping FlutterResult) {
    guard let presenter = topViewController() else {
      result(FlutterError(code: "PRESENTER_UNAVAILABLE", message: "Unable to open the Apple app picker.", details: nil))
      return
    }
    let picker = ScreenTimeSafeguardPicker { [weak self] selection in
      self?.saveSelection(selection)
      result(true)
    }
    presenter.present(UIHostingController(rootView: picker), animated: true)
  }

  private func syncSleep(_ values: [String: Any], result: @escaping FlutterResult) {
    let activity = ScreenTimeSafeguardStore.sleepActivity
    activityCenter.stopMonitoring([activity])
    guard values["enabled"] as? Bool == true, loadSelection() != nil else {
      clearIfNoActiveSafeguards()
      result(false)
      return
    }
    guard let start = values["startMinutes"] as? Int,
          let end = values["endMinutes"] as? Int,
          start != end else {
      result(FlutterError(code: "INVALID_SLEEP_WINDOW", message: "Sleep start and end must be different.", details: nil))
      return
    }
    do {
      let schedule = DeviceActivitySchedule(
        intervalStart: DateComponents(hour: start / 60, minute: start % 60),
        intervalEnd: DateComponents(hour: end / 60, minute: end % 60),
        repeats: true
      )
      try activityCenter.startMonitoring(activity, during: schedule)
      result(true)
    } catch {
      result(FlutterError(code: "SLEEP_SCHEDULE_FAILED", message: "Unable to schedule the sleep shield.", details: error.localizedDescription))
    }
  }

  private func schedulePrayerWindows(_ values: [[String: Any]], result: @escaping FlutterResult) {
    stopPrayerWindows()
    guard loadSelection() != nil else {
      result(false)
      return
    }
    let formatter = ISO8601DateFormatter()
    do {
      for value in values {
        guard let id = value["id"] as? String,
              let startText = value["start"] as? String,
              let endText = value["end"] as? String,
              let start = formatter.date(from: startText),
              let end = formatter.date(from: endText),
              end > start else { continue }
        let calendar = Calendar.current
        let schedule = DeviceActivitySchedule(
          intervalStart: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: start),
          intervalEnd: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: end),
          repeats: false
        )
        try activityCenter.startMonitoring(ScreenTimeSafeguardStore.prayerActivity(id), during: schedule)
      }
      result(true)
    } catch {
      result(FlutterError(code: "PRAYER_SCHEDULE_FAILED", message: "Unable to schedule prayer shields.", details: error.localizedDescription))
    }
  }

  private func stopPrayerWindows() {
    activityCenter.stopMonitoring(ScreenTimeSafeguardStore.prayerActivities)
  }

  private func loadSelection() -> FamilyActivitySelection? {
    guard let data = preferences?.data(forKey: ScreenTimeSafeguardStore.selectionKey) else { return nil }
    return try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
  }

  private func saveSelection(_ selection: FamilyActivitySelection) {
    let data = try? PropertyListEncoder().encode(selection)
    preferences?.set(data, forKey: ScreenTimeSafeguardStore.selectionKey)
  }

  private func clearIfNoActiveSafeguards() {
    guard preferences?.array(forKey: ScreenTimeSafeguardStore.activeActivitiesKey)?.isEmpty != false else { return }
    store.shield.applications = nil
    store.shield.applicationCategories = nil
    store.shield.webDomains = nil
  }

  private func topViewController(from root: UIViewController? = UIApplication.shared.connectedScenes
    .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
    .first?.rootViewController) -> UIViewController? {
    if let navigation = root as? UINavigationController { return topViewController(from: navigation.visibleViewController) }
    if let tab = root as? UITabBarController { return topViewController(from: tab.selectedViewController) }
    if let presented = root?.presentedViewController { return topViewController(from: presented) }
    return root
  }
}

@available(iOS 16.0, *)
private struct ScreenTimeSafeguardPicker: View {
  @Environment(\.dismiss) private var dismiss
  @State private var selection = FamilyActivitySelection()
  let onSave: (FamilyActivitySelection) -> Void

  var body: some View {
    NavigationStack {
      FamilyActivityPicker(selection: $selection)
        .navigationTitle("Apps to protect")
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
          }
          ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
              onSave(selection)
              dismiss()
            }
          }
        }
    }
  }
}
