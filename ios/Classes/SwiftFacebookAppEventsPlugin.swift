import Flutter
import Foundation
import UIKit
import FBSDKCoreKit
import FBSDKCoreKit_Basics
import FBAudienceNetwork

public class SwiftFacebookAppEventsPlugin: NSObject, FlutterPlugin {
    private static var isSDKInitialized = false

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter.oddbit.id/facebook_app_events_lite", binaryMessenger: registrar.messenger())
        let instance = SwiftFacebookAppEventsPlugin()

        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
    }
    
    /// Connect app delegate with SDK
    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        return ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    public func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        return ApplicationDelegate.shared.application(
            application,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
            case "initializeFacebookSDK":
                guard let arguments = call.arguments as? [String: Any],
                    let appID = arguments["appID"] as? String,
                    let displayName = arguments["displayName"] as? String,
                    let clientToken = arguments["clientToken"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for Facebook SDK initialization", details: nil))
                    return
                }

                initializeFacebookSDK(appID: appID, displayName: displayName, clientToken: clientToken)
                result(nil)
                break
            case "clearUserData":
                handleClearUserData(call, result: result)
                break
            case "setUserData":
                handleSetUserData(call, result: result)
                break
            case "clearUserID":
                handleClearUserID(call, result: result)
                break
            case "flush":
                handleFlush(call, result: result)
                break
            case "getApplicationId":
                handleGetApplicationId(call, result: result)
                break
            case "logEvent":
                handleLogEvent(call, result: result)
                break
            case "logPushNotificationOpen":
                handlePushNotificationOpen(call, result: result)
                break
            case "setUserID":
                handleSetUserId(call, result: result)
                break
            case "setAutoLogAppEventsEnabled":
                handleSetAutoLogAppEventsEnabled(call, result: result)
                break
            case "setDataProcessingOptions":
                handleSetDataProcessingOptions(call, result: result)
                break
            case "logPurchase":
                handlePurchased(call, result: result)
                break
            case "getAnonymousId":
                handleHandleGetAnonymousId(call, result: result)
                break
            case "setAdvertiserTracking":
                handleSetAdvertiserTracking(call, result: result)
                break
            default:
                result(FlutterMethodNotImplemented)
        }
    }

    /// Initialize Facebook SDK with dynamic values
    private func initializeFacebookSDK(appID: String, displayName: String, clientToken: String) {
        guard !SwiftFacebookAppEventsPlugin.isSDKInitialized else {
            print("Facebook SDK is already initialized")
            return
        }

        // Log to confirm initialization process
        print("Initializing Facebook SDK with:")
        print("AppID: \(appID)")
        print("DisplayName: \(displayName)")
        print("ClientToken: \(clientToken)")

        // Set Facebook SDK configuration
        Settings.shared.appID = appID
        Settings.shared.displayName = displayName
        Settings.shared.clientToken = clientToken

        // Enable Advertiser ID collection and auto-logging of app events
        Settings.shared.isAdvertiserIDCollectionEnabled = true
        Settings.shared.isAutoLogAppEventsEnabled = true
        Settings.shared.isAdvertiserTrackingEnabled = true

        // Initialize the SDK
        ApplicationDelegate.shared.initializeSDK()
        SwiftFacebookAppEventsPlugin.isSDKInitialized = true
    }

    private func handleClearUserData(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        AppEvents.shared.clearUserData()
        result(nil)
    }

    private func handleSetUserData(_ call: FlutterMethodCall, result: @escaping FlutterResult) {        
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()

        AppEvents.shared.setUserData(arguments["email"] as? String, forType: FBSDKAppEventUserDataType.email)
        AppEvents.shared.setUserData(arguments["firstName"] as? String, forType: FBSDKAppEventUserDataType.firstName)
        AppEvents.shared.setUserData(arguments["lastName"] as? String, forType: FBSDKAppEventUserDataType.lastName)
        AppEvents.shared.setUserData(arguments["phone"] as? String, forType: FBSDKAppEventUserDataType.phone)
        AppEvents.shared.setUserData(arguments["dateOfBirth"] as? String, forType: FBSDKAppEventUserDataType.dateOfBirth)
        AppEvents.shared.setUserData(arguments["gender"] as? String, forType: FBSDKAppEventUserDataType.gender)
        AppEvents.shared.setUserData(arguments["city"] as? String, forType: FBSDKAppEventUserDataType.city)
        AppEvents.shared.setUserData(arguments["state"] as? String, forType: FBSDKAppEventUserDataType.state)
        AppEvents.shared.setUserData(arguments["zip"] as? String, forType: FBSDKAppEventUserDataType.zip)
        AppEvents.shared.setUserData(arguments["country"] as? String, forType: FBSDKAppEventUserDataType.country)

        result(nil)
    }

    private func handleClearUserID(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        AppEvents.shared.userID = nil
        result(nil)
    }

    private func handleFlush(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        AppEvents.shared.flush()
        result(nil)
    }

    private func handleGetApplicationId(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(Settings.shared.appID)
    }

    private func handleHandleGetAnonymousId(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(AppEvents.shared.anonymousID)
    }

    private func handleLogEvent(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        let eventName = arguments["name"] as! String
        let parameters = arguments["parameters"] as? [AppEvents.ParameterName: Any] ?? [AppEvents.ParameterName: Any]()
        if arguments["_valueToSum"] != nil && !(arguments["_valueToSum"] is NSNull) {
            let valueToDouble = arguments["_valueToSum"] as! Double
            AppEvents.shared.logEvent(AppEvents.Name(eventName), valueToSum: valueToDouble, parameters: parameters)
        } else {
            AppEvents.shared.logEvent(AppEvents.Name(eventName), parameters: parameters)
        }

        result(nil)
    }

    private func handlePushNotificationOpen(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        let payload = arguments["payload"] as? [String: Any]
        if let action = arguments["action"] as? String {
            AppEvents.shared.logPushNotificationOpen(payload: payload!, action: action)
        } else {
            AppEvents.shared.logPushNotificationOpen(payload: payload!)
        }
        result(nil)
    }

    private func handleSetUserId(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let id = call.arguments as! String
        AppEvents.shared.userID = id
        result(nil)
    }

    private func handleSetAutoLogAppEventsEnabled(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let enabled = call.arguments as! Bool
        Settings.shared.isAutoLogAppEventsEnabled = enabled
        result(nil)
    }

    private func handleSetDataProcessingOptions(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        let modes = arguments["options"] as? [String] ?? []
        let state = arguments["state"] as? Int32 ?? 0
        let country = arguments["country"] as? Int32 ?? 0

        Settings.shared.setDataProcessingOptions(modes, country: country, state: state)

        result(nil)
    }

    private func handlePurchased(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        let amount = arguments["amount"] as! Double
        let currency = arguments["currency"] as! String
        let parameters = arguments["parameters"] as? [AppEvents.ParameterName: Any] ?? [AppEvents.ParameterName: Any]()
        AppEvents.shared.logPurchase(amount: amount, currency: currency, parameters: parameters)

        result(nil)
    }

    private func handleSetAdvertiserTracking(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [String: Any]()
        let enabled = arguments["enabled"] as! Bool
        let collectId = arguments["collectId"] as! Bool
        FBAdSettings.setAdvertiserTrackingEnabled(enabled)
        Settings.shared.isAdvertiserTrackingEnabled = enabled
        Settings.shared.isAdvertiserIDCollectionEnabled = collectId
        result(nil)
    }
}
