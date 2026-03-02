//
//  PushNotifications.swift
//  SwiftGodotIosPlugins
//

import Foundation
import SwiftGodot
#if canImport(UIKit)
import UIKit
#endif
#if canImport(UserNotifications)
import UserNotifications
#endif

#initSwiftExtension(
    cdecl: "pushnotifications",
    types: [
        PushNotifications.self,
    ]
)

enum PushNotificationsError: Int, Error {
    case unknownError = 1
    case notAvailable = 2
    case authorizationDenied = 3
    case authorizationFailed = 4

    var localizedDescription: String {
        switch self {
        case .unknownError:
            return "An unknown error occurred."
        case .notAvailable:
            return "Push notifications are not available on this platform."
        case .authorizationDenied:
            return "Push notification authorization was denied by the user."
        case .authorizationFailed:
            return "Failed to request push notification authorization."
        }
    }
}

@Godot
class PushNotifications: Object {

    static var shared: PushNotifications?

    #if canImport(UIKit)
    private var hasSwizzled = false
    #endif

    /// Emitted when the device successfully registers for remote notifications.
    /// The token is a hex-encoded string representation of the APNs device token.
    @Signal var deviceTokenReceived: SignalWithArguments<String>

    /// Emitted when the device token changes (e.g. after app restore, OS update).
    @Signal var deviceTokenUpdated: SignalWithArguments<String>

    /// Emitted when registration for remote notifications fails.
    @Signal var registrationError: SignalWithArguments<Int, String>

    /// Emitted after authorization request completes with result: "granted" or "denied".
    @Signal var authorizationResult: SignalWithArguments<String>

    required override init() {
        super.init()
        PushNotifications.shared = self
    }

    required init(nativeHandle: UnsafeRawPointer) {
        super.init()
        PushNotifications.shared = self
    }

    deinit {
        PushNotifications.shared = nil
    }

    // MARK: - Public API

    /// Requests authorization for push notifications and registers the device with APNs.
    /// Options parameter is a bitmask:
    /// - 1 (PUSH_ALERT): Display alerts
    /// - 2 (PUSH_BADGE): Update badge number
    /// - 4 (PUSH_SOUND): Play sounds
    /// - 8 (PUSH_PROVISIONAL): Provisional authorization (quiet notifications, no prompt)
    @Callable
    func registerPushNotifications(_ options: Int) {
        #if canImport(UIKit) && canImport(UserNotifications)
        var authOptions: UNAuthorizationOptions = []

        if options & 1 != 0 { authOptions.insert(.alert) }
        if options & 2 != 0 { authOptions.insert(.badge) }
        if options & 4 != 0 { authOptions.insert(.sound) }
        if options & 8 != 0 { authOptions.insert(.provisional) }

        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { [weak self] granted, error in
            guard let self = self else { return }

            if let error = error {
                GD.printErr("PushNotifications: authorization error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.registrationError.emit(
                        PushNotificationsError.authorizationFailed.rawValue,
                        error.localizedDescription
                    )
                }
                return
            }

            if granted {
                DispatchQueue.main.async {
                    self.authorizationResult.emit("granted")
                    self.swizzleAppDelegateIfNeeded()
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                DispatchQueue.main.async {
                    self.authorizationResult.emit("denied")
                }
            }
        }
        #else
        GD.printErr("PushNotifications: not available on this platform")
        DispatchQueue.main.async {
            self.registrationError.emit(
                PushNotificationsError.notAvailable.rawValue,
                PushNotificationsError.notAvailable.localizedDescription
            )
        }
        #endif
    }

