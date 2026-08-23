import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      GeneratedPluginRegistrant.register(with: self)
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    let safeContentIosChannel = FlutterMethodChannel(
      name: IosSafeContentBridge.channelName,
      binaryMessenger: controller.binaryMessenger
    )
    let safeContentIosBridge = IosSafeContentBridge()
    safeContentIosChannel.setMethodCallHandler { call, result in
      safeContentIosBridge.handle(call, result: result)
    }

    if #available(iOS 16.0, *) {
      let screenTimeChannel = FlutterMethodChannel(
        name: ScreenTimeSafeguardBridge.channelName,
        binaryMessenger: controller.binaryMessenger
      )
      let screenTimeBridge = ScreenTimeSafeguardBridge()
      screenTimeChannel.setMethodCallHandler { call, result in
        screenTimeBridge.handle(call, result: result)
      }
    }

    let parentVoiceChannel = FlutterMethodChannel(
      name: IosParentVoiceNotificationBridge.channelName,
      binaryMessenger: controller.binaryMessenger
    )
    let parentVoiceBridge = IosParentVoiceNotificationBridge()
    parentVoiceChannel.setMethodCallHandler { call, result in
      parentVoiceBridge.handle(call, result: result)
    }

    let blockingChannel = FlutterMethodChannel(name: "app_blocking/block",
                                              binaryMessenger: controller.binaryMessenger)
    
    blockingChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      
      if call.method == "blockApp" {
          result(
            FlutterError(
              code: "UNSUPPORTED_ON_IOS",
              message: "Direct app blocking is Android-only in this build.",
              details: "Use iOS Screen Time / Family Controls integration for iOS-native restrictions."
            )
          )
      } else if call.method == "closeAppAndGoHome" {
          result(
            FlutterError(
              code: "UNSUPPORTED_ON_IOS",
              message: "Programmatic close/go-home is not available on iOS.",
              details: "This capability is intentionally unavailable by iOS platform rules."
            )
          )
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
