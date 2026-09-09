import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let paymentReturnChannelName = "kz.jetkiz.app/payment-return"
  private var paymentReturnChannel: FlutterMethodChannel?
  private var pendingPaymentReturn: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let url = launchOptions?[.url] as? URL, isPaymentReturn(url) {
      pendingPaymentReturn = url.absoluteString
    }

    let launched = super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: paymentReturnChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      paymentReturnChannel = channel
      channel.setMethodCallHandler { [weak self] call, result in
        guard call.method == "getInitialPaymentReturn" else {
          result(FlutterMethodNotImplemented)
          return
        }
        result(self?.pendingPaymentReturn)
      }
    }

    return launched
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if isPaymentReturn(url) {
      pendingPaymentReturn = url.absoluteString
      paymentReturnChannel?.invokeMethod(
        "paymentReturn",
        arguments: url.absoluteString
      )
      return true
    }

    return super.application(app, open: url, options: options)
  }

  private func isPaymentReturn(_ url: URL) -> Bool {
    guard url.scheme?.lowercased() == "jetkiz" else { return false }
    guard url.host?.lowercased() == "payment" else { return false }
    return url.path == "/return"
  }
}
