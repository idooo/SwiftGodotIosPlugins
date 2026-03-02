# Push Notifications Plugin

iOS Push Notifications (APNs) plugin for Godot 4.2+ using SwiftGodot.

Registers devices with Apple Push Notification service and provides the device token needed for server-side push notification delivery.

## Setup

1. Build the plugin: `./build.sh PushNotifications release ios`
2. Copy the addon to your Godot project's `addons/iosplugins/` directory
3. Enable **Push Notifications** capability in your Xcode export project
4. Ensure your app has a valid APNs certificate/key configured in Apple Developer portal

## Usage

```gdscript
var _push: PushNotifications

func _ready() -> void:
    if _push == null && ClassDB.class_exists("PushNotifications"):
        _push = ClassDB.instantiate("PushNotifications")
        _push.device_token_received.connect(_on_device_token_received)
        _push.registration_error.connect(_on_registration_error)
        _push.authorization_result.connect(_on_authorization_result)

        # Register with alert, badge and sound permissions
        _push.registerPushNotifications(1 | 2 | 4)

func _on_device_token_received(token: String) -> void:
    # Send this token to your server for push notification delivery
    print("APNs device token: " + token)

func _on_registration_error(error_code: int, message: String) -> void:
    print("Registration failed: " + message)

func _on_authorization_result(result: String) -> void:
    print("Authorization result: " + result)  # "granted" or "denied"
```

## Push Option Flags (bitmask)

| Flag | Value | Description |
|------|-------|-------------|
| PUSH_ALERT | 1 | Display alert notifications |
| PUSH_BADGE | 2 | Update app badge number |
| PUSH_SOUND | 4 | Play notification sounds |
| PUSH_PROVISIONAL | 8 | Provisional authorization (quiet delivery, no user prompt) |

## Methods

| Method | Description |
|--------|-------------|
| `registerPushNotifications(options: int)` | Requests notification authorization and registers with APNs. Options is a bitmask of push option flags. |
| `setBadgeNumber(value: int)` | Sets the badge number on the app icon. Pass 0 to clear. |
| `getBadgeNumber() -> int` | Returns the current badge number of the app icon. |

## Signals

| Signal | Parameters | Description |
|--------|-----------|-------------|
| `device_token_received` | `token: String` | Emitted when device successfully registers with APNs. The token is a hex string to send to your server. |
| `device_token_updated` | `token: String` | Emitted when the device token changes (app restore, OS update, etc). |
| `registration_error` | `error_code: int, message: String` | Emitted when registration fails. |
| `authorization_result` | `result: String` | Emitted after authorization request. Value is `"granted"` or `"denied"`. |

## Error Codes

| Code | Name | Description |
|------|------|-------------|
| 1 | Unknown Error | An unknown error occurred |
| 2 | Not Available | Push notifications not available on this platform |
| 3 | Authorization Denied | User denied notification permission |
| 4 | Authorization Failed | Failed to request authorization |

## How It Works

1. Call `registerPushNotifications()` with desired option flags
2. iOS prompts the user for notification permission (unless using PUSH_PROVISIONAL)
3. If granted, `authorization_granted` signal fires and the plugin calls `UIApplication.shared.registerForRemoteNotifications()`
4. iOS contacts APNs and returns a device token
5. `device_token_received` signal fires with the hex-encoded token string
6. Send this token to your backend server to use with Apple's APNs HTTP/2 API

The plugin uses method swizzling to automatically intercept `UIApplicationDelegate` callbacks for token registration, so no manual Xcode project modifications are needed beyond enabling the Push Notifications capability.
