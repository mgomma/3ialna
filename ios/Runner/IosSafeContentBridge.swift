import FamilyControls
import Flutter
import UIKit

final class IosSafeContentBridge {
  static let channelName = "safe_content/ios"

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.0, *) else {
      result(FlutterError(
        code: "IOS_VERSION_UNSUPPORTED",
        message: "Family Controls requires iOS 16 or later.",
        details: nil
      ))
      return
    }

    switch call.method {
    case "isAuthorizationGranted":
      result(AuthorizationCenter.shared.authorizationStatus == .approved)
    case "requestAuthorization":
      Task {
        do {
          try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
          result(AuthorizationCenter.shared.authorizationStatus == .approved)
        } catch {
          result(FlutterError(
            code: "FAMILY_CONTROLS_AUTHORIZATION_FAILED",
            message: "Family Controls authorization was not granted.",
            details: error.localizedDescription
          ))
        }
      }
    case "startWebProtection", "stopWebProtection":
      result(FlutterError(
        code: "IOS_WEB_FILTER_REQUIRES_EXTENSION",
        message: "iOS web filtering requires an approved Network Extension target and entitlement.",
        details: "Family Controls authorization is separate from DNS or page-content filtering."
      ))
    case "isWebProtectionRunning":
      result(false)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
