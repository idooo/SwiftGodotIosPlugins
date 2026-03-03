# SwiftGodotIosPlugins

A highly customized fork of [SwiftGodotIosPlugins](https://github.com/zt-pawer/SwiftGodotIosPlugins) that uses a later version of SwiftGodot and only supports what's needed for my use case.

[![Godot](https://img.shields.io/badge/Godot%20Engine-4.3-blue.svg)](https://github.com/godotengine/godot/)
[![SwiftGodot](https://img.shields.io/badge/SwiftGodot-main-blue.svg)](https://github.com/migueldeicaza/SwiftGodot/)
![iOS](https://img.shields.io/badge/iOS-17+-green.svg?style=flat)
[![Swift](https://img.shields.io/badge/Swift-5.9.1-blue.svg)](https://www.swift.org/)
[![License](https://img.shields.io/badge/license-MIT-lightgrey.svg?maxAge=2592000)](https://github.com/zt-pawer/SwiftGodotGameCenter/blob/main/LICENSE)

## Benefits

There are few major benefits with this version of the plugins compared to the classical [godot-ios-plugins](https://github.com/godot-sdk-integrations/godot-ios-plugins) plugins:
- Completely written in Swift
- Leverage new Apple SDKs (no deprecated APIs)
- Conform to Godot signals
- No need to recompile if the Godot version changes

# Supported Plugins

Currently, SwiftGodotIosPlugins implements the iOS **InAppPurchase** and **PushNotifications** integration.

# How to use it

Register the signals as indicated for each plugin and implement the methods that you need to handle. A demo application is provided for each of the plugin.
[YouTube tutorial](https://www.youtube.com/watch?v=RcisM4x9cTo)

# Technical details
- [InAppPurchase](InAppPurchase/README.md)
- [PushNotifications](PushNotifications/README.md)
