import FamilyControls
import Flutter
import NetworkExtension
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
    case "requestNetworkPermission":
      configureDNSProxy(result: result)
    case "startWebProtection":
      setDNSProxyEnabled(true, result: result)
    case "stopWebProtection":
      setDNSProxyEnabled(false, result: result)
    case "isWebProtectionRunning":
      readDNSProxyStatus(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func configureDNSProxy(result: @escaping FlutterResult) {
    let manager = NEDNSProxyManager.shared()
    manager.loadFromPreferences { error in
      guard error == nil else {
        result(FlutterError(code: "DNS_PROXY_LOAD_FAILED", message: "تعذر تحميل إعداد حماية DNS.", details: error?.localizedDescription))
        return
      }
      let provider = NEDNSProxyProviderProtocol()
      provider.providerBundleIdentifier = "com.ialna.app.SafeContentDNSProxy"
      manager.providerProtocol = provider
      manager.localizedDescription = "3ialna Safe Content"
      manager.saveToPreferences { saveError in
        if let saveError {
          result(FlutterError(code: "DNS_PROXY_PERMISSION_FAILED", message: "تعذر طلب إذن حماية DNS.", details: saveError.localizedDescription))
        } else {
          result(true)
        }
      }
    }
  }

  private func setDNSProxyEnabled(_ enabled: Bool, result: @escaping FlutterResult) {
    let manager = NEDNSProxyManager.shared()
    manager.loadFromPreferences { error in
      guard error == nil else {
        result(FlutterError(code: "DNS_PROXY_LOAD_FAILED", message: "تعذر تحميل حالة حماية DNS.", details: error?.localizedDescription))
        return
      }
      guard manager.providerProtocol != nil else {
        result(FlutterError(code: "DNS_PROXY_NOT_CONFIGURED", message: "لم يتم إعداد حماية DNS بعد.", details: "Call requestNetworkPermission first."))
        return
      }
      manager.isEnabled = enabled
      manager.saveToPreferences { saveError in
        if let saveError {
          result(FlutterError(code: "DNS_PROXY_UPDATE_FAILED", message: "تعذر تحديث حالة حماية DNS.", details: saveError.localizedDescription))
        } else {
          result(enabled)
        }
      }
    }
  }

  private func readDNSProxyStatus(result: @escaping FlutterResult) {
    let manager = NEDNSProxyManager.shared()
    manager.loadFromPreferences { error in
      guard error == nil else {
        result(FlutterError(code: "DNS_PROXY_LOAD_FAILED", message: "تعذر قراءة حالة حماية DNS.", details: error?.localizedDescription))
        return
      }
      result(manager.isEnabled && manager.providerProtocol != nil)
    }
  }
}
