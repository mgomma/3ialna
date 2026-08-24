import DeviceActivity
import Foundation
import ManagedSettings

enum ScreenTimeSafeguardStore {
  static let appGroup = "group.com.ialna.app"
  static let selectionKey = "screen_time_safeguard_selection"
  static let activeActivitiesKey = "screen_time_safeguard_active_activities"
  static let sleepActivity = DeviceActivityName("3ialna.sleep")
  static let prayerIds = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
  static let prayerActivities = prayerIds.map(prayerActivity)

  static func prayerActivity(_ id: String) -> DeviceActivityName {
    DeviceActivityName("3ialna.prayer.\(id)")
  }
}