    /// Sets the badge number on the app icon on the Home screen.
    /// - Parameter value: The badge number to display. Use 0 to remove the badge.
    @Callable
    func setBadgeNumber(_ value: Int) {
        #if canImport(UIKit) && canImport(UserNotifications)
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(value) { error in
                if let error = error {
                    GD.printErr("PushNotifications: failed to set badge count: \(error.localizedDescription)")
                }
            }
        } else {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = value
            }
        }
        #endif
    }

    /// Returns the current badge number of the app icon on the Home screen.
    @Callable
    func getBadgeNumber() -> Int {
        #if canImport(UIKit)
        return UIApplication.shared.applicationIconBadgeNumber
        #else
        return 0
        #endif
    }

    // MARK: - Internal: device token handling

    func onDeviceTokenReceived(_ tokenHex: String) {
        DispatchQueue.main.async {
            self.deviceTokenReceived.emit(tokenHex)
            self.deviceTokenUpdated.emit(tokenHex)
        }
    }

    func onRegistrationFailed(_ error: Error) {
        DispatchQueue.main.async {
            self.registrationError.emit(
                PushNotificationsError.unknownError.rawValue,
                error.localizedDescription
            )
        }
    }

    // MARK: - AppDelegate swizzling

    // Swizzles Godot's AppDelegate to intercept the device token callbacks.
    // Called once, right before registerForRemoteNotifications().

    #if canImport(UIKit)
    private func swizzleAppDelegateIfNeeded() {
        guard !hasSwizzled else { return }
        hasSwizzled = true

        guard let delegate = UIApplication.shared.delegate else {
            GD.printErr("PushNotifications: no app delegate found")
            return
        }

        let delegateClass: AnyClass = type(of: delegate)
        swizzleDidRegister(delegateClass)
        swizzleDidFailToRegister(delegateClass)
    }

    private func swizzleDidRegister(_ cls: AnyClass) {
        let selector = #selector(UIApplicationDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:))

        let newBlock: @convention(block) (AnyObject, UIApplication, Data) -> Void = { _, _, deviceToken in
            let tokenHex = deviceToken.map { String(format: "%02x", $0) }.joined()
            PushNotifications.shared?.onDeviceTokenReceived(tokenHex)
        }

        if let originalMethod = class_getInstanceMethod(cls, selector) {
            let originalIMP = method_getImplementation(originalMethod)
            let replacementBlock: @convention(block) (AnyObject, UIApplication, Data) -> Void = { obj, app, deviceToken in
                // Call original implementation first
                typealias Fn = @convention(c) (AnyObject, Selector, UIApplication, Data) -> Void
                let original = unsafeBitCast(originalIMP, to: Fn.self)
                original(obj, selector, app, deviceToken)
                // Then forward to our plugin
                let tokenHex = deviceToken.map { String(format: "%02x", $0) }.joined()
                PushNotifications.shared?.onDeviceTokenReceived(tokenHex)
            }
            method_setImplementation(originalMethod, imp_implementationWithBlock(replacementBlock))
        } else {
            class_addMethod(cls, selector, imp_implementationWithBlock(newBlock), "v@:@@")
        }
    }

    private func swizzleDidFailToRegister(_ cls: AnyClass) {
        let selector = #selector(UIApplicationDelegate.application(_:didFailToRegisterForRemoteNotificationsWithError:))

        let newBlock: @convention(block) (AnyObject, UIApplication, NSError) -> Void = { _, _, error in
            PushNotifications.shared?.onRegistrationFailed(error)
        }

        if let originalMethod = class_getInstanceMethod(cls, selector) {
            let originalIMP = method_getImplementation(originalMethod)
            let replacementBlock: @convention(block) (AnyObject, UIApplication, NSError) -> Void = { obj, app, error in
                typealias Fn = @convention(c) (AnyObject, Selector, UIApplication, NSError) -> Void
                let original = unsafeBitCast(originalIMP, to: Fn.self)
                original(obj, selector, app, error)
                PushNotifications.shared?.onRegistrationFailed(error)
            }
            method_setImplementation(originalMethod, imp_implementationWithBlock(replacementBlock))
        } else {
            class_addMethod(cls, selector, imp_implementationWithBlock(newBlock), "v@:@@")
        }
    }
    #endif
}
