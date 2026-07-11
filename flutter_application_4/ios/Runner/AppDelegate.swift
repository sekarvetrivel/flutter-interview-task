import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

  // Must match the Dart side exactly (battery_screen.dart).
  private let channelName = "com.example/battery"
  private let methodGetBatteryLevel = "getBatteryLevel"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let batteryChannel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: controller.binaryMessenger
    )

    batteryChannel.setMethodCallHandler { [weak self] (call, result) in
      guard call.method == self?.methodGetBatteryLevel else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.receiveBatteryLevel(result: result)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func receiveBatteryLevel(result: FlutterResult) {
    let device = UIDevice.current
    device.isBatteryMonitoringEnabled = true

    if device.batteryState == .unknown {
      // Mirrors the Android side's `result.error(...)` call — this becomes
      // a PlatformException with code "UNAVAILABLE" on the Dart side,
      // which battery_screen.dart already handles without crashing.
      result(
        FlutterError(
          code: "UNAVAILABLE",
          message: "Battery info not available (e.g. running on a simulator).",
          details: nil
        )
      )
    } else {
      // batteryLevel is a Float 0.0-1.0; convert to an Int 0-100 so the
      // Dart side (and Android) can treat this identically.
      let percentage = Int(device.batteryLevel * 100)
      result(percentage)
    }
  }
}
