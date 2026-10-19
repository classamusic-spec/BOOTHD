import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PorcelainDeviceStorage") {
      DeviceStorageChannel.register(with: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PorcelainKiosk") {
      KioskChannel.register(with: registrar.messenger())
    }
  }
}

/// Free space for the launch checks (ADR-0012), and keeping the booth's
/// files out of iCloud and computer backups (ADR-0016): Dart has no API
/// for either. Reports only a number of bytes.
enum DeviceStorageChannel {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "porcelain/device_storage", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      if call.method == "excludeFromBackup" {
        DeviceStorageChannel.excludeFromBackup(call, result)
        return
      }
      guard call.method == "freeBytes" else {
        result(FlutterMethodNotImplemented)
        return
      }
      do {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        let values = try home.resourceValues(forKeys: [
          .volumeAvailableCapacityForImportantUsageKey
        ])
        if let bytes = values.volumeAvailableCapacityForImportantUsage {
          result(NSNumber(value: bytes))
        } else {
          result(FlutterError(code: "unavailable", message: nil, details: nil))
        }
      } catch {
        result(FlutterError(code: "unavailable", message: nil, details: nil))
      }
    }
  }

  /// Marks the directory, and so everything in it, as excluded from
  /// backups.
  private static func excludeFromBackup(
    _ call: FlutterMethodCall, _ result: FlutterResult
  ) {
    guard let arguments = call.arguments as? [String: Any],
      let path = arguments["path"] as? String
    else {
      result(FlutterError(code: "bad_arguments", message: nil, details: nil))
      return
    }
    var url = URL(fileURLWithPath: path, isDirectory: true)
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    do {
      try url.setResourceValues(values)
      result(nil)
    } catch {
      result(FlutterError(code: "unavailable", message: nil, details: nil))
    }
  }
}

/// Whether the iPad is locked to this app (ADR-0016): Dart has no API for
/// it. Read only: the app never starts or ends Guided Access.
enum KioskChannel {
  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "porcelain/kiosk", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "lockState" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(UIAccessibility.isGuidedAccessEnabled ? "guidedAccess" : "none")
    }
  }
}
