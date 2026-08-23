import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

final class ScreenTimeSafeguardMonitor: DeviceActivityMonitor {
  private let managedStore = ManagedSettingsStore(named: .init("3ialna.childSafeguards"))
  private let preferences = UserDefaults(suiteName: ScreenTimeSafeguardStore.appGroup)

  override func intervalDidStart(for activity: DeviceActivityName) {
    updateActiveActivity(activity.rawValue, active: true)
  }

  override func intervalDidEnd(for activity: DeviceActivityName) {
    updateActiveActivity(activity.rawValue, active: false)
  }

  private func updateActiveActivity(_ activity: String, active: Bool) {
    var current = Set(preferences?.stringArray(forKey: ScreenTimeSafeguardStore.activeActivitiesKey) ?? [])
    if active { current.insert(activity) } else { current.remove(activity) }
    preferences?.set(Array(current), forKey: ScreenTimeSafeguardStore.activeActivitiesKey)
    current.isEmpty ? clearShield() : applyShield()
  }

  private func applyShield() {
    guard let data = preferences?.data(forKey: ScreenTimeSafeguardStore.selectionKey),
          let selection = try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data) else { return }
    managedStore.shield.applications = selection.applicationTokens
    managedStore.shield.applicationCategories = .specific(selection.categoryTokens)
    managedStore.shield.webDomains = selection.webDomainTokens
  }

  private func clearShield() {
    managedStore.shield.applications = nil
    managedStore.shield.applicationCategories = nil
    managedStore.shield.webDomains = nil
  }
}
