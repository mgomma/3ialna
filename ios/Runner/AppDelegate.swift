import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let blockingChannel = FlutterMethodChannel(name: "app_blocking/block",
                                              binaryMessenger: controller.binaryMessenger)
    
    blockingChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      
      if call.method == "blockApp" {
          // iOS Screen Time API implementation would go here
          // Note: Requires FamilyControls entitlement and physical device
          result(true)
      } else if call.method == "closeAppAndGoHome" {
          // iOS doesn't allow apps to close themselves or go home programmatically
          // The Screen Time API handles this via ManagedSettings
          result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
